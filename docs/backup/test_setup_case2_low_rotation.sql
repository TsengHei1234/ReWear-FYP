-- ============================================================
-- ReWear — TEST SETUP: Case 2  ⚠ Low Rotation +2
-- Sets all IN_WARDROBE items with a known last_worn_date to TODAY
-- so every item's TDS ≈ 0 → every generated outfit shows
-- ⚠ Low Rotation +2 in the subtitle.
--
-- HOW TO USE
--   1. Paste into Supabase SQL Editor and Run.
--   2. Open app → Outfit Generator → Generate any Casual outfit.
--   3. Every card subtitle should read:
--        Casual · ⚠ Low Rotation +2
--   4. When done → run test_revert_case2_low_rotation.sql to restore.
--
-- NOTE: Run this BEFORE test_setup_cases345.sql (or after its revert).
--       Do NOT have the Cases 3-5 test items in the wardrobe at the
--       same time, or their dates will also be set to today, breaking
--       the high-TDS state you need for Cases 4/5.
-- ============================================================

BEGIN;

UPDATE public.items
SET last_worn_date = '2026-06-21'
WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406'
  AND status = 'IN_WARDROBE'
  AND last_worn_date IS NOT NULL;

COMMIT;
