-- ==============================================================================
-- Migration: 018_fix_duplicate_booking_notifications.sql
-- Description:
--   Fixes duplicate notifications when a provider accepts or rejects a booking.
--   Previously, BOTH on_booking_item_status_change() (from 003) AND
--   on_booking_status_change_notifications() (from 008) inserted notifications
--   for the same 'confirmed' / 'attention_needed' transition.
--   This migration keeps status synchronization in on_booking_item_status_change()
--   and delegates all booking lifecycle notifications strictly to
--   on_booking_status_change_notifications() (008).
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.on_booking_item_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_booking_status TEXT;
  v_total_items INTEGER;
  v_accepted_items INTEGER;
  v_rejected_items INTEGER;
BEGIN
  IF NEW.item_status = OLD.item_status THEN
    RETURN NEW;
  END IF;

  SELECT status INTO v_booking_status
  FROM public.bookings WHERE id = NEW.booking_id;

  -- لا نعيد تعديل حالة الحجز إذا كان ملغى أو مكتملاً بالفعل
  IF v_booking_status IN ('cancelled', 'completed') THEN
    RETURN NEW;
  END IF;

  -- إحصاء حالات عناصر الحجز
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE item_status = 'accepted'),
    COUNT(*) FILTER (WHERE item_status = 'rejected')
  INTO v_total_items, v_accepted_items, v_rejected_items
  FROM public.booking_items
  WHERE booking_id = NEW.booking_id;

  -- تحديث حالة الحجز الرئيسي فقط؛ الإشعارات يتكفل بها trg_booking_status_notifications منعاً للتكرار
  IF v_rejected_items > 0 THEN
    IF v_booking_status IS DISTINCT FROM 'attention_needed' THEN
      UPDATE public.bookings SET status = 'attention_needed' WHERE id = NEW.booking_id;
    END IF;
  ELSIF v_total_items > 0 AND v_accepted_items = v_total_items THEN
    IF v_booking_status IS DISTINCT FROM 'confirmed' THEN
      UPDATE public.bookings SET status = 'confirmed' WHERE id = NEW.booking_id;
    END IF;
  ELSIF v_accepted_items > 0 THEN
    IF v_booking_status IS DISTINCT FROM 'partially_accepted' THEN
      UPDATE public.bookings SET status = 'partially_accepted' WHERE id = NEW.booking_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

