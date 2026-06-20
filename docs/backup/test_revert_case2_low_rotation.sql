-- ============================================================
-- ReWear — TEST REVERT: Case 2  ⚠ Low Rotation +2
-- Restores every item's original last_worn_date.
-- Run this after testing Case 2.
-- ============================================================

BEGIN;

UPDATE public.items SET last_worn_date = '2026-06-05'  WHERE id = '61475ce7-1366-4761-a821-14d3b3d35131' AND user_id = '86c29170-c5cb-4f87-844e-949f38891406'; -- Red T shirt
UPDATE public.items SET last_worn_date = '2026-05-30'  WHERE id = '855446ca-d823-4a3f-b2e0-8e3d7fa9dea8' AND user_id = '86c29170-c5cb-4f87-844e-949f38891406'; -- Blue T shirt
UPDATE public.items SET last_worn_date = '2026-06-04'  WHERE id = '7eb04c06-3c3b-4f76-bf04-9424c9110f15' AND user_id = '86c29170-c5cb-4f87-844e-949f38891406'; -- Brown Casual Short
UPDATE public.items SET last_worn_date = '2026-06-03'  WHERE id = '492d6e1e-33c6-42ba-94ae-a66c9fa61e6b' AND user_id = '86c29170-c5cb-4f87-844e-949f38891406'; -- White Casual Shorts
UPDATE public.items SET last_worn_date = '2026-06-03'  WHERE id = '1cce3a54-41ab-4e70-81c5-ddd327410105' AND user_id = '86c29170-c5cb-4f87-844e-949f38891406'; -- Green T Shirt
UPDATE public.items SET last_worn_date = '2026-06-04'  WHERE id = '383f2bde-aa32-4571-8e9a-ce49261d2595' AND user_id = '86c29170-c5cb-4f87-844e-949f38891406'; -- Beige T-shirt
UPDATE public.items SET last_worn_date = '2026-06-04'  WHERE id = 'c8b73edf-11a1-4a93-adf0-115495f1a620' AND user_id = '86c29170-c5cb-4f87-844e-949f38891406'; -- White Jacket (CASUAL_JACKET)
UPDATE public.items SET last_worn_date = '2026-06-04'  WHERE id = '6fe82f20-25cd-4297-a248-a2498c532ec6' AND user_id = '86c29170-c5cb-4f87-844e-949f38891406'; -- Nike Sport Shoe
UPDATE public.items SET last_worn_date = '2026-06-04'  WHERE id = 'efccdd63-704a-47af-a08b-8b7b36dfe61e' AND user_id = '86c29170-c5cb-4f87-844e-949f38891406'; -- ONISUKA Casual Shoe
UPDATE public.items SET last_worn_date = '2026-06-04'  WHERE id = '1edf334a-14cb-4abb-be1b-2d5fde22bb6a' AND user_id = '86c29170-c5cb-4f87-844e-949f38891406'; -- Light Brown Casual Shorts
UPDATE public.items SET last_worn_date = '2025-11-06'  WHERE id = 'c6e17005-4123-468e-8a9d-899406dea197' AND user_id = '86c29170-c5cb-4f87-844e-949f38891406'; -- White T shirt 2
UPDATE public.items SET last_worn_date = '2026-06-01'  WHERE id = 'ba2eb495-66e3-443b-a463-f6d0d36042ca' AND user_id = '86c29170-c5cb-4f87-844e-949f38891406'; -- Beige Casual Sneakers
UPDATE public.items SET last_worn_date = '2025-11-15'  WHERE id = 'd89fc523-8ad1-4e28-8708-a7ee665b12b3' AND user_id = '86c29170-c5cb-4f87-844e-949f38891406'; -- Brown Casual Jacket
UPDATE public.items SET last_worn_date = '2026-06-14'  WHERE id = 'b8e1c17b-c950-425c-b7e8-6ebeee692057' AND user_id = '86c29170-c5cb-4f87-844e-949f38891406'; -- Dark Blue Casual Jacket
-- Dark Brown Casual Sneakers, HLA Button-Up, Apple Polo → last_worn_date was NULL, not touched.

COMMIT;
