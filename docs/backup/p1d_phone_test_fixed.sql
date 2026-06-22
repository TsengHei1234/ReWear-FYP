-- ============================================================
-- ReWear — P1D Phone Testing SQL (FIXED / code-aware)
-- Purpose : Isolated item sets for manual phone testing of P1D tier ordering
-- User    : 86c29170-c5cb-4f87-844e-949f38891406
-- Safety  : Each scenario deletes ONLY this user's ReWear rows, then inserts
--           temporary test items. It does NOT touch auth.users.
--
-- HOW TO USE
-- 1) Restore rewear_backup_2026-06-19.sql first.
-- 2) Run ONLY ONE scenario block at a time.
-- 3) Cold restart app or pull-to-refresh.
-- 4) Outfit Generator -> Occasion Casual -> Top + Bottom only -> clear pin -> clear type filters -> Generate Outfit.
-- 5) After all testing, restore rewear_backup_2026-06-19.sql again.
-- ============================================================

-- ============================================================
-- SCENARIO 1 — T1 ENOUGH
-- Goal: T1 matched + acceptable colour fills all 3 cards.
-- Hidden high-score loose outfit exists, but T1 tier is selected first.
-- Expected cards:
--   1. S1 White Anchor Top + S1 Black Chino A       Score 74  no warning
--   2. S1 White Anchor Top + S1 Grey Chino B        Score 72  no warning
--   3. S1 White Anchor Top + S1 Beige Chino C       Score 71  no warning
-- Fail if S1 Red Gym Top Hidden or S1 Navy Formal Bottom Hidden appears.
-- ============================================================
BEGIN;

DELETE FROM public.item_events      WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.outfit_log_items WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.outfit_logs      WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.items            WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';

UPDATE public.profiles SET
  style_preferences = '{"preferred_colours":[],"disliked_colours":[]}'::jsonb,
  recommendation_mode = 'PURE_ROTATION'
WHERE id = '86c29170-c5cb-4f87-844e-949f38891406';

INSERT INTO public.items (
  id, user_id, image_path, name, category, type,
  color_tags, occasion_tags,
  formality_level, condition, condition_review_mode, condition_next_drop,
  is_favorite, status, date_added, is_new_item,
  initial_history_type, initial_last_worn_option, initial_wear_count_option,
  initial_owned_duration_option, initial_usage_age_days,
  wear_count_unknown, last_worn_unknown,
  wear_count, last_worn_date, skip_count,
  laundry_started_at, kept_until, donated_at,
  created_at, updated_at
) VALUES
('10000000-0000-4000-8000-000000000001','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S1 White Anchor Top','TOP','T_SHIRT',ARRAY['white'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,0,NULL,NULL,NULL,now(),now()),
('10000000-0000-4000-8000-000000000002','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S1 Red Gym Top Hidden','TOP','SPORTS_T_SHIRT',ARRAY['red'],ARRAY['CASUAL'],1,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,false,false,0,NULL,0,NULL,NULL,NULL,now(),now()),
('10000000-0000-4000-8000-000000000011','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S1 Black Chino A','BOTTOM','CHINOS',ARRAY['black'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,0,NULL,NULL,NULL,now(),now()),
('10000000-0000-4000-8000-000000000012','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S1 Grey Chino B','BOTTOM','CHINOS',ARRAY['grey'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,1,NULL,NULL,NULL,now(),now()),
('10000000-0000-4000-8000-000000000013','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S1 Beige Chino C','BOTTOM','CHINOS',ARRAY['beige'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,2,NULL,NULL,NULL,now(),now()),
('10000000-0000-4000-8000-000000000014','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S1 Navy Formal Bottom Hidden','BOTTOM','FORMAL_TROUSERS_SLACKS',ARRAY['navy'],ARRAY['CASUAL'],5,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,false,false,0,NULL,0,NULL,NULL,NULL,now(),now());

COMMIT;

-- ============================================================
-- SCENARIO 2 — T2 BEFORE T3
-- Goal: matched + weak colour (T2) is selected before higher-score loose + acceptable colour (T3).
-- Expected cards:
--   1. S2 Red Matched Top + S2 Green Matched Bottom A  Score 53  Weak colour match
--   2. S2 Red Matched Top + S2 Green Matched Bottom B  Score 51  Weak colour match
--   3. S2 Red Matched Top + S2 Green Matched Bottom C  Score 50  Weak colour match
-- Hidden higher-score T3 exists through S2 White Loose Top Hidden, but T2 fills all 3.
-- Fail if S2 White Loose Top Hidden appears.
-- ============================================================
BEGIN;

DELETE FROM public.item_events      WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.outfit_log_items WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.outfit_logs      WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.items            WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';

UPDATE public.profiles SET
  style_preferences = '{"preferred_colours":[],"disliked_colours":[]}'::jsonb,
  recommendation_mode = 'PURE_ROTATION'
WHERE id = '86c29170-c5cb-4f87-844e-949f38891406';

INSERT INTO public.items (
  id, user_id, image_path, name, category, type,
  color_tags, occasion_tags,
  formality_level, condition, condition_review_mode, condition_next_drop,
  is_favorite, status, date_added, is_new_item,
  initial_history_type, initial_last_worn_option, initial_wear_count_option,
  initial_owned_duration_option, initial_usage_age_days,
  wear_count_unknown, last_worn_unknown,
  wear_count, last_worn_date, skip_count,
  laundry_started_at, kept_until, donated_at,
  created_at, updated_at
) VALUES
('20000000-0000-4000-8000-000000000001','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S2 Red Matched Top','TOP','T_SHIRT',ARRAY['red'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,0,NULL,NULL,NULL,now(),now()),
('20000000-0000-4000-8000-000000000002','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S2 White Loose Top Hidden','TOP','SPORTS_T_SHIRT',ARRAY['white'],ARRAY['CASUAL'],1,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,false,false,0,NULL,0,NULL,NULL,NULL,now(),now()),
('20000000-0000-4000-8000-000000000011','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S2 Green Matched Bottom A','BOTTOM','CHINOS',ARRAY['green'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,0,NULL,NULL,NULL,now(),now()),
('20000000-0000-4000-8000-000000000012','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S2 Green Matched Bottom B','BOTTOM','CHINOS',ARRAY['green'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,1,NULL,NULL,NULL,now(),now()),
('20000000-0000-4000-8000-000000000013','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S2 Green Matched Bottom C','BOTTOM','CHINOS',ARRAY['green'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,2,NULL,NULL,NULL,now(),now()),
('20000000-0000-4000-8000-000000000014','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S2 Navy Loose Bottom Hidden','BOTTOM','FORMAL_TROUSERS_SLACKS',ARRAY['navy'],ARRAY['CASUAL'],5,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,false,false,0,NULL,0,NULL,NULL,NULL,now(),now());

COMMIT;

-- ============================================================
-- SCENARIO 3 — FINAL DISPLAY SCORE SORT
-- Goal: P1D selects by tier first (T2,T2,T3), then UI displays selected cards by OutfitScore.
-- Expected visible cards AFTER display sort:
--   1. S3 White Loose Top + S3 Green Bottom A      Score 84  Loose formality
--   2. S3 Red Matched Top + S3 Green Bottom A      Score 53  Weak colour match
--   3. S3 Red Matched Top + S3 Green Bottom B      Score 51  Weak colour match
-- Fail if visible order is T2, T2, T3 instead of score-descending.
-- ============================================================
BEGIN;

DELETE FROM public.item_events      WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.outfit_log_items WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.outfit_logs      WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.items            WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';

UPDATE public.profiles SET
  style_preferences = '{"preferred_colours":[],"disliked_colours":[]}'::jsonb,
  recommendation_mode = 'PURE_ROTATION'
WHERE id = '86c29170-c5cb-4f87-844e-949f38891406';

INSERT INTO public.items (
  id, user_id, image_path, name, category, type,
  color_tags, occasion_tags,
  formality_level, condition, condition_review_mode, condition_next_drop,
  is_favorite, status, date_added, is_new_item,
  initial_history_type, initial_last_worn_option, initial_wear_count_option,
  initial_owned_duration_option, initial_usage_age_days,
  wear_count_unknown, last_worn_unknown,
  wear_count, last_worn_date, skip_count,
  laundry_started_at, kept_until, donated_at,
  created_at, updated_at
) VALUES
('30000000-0000-4000-8000-000000000001','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S3 Red Matched Top','TOP','T_SHIRT',ARRAY['red'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,0,NULL,NULL,NULL,now(),now()),
('30000000-0000-4000-8000-000000000002','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S3 White Loose Top','TOP','SPORTS_T_SHIRT',ARRAY['white'],ARRAY['CASUAL'],1,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,false,false,0,NULL,0,NULL,NULL,NULL,now(),now()),
('30000000-0000-4000-8000-000000000011','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S3 Green Bottom A','BOTTOM','CHINOS',ARRAY['green'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,0,NULL,NULL,NULL,now(),now()),
('30000000-0000-4000-8000-000000000012','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S3 Green Bottom B','BOTTOM','CHINOS',ARRAY['green'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,1,NULL,NULL,NULL,now(),now()),
('30000000-0000-4000-8000-000000000013','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S3 Navy Loose Bottom','BOTTOM','FORMAL_TROUSERS_SLACKS',ARRAY['navy'],ARRAY['CASUAL'],5,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,false,false,0,NULL,0,NULL,NULL,NULL,now(),now());

COMMIT;

-- ============================================================
-- SCENARIO 4 — T4 FALLBACK
-- Goal: loose + weak colour (T4) appears only because better tiers cannot fill 3 cards.
-- Expected cards:
--   1. S4 White Matched Top + S4 Green Matched Bottom A  Score 71  no warning
--   2. S4 White Matched Top + S4 Green Matched Bottom B  Score 69  no warning
--   3. S4 Red Loose Top + S4 Green Matched Bottom A      Score 66  Loose formality +1
-- Card 3 is T4.
-- ============================================================
BEGIN;

DELETE FROM public.item_events      WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.outfit_log_items WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.outfit_logs      WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.items            WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';

UPDATE public.profiles SET
  style_preferences = '{"preferred_colours":[],"disliked_colours":[]}'::jsonb,
  recommendation_mode = 'PURE_ROTATION'
WHERE id = '86c29170-c5cb-4f87-844e-949f38891406';

INSERT INTO public.items (
  id, user_id, image_path, name, category, type,
  color_tags, occasion_tags,
  formality_level, condition, condition_review_mode, condition_next_drop,
  is_favorite, status, date_added, is_new_item,
  initial_history_type, initial_last_worn_option, initial_wear_count_option,
  initial_owned_duration_option, initial_usage_age_days,
  wear_count_unknown, last_worn_unknown,
  wear_count, last_worn_date, skip_count,
  laundry_started_at, kept_until, donated_at,
  created_at, updated_at
) VALUES
('40000000-0000-4000-8000-000000000001','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S4 White Matched Top','TOP','T_SHIRT',ARRAY['white'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,0,NULL,NULL,NULL,now(),now()),
('40000000-0000-4000-8000-000000000002','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S4 Red Loose Top','TOP','SPORTS_T_SHIRT',ARRAY['red'],ARRAY['CASUAL'],1,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,false,false,0,NULL,0,NULL,NULL,NULL,now(),now()),
('40000000-0000-4000-8000-000000000011','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S4 Green Matched Bottom A','BOTTOM','CHINOS',ARRAY['green'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,0,NULL,NULL,NULL,now(),now()),
('40000000-0000-4000-8000-000000000012','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S4 Green Matched Bottom B','BOTTOM','CHINOS',ARRAY['green'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,1,NULL,NULL,NULL,now(),now()),
('40000000-0000-4000-8000-000000000013','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S4 Green High Bottom Source','BOTTOM','FORMAL_TROUSERS_SLACKS',ARRAY['green'],ARRAY['CASUAL'],5,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,false,false,0,NULL,0,NULL,NULL,NULL,now(),now());

COMMIT;

-- ============================================================
-- SCENARIO 5 — SKIP ITEM REPLACEMENT FOLLOWS P1D
-- Goal: after skipping card 3's bottom item, replacement chooses T2 before higher-score T3.
-- Initial expected cards:
--   1. S5 Red Matched Top + S5 Black Bottom A        Score 71  no warning
--   2. S5 Red Matched Top + S5 Grey Bottom B         Score 69  no warning
--   3. S5 Red Matched Top + S5 Beige Bottom C Skip   Score 68  no warning
-- Action: Open card 3 -> skip item S5 Beige Bottom C Skip (row skip icon), NOT Skip Outfit.
-- After skip expected cards:
--   1. S5 Red Matched Top + S5 Black Bottom A        Score 71  no warning
--   2. S5 Red Matched Top + S5 Grey Bottom B         Score 69  no warning
--   3. S5 Red Matched Top + S5 Green Replacement Bottom Score 49  Weak colour match
-- Fail if S5 White Loose Top Higher Score appears after skip.
-- ============================================================
BEGIN;

DELETE FROM public.item_events      WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.outfit_log_items WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.outfit_logs      WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.items            WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';

UPDATE public.profiles SET
  style_preferences = '{"preferred_colours":[],"disliked_colours":[]}'::jsonb,
  recommendation_mode = 'PURE_ROTATION'
WHERE id = '86c29170-c5cb-4f87-844e-949f38891406';

INSERT INTO public.items (
  id, user_id, image_path, name, category, type,
  color_tags, occasion_tags,
  formality_level, condition, condition_review_mode, condition_next_drop,
  is_favorite, status, date_added, is_new_item,
  initial_history_type, initial_last_worn_option, initial_wear_count_option,
  initial_owned_duration_option, initial_usage_age_days,
  wear_count_unknown, last_worn_unknown,
  wear_count, last_worn_date, skip_count,
  laundry_started_at, kept_until, donated_at,
  created_at, updated_at
) VALUES
('50000000-0000-4000-8000-000000000001','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S5 Red Matched Top','TOP','T_SHIRT',ARRAY['red'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,0,NULL,NULL,NULL,now(),now()),
('50000000-0000-4000-8000-000000000002','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S5 White Loose Top Higher Score','TOP','SPORTS_T_SHIRT',ARRAY['white'],ARRAY['CASUAL'],1,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,false,false,0,NULL,0,NULL,NULL,NULL,now(),now()),
('50000000-0000-4000-8000-000000000011','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S5 Black Bottom A','BOTTOM','CHINOS',ARRAY['black'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,0,NULL,NULL,NULL,now(),now()),
('50000000-0000-4000-8000-000000000012','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S5 Grey Bottom B','BOTTOM','CHINOS',ARRAY['grey'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,1,NULL,NULL,NULL,now(),now()),
('50000000-0000-4000-8000-000000000013','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S5 Beige Bottom C Skip','BOTTOM','CHINOS',ARRAY['beige'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,2,NULL,NULL,NULL,now(),now()),
('50000000-0000-4000-8000-000000000014','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S5 Green Replacement Bottom','BOTTOM','CHINOS',ARRAY['green'],ARRAY['CASUAL'],3,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,true,true,0,NULL,3,NULL,NULL,NULL,now(),now()),
('50000000-0000-4000-8000-000000000015','86c29170-c5cb-4f87-844e-949f38891406',NULL,'S5 Navy Higher Score Loose Bottom','BOTTOM','FORMAL_TROUSERS_SLACKS',ARRAY['navy'],ARRAY['CASUAL'],5,5,'AUTO',999,false,'IN_WARDROBE',current_date-200,false,'ALREADY_OWNED_UNWORN',NULL,NULL,'oneToTwoYears',365,false,false,0,NULL,0,NULL,NULL,NULL,now(),now());

COMMIT;
