-- ============================================================
-- ReWear — TEST SETUP: Cases 3 / 4 / 5
--   Case 3  ⚠ Loose formality
--   Case 4  ⚠ Weak colour match
--   Case 5  ⚠ Loose formality +1  (both warnings)
--
-- Inserts 4 test items (no image — image_path nullable by design).
-- All items have last_worn_date ~30 days ago so TDS = 1.0 (High
-- Rotation) and the generator will eagerly pick them when filtered.
--
-- After testing → run test_revert_cases345_loose_colour.sql.
-- ============================================================
--
-- ITEM GUIDE
-- ┌─────────────────────┬──────────────┬──────────┬──────────────────┐
-- │ Name                │ Type         │ Colour   │ Used in case     │
-- ├─────────────────────┼──────────────┼──────────┼──────────────────┤
-- │ [TEST] Purple Blazer│ BLAZER (f=4) │ purple   │ 3, 5             │
-- │ [TEST] Orange T-Shirt│ T_SHIRT (f=2)│ orange   │ 4, 5  (PIN ME)  │
-- │ [TEST] Blue Leggings│ LEGGINGS(f=1)│ blue     │ 4, 5             │
-- │ [TEST] Orange Sandals│SANDALS (f=2) │ orange   │ 4, 5             │
-- └─────────────────────┴──────────────┴──────────┴──────────────────┘
--
-- COLOUR SCORE MATHS (why these colours were chosen)
--   Case 4 / 5 outfit colour pairs:
--     orange ↔ blue        = 0.30  (blue|orange clash)
--     blue   ↔ orange      = 0.30  (blue|orange clash)
--     orange ↔ purple      = 0.30  (orange|purple clash)
--     purple ↔ orange      = 0.30  (orange|purple clash)
--   Average for 4-item (Case 5): 0.30 → Fallback badge → ⚠ Weak colour match ✓
--   Average for 3-item (Case 4): 0.30 → Fallback badge → ⚠ Weak colour match ✓
--
--   Case 3 outfit (Purple Blazer + neutral existing clothes):
--     purple ↔ white/beige = 0.90  (achromatic + chromatic)
--     neutrals ↔ neutrals  = 1.00
--   Average ≈ 0.95 → Strong badge → NO colour warning ✓
-- ============================================================

BEGIN;

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

-- [TEST] Purple Blazer — f=4, used for Cases 3 + 5 (loose formality)
-- Last worn 37 days ago → TDS=1.0, generator picks it eagerly when Blazer is filtered.
('00000001-0000-0000-0000-000000000001','86c29170-c5cb-4f87-844e-949f38891406',
 NULL,
 '[TEST] Purple Blazer','OUTERWEAR','BLAZER',
 ARRAY['purple'],ARRAY['WORK','CASUAL'],
 4,5,'AUTO',30,
 false,'IN_WARDROBE','2026-06-21',false,
 'ALREADY_OWNED_WORN','threeToSixMonths','oneToFive',
 'oneToTwoYears',365,
 false,false,
 5,'2026-05-15',0,
 NULL,NULL,NULL,
 NOW(),NOW()),

-- [TEST] Orange T-Shirt — f=2, used for Cases 4 + 5 (colour clash trigger)
-- Last worn 30 days ago → TDS=1.0. PIN THIS ITEM when testing Cases 4 and 5.
('00000001-0000-0000-0000-000000000002','86c29170-c5cb-4f87-844e-949f38891406',
 NULL,
 '[TEST] Orange T-Shirt','TOP','T_SHIRT',
 ARRAY['orange'],ARRAY['CASUAL','RELAX'],
 2,5,'AUTO',30,
 false,'IN_WARDROBE','2026-06-21',false,
 'ALREADY_OWNED_WORN','threeToSixMonths','oneToFive',
 'oneToTwoYears',365,
 false,false,
 5,'2026-05-22',0,
 NULL,NULL,NULL,
 NOW(),NOW()),

-- [TEST] Blue Leggings — f=1, used for Cases 4 + 5 (colour clash + unique type)
-- Only legging in wardrobe → generator MUST pick it when Bottom=Leggings is filtered.
('00000001-0000-0000-0000-000000000003','86c29170-c5cb-4f87-844e-949f38891406',
 NULL,
 '[TEST] Blue Leggings','BOTTOM','LEGGINGS',
 ARRAY['blue'],ARRAY['CASUAL','RELAX'],
 1,5,'AUTO',30,
 false,'IN_WARDROBE','2026-06-21',false,
 'ALREADY_OWNED_WORN','threeToSixMonths','oneToFive',
 'oneToTwoYears',365,
 false,false,
 5,'2026-05-22',0,
 NULL,NULL,NULL,
 NOW(),NOW()),

-- [TEST] Orange Sandals — f=2, used for Cases 4 + 5 (colour clash + unique type)
-- Only sandal in wardrobe → generator MUST pick it when Shoes=Sandals is filtered.
('00000001-0000-0000-0000-000000000004','86c29170-c5cb-4f87-844e-949f38891406',
 NULL,
 '[TEST] Orange Sandals','FOOTWEAR','SANDALS',
 ARRAY['orange'],ARRAY['CASUAL','RELAX'],
 2,5,'AUTO',30,
 false,'IN_WARDROBE','2026-06-21',false,
 'ALREADY_OWNED_WORN','threeToSixMonths','oneToFive',
 'oneToTwoYears',365,
 false,false,
 5,'2026-05-22',0,
 NULL,NULL,NULL,
 NOW(),NOW());

COMMIT;
