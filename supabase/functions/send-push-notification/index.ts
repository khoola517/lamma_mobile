import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.15.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// دالة لإنشاء Google OAuth2 Access Token باستخدام مفتاح حساب الخدمة (Service Account)
async function getGoogleAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const strHeader = btoa(JSON.stringify(header));
  const strClaim = btoa(JSON.stringify(claim));
  const unsignedToken = `${strHeader}.${strClaim}`;

  // تحضير المفتاح الخاص RSA PKCS#8
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = serviceAccount.private_key
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s+/g, "");

  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedToken)
  );

  const strSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const jwt = `${unsignedToken}.${strSignature}`;

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenResponse.ok) {
    const errorText = await tokenResponse.text();
    throw new Error(`Failed to obtain Google access token: ${errorText}`);
  }

  const tokenData = await tokenResponse.json();
  return tokenData.access_token;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const payload = await req.json();
    const record = payload.record || payload;

    if (!record || !record.user_id || !record.title) {
      return new Response(
        JSON.stringify({ error: "Missing required notification fields (user_id, title)" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const firebaseServiceAccountEnv = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

    if (!firebaseServiceAccountEnv) {
      return new Response(
        JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT secret is not configured in Supabase" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const serviceAccount = JSON.parse(firebaseServiceAccountEnv);
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 1. استخراج التوكنات النشطة للمستخدم المستهدف
    const { data: tokens, error: tokensError } = await supabase
      .from("user_fcm_tokens")
      .select("fcm_token, platform")
      .eq("user_id", record.user_id)
      .eq("is_active", true);

    if (tokensError) {
      throw new Error(`Failed to query user_fcm_tokens: ${tokensError.message}`);
    }

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: "No active FCM tokens found for user",
          deliveredCount: 0,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. توليد رمز الدخول لـ Firebase Cloud Messaging
    const accessToken = await getGoogleAccessToken(serviceAccount);
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;

    let deliveredCount = 0;
    const deactivatedTokens: string[] = [];

    // 3. إرسال الإشعار لكل جهاز نشط
    for (const item of tokens) {
      const messageBody = {
        message: {
          token: item.fcm_token,
          notification: {
            title: record.title,
            body: record.body || "",
          },
          data: {
            id: String(record.id || ""),
            type: String(record.type || ""),
            booking_id: String(record.related_booking_id || ""),
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high",
            notification: {
              channel_id: "high_importance_channel",
              sound: "default",
            },
          },
          webpush: {
            headers: {
              Urgency: "high",
            },
            notification: {
              title: record.title,
              body: record.body || "",
              icon: "/icons/Icon-192.png",
              badge: "/favicon.png",
            },
          },
        },
      };

      const fcmResponse = await fetch(fcmEndpoint, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(messageBody),
      });

      if (fcmResponse.ok) {
        deliveredCount++;
      } else {
        const errorData = await fcmResponse.json().catch(() => ({}));
        const errorCode = errorData?.error?.details?.[0]?.errorCode || errorData?.error?.status;

        // تعطيل التوكن إذا كان غير صالح أو ملغى (UNREGISTERED / NOT_FOUND)
        if (
          fcmResponse.status === 404 ||
          errorCode === "UNREGISTERED" ||
          errorCode === "INVALID_ARGUMENT"
        ) {
          await supabase.rpc("deactivate_invalid_fcm_token", {
            p_fcm_token: item.fcm_token,
          });
          deactivatedTokens.push(item.fcm_token);
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        totalTokens: tokens.length,
        deliveredCount,
        deactivatedTokensCount: deactivatedTokens.length,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message || "Unknown error occurred" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
