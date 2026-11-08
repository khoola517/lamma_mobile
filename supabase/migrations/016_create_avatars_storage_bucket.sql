-- =========================================================================
-- Migration 016: إنشاء حاوية تخزين الصور الرمزية (avatars bucket) وسياسات الأمان
-- Khadematy App - Storage Bucket Setup for User Avatars
-- =========================================================================

-- 1. إنشاء حاوية avatars في Supabase Storage إذا لم تكن موجودة وجعلها عامة (Public)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,
    5242880, -- الحد الأقصى 5 ميجابايت
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

-- 2. سياسة السماح بالوصول العام لقراءة الصور (Public Read)
DROP POLICY IF EXISTS "Avatar public read policy" ON storage.objects;
CREATE POLICY "Avatar public read policy"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- 3. سياسة السماح للمستخدم برفع وتحديث صورته
DROP POLICY IF EXISTS "Avatar upload policy" ON storage.objects;
CREATE POLICY "Avatar upload policy"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Avatar update policy" ON storage.objects;
CREATE POLICY "Avatar update policy"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Avatar delete policy" ON storage.objects;
CREATE POLICY "Avatar delete policy"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'avatars');

