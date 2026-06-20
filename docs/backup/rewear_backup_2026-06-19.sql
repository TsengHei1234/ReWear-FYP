-- ============================================================
-- ReWear — Supabase Data Restore Script
-- Generated : 2026-06-19
-- User      : suytsenghei@gmail.com (86c29170-c5cb-4f87-844e-949f38891406)
-- Snapshot  : Before Phase 10 outfit-generator testing session
-- Tables    : items (19 rows), item_events (23 rows),
--             outfit_logs (4 rows), outfit_log_items (11 rows),
--             profiles (UPDATE only — does not touch auth)
--
-- HOW TO RESTORE
-- 1. Open the Supabase dashboard → SQL Editor
-- 2. Paste this entire script and click Run
-- 3. Confirm the counts at the bottom match the numbers above
-- ============================================================

BEGIN;

-- ── Step 1: Delete in FK-safe order (children first) ─────────────────────────
DELETE FROM public.item_events      WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.outfit_log_items WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.outfit_logs      WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';
DELETE FROM public.items            WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';

-- ── Step 2: Restore items (19 rows) ──────────────────────────────────────────
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

-- Red T shirt
('61475ce7-1366-4761-a821-14d3b3d35131','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/61475ce7-1366-4761-a821-14d3b3d35131/main.jpg',
 'Red T shirt','TOP','T_SHIRT',ARRAY['red'],ARRAY['CASUAL','RELAX'],
 2,5,'AUTO',38,false,'IN_WARDROBE','2026-06-03',false,
 'ALREADY_OWNED_WORN','thisWeek','sixToTwenty','threeToSixMonths',180,
 false,false,12,'2026-06-05',0,NULL,NULL,NULL,
 '2026-06-03 13:43:25.171291+00','2026-06-18 19:38:41.044303+00'),

-- Blue T shirt
('855446ca-d823-4a3f-b2e0-8e3d7fa9dea8','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/855446ca-d823-4a3f-b2e0-8e3d7fa9dea8/main.jpg',
 'Blue T shirt','TOP','T_SHIRT',ARRAY['blue'],ARRAY['CASUAL'],
 2,5,'AUTO',38,false,'IN_WARDROBE','2026-06-03',false,
 'ALREADY_OWNED_WORN','thisWeek','sixToTwenty','sixToTwelveMonths',365,
 false,false,10,'2026-05-30',0,NULL,NULL,NULL,
 '2026-06-03 13:44:45.399955+00','2026-06-18 19:38:41.044303+00'),

-- Brown Casual Short
('7eb04c06-3c3b-4f76-bf04-9424c9110f15','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/7eb04c06-3c3b-4f76-bf04-9424c9110f15/main.jpg',
 'Brown Casual Short','BOTTOM','CASUAL_SHORTS',ARRAY['beige'],ARRAY['CASUAL'],
 2,3,'AUTO',83,false,'IN_WARDROBE','2026-06-03',false,
 'ALREADY_OWNED_WORN','thisWeek','twentyPlus','dontRemember',365,
 false,false,26,'2026-06-04',0,NULL,NULL,NULL,
 '2026-06-03 13:46:37.632005+00','2026-06-18 19:38:41.044303+00'),

-- White Casual Shorts
('492d6e1e-33c6-42ba-94ae-a66c9fa61e6b','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/492d6e1e-33c6-42ba-94ae-a66c9fa61e6b/main.jpg',
 'White Casual Shorts','BOTTOM','CASUAL_SHORTS',ARRAY['white'],ARRAY['CASUAL'],
 2,5,'AUTO',58,false,'IN_WARDROBE','2026-06-03',false,
 'ALREADY_OWNED_UNWORN',NULL,NULL,'sixToTwelveMonths',365,
 false,false,1,'2026-06-03',1,NULL,NULL,NULL,
 '2026-06-03 13:47:42.378174+00','2026-06-18 19:38:41.044303+00'),

-- Beige T shirt (status: DELETED)
('941415bf-c9e8-4b63-90ad-d663d503d515','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/941415bf-c9e8-4b63-90ad-d663d503d515/main.jpg',
 'Beige T shirt','TOP','T_SHIRT',ARRAY['beige'],ARRAY['CASUAL'],
 2,4,'AUTO',53,false,'DELETED','2026-06-03',false,
 'ALREADY_OWNED_WORN','threeToSixMonths','twentyPlus','oneToTwoYears',730,
 false,false,25,'2026-01-19',0,NULL,NULL,NULL,
 '2026-06-03 13:49:25.298998+00','2026-06-03 13:51:56.475075+00'),

-- Green T Shirt
('1cce3a54-41ab-4e70-81c5-ddd327410105','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/1cce3a54-41ab-4e70-81c5-ddd327410105/main.jpg',
 'Green T Shirt','TOP','T_SHIRT',ARRAY['green'],ARRAY['CASUAL','RELAX'],
 2,4,'AUTO',54,false,'IN_WARDROBE','2026-06-03',false,
 'ALREADY_OWNED_WORN','sixPlusMonths','twentyPlus','twoPlusYears',1095,
 false,false,26,'2026-06-03',2,NULL,NULL,NULL,
 '2026-06-03 13:50:35.961341+00','2026-06-18 19:18:02.165648+00'),

-- Beige T-shirt
('383f2bde-aa32-4571-8e9a-ce49261d2595','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/383f2bde-aa32-4571-8e9a-ce49261d2595/main.jpg',
 'Beige T-shirt','TOP','T_SHIRT',ARRAY['beige'],ARRAY['CASUAL'],
 2,5,'AUTO',53,false,'IN_WARDROBE','2026-06-03',false,
 'ALREADY_OWNED_WORN','threeToSixMonths','twentyPlus','twoPlusYears',1095,
 false,false,27,'2026-06-04',3,NULL,NULL,NULL,
 '2026-06-03 13:52:45.423302+00','2026-06-18 19:38:41.044303+00'),

-- White Jacket
('c8b73edf-11a1-4a93-adf0-115495f1a620','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/c8b73edf-11a1-4a93-adf0-115495f1a620/main.jpg',
 'White Jacket','OUTERWEAR','CASUAL_JACKET',ARRAY['white'],ARRAY['CASUAL','WORK'],
 2,3,'AUTO',59,false,'IN_WARDROBE','2026-06-04',false,
 'ALREADY_OWNED_WORN','thisWeek','twentyPlus','twoPlusYears',1095,
 false,false,26,'2026-06-04',0,NULL,NULL,NULL,
 '2026-06-03 17:45:12.617178+00','2026-06-18 19:38:41.044303+00'),

-- Nike Sport Shoe
('6fe82f20-25cd-4297-a248-a2498c532ec6','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/6fe82f20-25cd-4297-a248-a2498c532ec6/main.jpg',
 'Nike Sport Shoe','FOOTWEAR','SPORT_SHOES',ARRAY['white'],ARRAY['ACTIVE','CASUAL'],
 2,4,'AUTO',76,false,'IN_WARDROBE','2026-06-04',false,
 'ALREADY_OWNED_WORN','thisMonth','twentyPlus','twoPlusYears',1095,
 false,false,26,'2026-06-04',0,NULL,NULL,NULL,
 '2026-06-03 17:48:28.989259+00','2026-06-18 15:54:55.234011+00'),

-- ONISUKA Casual Shoe
('efccdd63-704a-47af-a08b-8b7b36dfe61e','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/efccdd63-704a-47af-a08b-8b7b36dfe61e/main.jpg',
 'ONISUKA Casual Shoe','FOOTWEAR','CASUAL_SNEAKERS',ARRAY['white'],ARRAY['CASUAL'],
 2,4,'AUTO',50,false,'IN_WARDROBE','2026-06-04',false,
 'ALREADY_OWNED_WORN','thisMonth','twentyPlus','twoPlusYears',1095,
 false,false,26,'2026-06-04',0,NULL,NULL,NULL,
 '2026-06-03 17:56:52.014474+00','2026-06-18 11:21:15.588422+00'),

-- Light Brown Casual Shorts
('1edf334a-14cb-4abb-be1b-2d5fde22bb6a','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/1edf334a-14cb-4abb-be1b-2d5fde22bb6a/main.jpg',
 'Light Brown Casual Shorts','BOTTOM','CASUAL_SHORTS',ARRAY['brown'],ARRAY['CASUAL','RELAX'],
 2,5,'AUTO',70,false,'IN_WARDROBE','2026-06-04',false,
 'ALREADY_OWNED_WORN','threeToSixMonths','sixToTwenty','sixToTwelveMonths',365,
 false,false,12,'2026-06-04',0,NULL,NULL,NULL,
 '2026-06-03 18:00:11.359957+00','2026-06-18 19:18:02.165648+00'),

-- White T shirt 1 (status: DONATED)
('352742fe-fc64-448e-9767-87784a36abad','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/352742fe-fc64-448e-9767-87784a36abad/main.jpg',
 'White T shirt 1','TOP','T_SHIRT',ARRAY['white'],ARRAY['CASUAL','RELAX'],
 2,4,'AUTO',38,false,'DONATED','2026-06-04',false,
 'ALREADY_OWNED_WORN','sixPlusMonths','sixToTwenty','oneToTwoYears',730,
 false,false,10,'2025-11-06',0,NULL,NULL,'2026-06-13',
 '2026-06-04 10:59:49.945866+00','2026-06-13 10:39:59.617883+00'),

-- White T shirt 2 (kept_until set)
('c6e17005-4123-468e-8a9d-899406dea197','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/c6e17005-4123-468e-8a9d-899406dea197/main.jpg',
 'White T shirt 2','TOP','T_SHIRT',ARRAY['white'],ARRAY['CASUAL','RELAX'],
 2,4,'AUTO',38,false,'IN_WARDROBE','2026-06-04',false,
 'ALREADY_OWNED_WORN','sixPlusMonths','sixToTwenty','oneToTwoYears',730,
 false,false,10,'2025-11-06',0,NULL,'2026-12-16',NULL,
 '2026-06-04 11:02:02.769705+00','2026-06-19 09:35:28.279804+00'),

-- Beige Casual Sneakers
('ba2eb495-66e3-443b-a463-f6d0d36042ca','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/ba2eb495-66e3-443b-a463-f6d0d36042ca/main.jpg',
 'Beige Casual Sneakers','FOOTWEAR','CASUAL_SNEAKERS',ARRAY['beige'],ARRAY['CASUAL','WORK'],
 2,2,'AUTO',50,false,'IN_WARDROBE','2026-06-05',false,
 'ALREADY_OWNED_WORN','thisWeek','twentyPlus','twoPlusYears',1095,
 false,false,25,'2026-06-01',0,NULL,NULL,NULL,
 '2026-06-05 12:28:34.744094+00','2026-06-18 19:38:41.044303+00'),

-- Brown Casual Jacket
('d89fc523-8ad1-4e28-8708-a7ee665b12b3','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/d89fc523-8ad1-4e28-8708-a7ee665b12b3/main.jpg',
 'Brown Casual Jacket','OUTERWEAR','CASUAL_JACKET',ARRAY['brown'],ARRAY['CASUAL'],
 2,5,'AUTO',37,false,'IN_WARDROBE','2026-06-13',false,
 'ALREADY_OWNED_WORN','sixPlusMonths','oneToFive','oneToTwoYears',730,
 false,false,3,'2025-11-15',0,NULL,NULL,NULL,
 '2026-06-13 09:02:29.790808+00','2026-06-19 09:43:17.21951+00'),

-- Dark Blue Casual Jacket
('b8e1c17b-c950-425c-b7e8-6ebeee692057','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/b8e1c17b-c950-425c-b7e8-6ebeee692057/main.jpg',
 'Dark Blue Casual Jacket','OUTERWEAR','CASUAL_JACKET',ARRAY['navy'],ARRAY['CASUAL','WORK'],
 2,4,'AUTO',59,false,'IN_WARDROBE','2026-06-13',false,
 'ALREADY_OWNED_WORN','thisWeek','twentyPlus','oneToThreeMonths',90,
 false,false,26,'2026-06-14',0,NULL,NULL,NULL,
 '2026-06-13 10:49:25.325025+00','2026-06-18 19:38:41.044303+00'),

-- Dark Brown Casual Sneakers
('6b5c9a8e-4f78-4aa3-aeae-77ee945db28d','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/6b5c9a8e-4f78-4aa3-aeae-77ee945db28d/main.jpg',
 'Dark Brown Casual Sneakers','FOOTWEAR','CASUAL_SNEAKERS',ARRAY['brown'],ARRAY['CASUAL','WORK'],
 2,5,'AUTO',25,false,'IN_WARDROBE','2026-06-13',false,
 'ALREADY_OWNED_UNWORN',NULL,NULL,'twoPlusYears',1095,
 false,false,0,NULL,0,NULL,NULL,NULL,
 '2026-06-13 12:08:03.337937+00','2026-06-18 19:38:41.044303+00'),

-- HLA White Casual Button-Up (brand new)
('5dfecd4e-58fa-4bef-ac0f-01c7d1070221','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/5dfecd4e-58fa-4bef-ac0f-01c7d1070221/main.jpg',
 'HLA White Casual Button-Up','TOP','CASUAL_BUTTON_UP_SHIRT',ARRAY['white'],ARRAY['CASUAL','WORK'],
 3,5,'AUTO',28,false,'IN_WARDROBE','2026-06-13',true,
 'BRAND_NEW',NULL,NULL,NULL,0,
 false,false,0,NULL,0,NULL,NULL,NULL,
 '2026-06-13 14:03:48.363001+00','2026-06-18 19:18:02.165648+00'),

-- Apple T shirt (brand new, polo)
('817e6357-6e83-4a0c-94b9-ebf89a7ca691','86c29170-c5cb-4f87-844e-949f38891406',
 '86c29170-c5cb-4f87-844e-949f38891406/817e6357-6e83-4a0c-94b9-ebf89a7ca691/main.jpg',
 'Apple T shirt','TOP','POLO_SHIRT',ARRAY['red'],ARRAY['CASUAL'],
 3,5,'AUTO',28,false,'IN_WARDROBE','2026-06-19',true,
 'BRAND_NEW',NULL,NULL,NULL,0,
 false,false,0,NULL,0,NULL,NULL,NULL,
 '2026-06-18 18:36:33.769962+00','2026-06-18 18:36:34.426212+00');

-- ── Step 3: Restore outfit_logs (4 rows) ─────────────────────────────────────
INSERT INTO public.outfit_logs (id, user_id, occasion, outfit_score, source, logged_at) VALUES
('19a9106b-b02e-4579-be33-2c334110a775','86c29170-c5cb-4f87-844e-949f38891406','CASUAL',0.5795754518705338,'OUTFIT_GENERATOR','2026-06-04 21:32:00.894848+00'),
('b53eb1a4-b855-4d53-85d2-4906e9d2a58d','86c29170-c5cb-4f87-844e-949f38891406','CASUAL',0.7563297402329439,'OUTFIT_GENERATOR','2026-06-04 06:45:28.863339+00'),
('f70eb909-647d-476e-ad33-72d2d16b015e','86c29170-c5cb-4f87-844e-949f38891406','CASUAL',0.7580136734024572,'OUTFIT_GENERATOR','2026-06-04 06:46:31.711241+00'),
('faea2d49-12d2-4690-978e-3b489907463f','86c29170-c5cb-4f87-844e-949f38891406','CASUAL',0.7660621958637469,'OUTFIT_GENERATOR','2026-06-03 18:06:29.906384+00');

-- ── Step 4: Restore outfit_log_items (11 rows) ───────────────────────────────
INSERT INTO public.outfit_log_items (id, user_id, outfit_log_id, item_id, layer_type) VALUES
('1a60a49b-5048-4477-9095-d1dab7a77943','86c29170-c5cb-4f87-844e-949f38891406','faea2d49-12d2-4690-978e-3b489907463f','1cce3a54-41ab-4e70-81c5-ddd327410105','TOP'),
('27e89e28-e1cc-4f3e-9c6a-602358705173','86c29170-c5cb-4f87-844e-949f38891406','f70eb909-647d-476e-ad33-72d2d16b015e','6fe82f20-25cd-4297-a248-a2498c532ec6','SHOES'),
('285ce24e-e3a5-4845-a55e-c8ca086f2ab2','86c29170-c5cb-4f87-844e-949f38891406','b53eb1a4-b855-4d53-85d2-4906e9d2a58d','383f2bde-aa32-4571-8e9a-ce49261d2595','TOP'),
('374d5c5d-2eb9-41b8-b266-0213593d7961','86c29170-c5cb-4f87-844e-949f38891406','b53eb1a4-b855-4d53-85d2-4906e9d2a58d','c8b73edf-11a1-4a93-adf0-115495f1a620','OUTERWEAR'),
('67390a94-032c-4a52-9ba1-7b4bae097e75','86c29170-c5cb-4f87-844e-949f38891406','b53eb1a4-b855-4d53-85d2-4906e9d2a58d','efccdd63-704a-47af-a08b-8b7b36dfe61e','SHOES'),
('7edb71ed-e153-40e3-83bc-39f22d0a5048','86c29170-c5cb-4f87-844e-949f38891406','19a9106b-b02e-4579-be33-2c334110a775','1edf334a-14cb-4abb-be1b-2d5fde22bb6a','BOTTOM'),
('82d34f88-c35e-4103-a437-c2c6a44e122a','86c29170-c5cb-4f87-844e-949f38891406','f70eb909-647d-476e-ad33-72d2d16b015e','1edf334a-14cb-4abb-be1b-2d5fde22bb6a','BOTTOM'),
('965f1f70-688d-467d-b884-3da85af8e551','86c29170-c5cb-4f87-844e-949f38891406','b53eb1a4-b855-4d53-85d2-4906e9d2a58d','7eb04c06-3c3b-4f76-bf04-9424c9110f15','BOTTOM'),
('976ff8be-ad9d-4832-a461-b7c14cd26c77','86c29170-c5cb-4f87-844e-949f38891406','19a9106b-b02e-4579-be33-2c334110a775','61475ce7-1366-4761-a821-14d3b3d35131','TOP'),
('a020eced-8786-4450-add2-52ab1940fc28','86c29170-c5cb-4f87-844e-949f38891406','f70eb909-647d-476e-ad33-72d2d16b015e','61475ce7-1366-4761-a821-14d3b3d35131','TOP'),
('b9880254-5fd7-4a29-ad0b-a63942030367','86c29170-c5cb-4f87-844e-949f38891406','faea2d49-12d2-4690-978e-3b489907463f','492d6e1e-33c6-42ba-94ae-a66c9fa61e6b','BOTTOM');

-- ── Step 5: Restore item_events (23 rows) ────────────────────────────────────
INSERT INTO public.item_events (id, user_id, item_id, event_type, source, occasion, outfit_log_id, event_at) VALUES
('20834fb6-f7f5-4b17-be85-f48d591d5161','86c29170-c5cb-4f87-844e-949f38891406','61475ce7-1366-4761-a821-14d3b3d35131','WORN','OUTFIT_GENERATOR','CASUAL','f70eb909-647d-476e-ad33-72d2d16b015e','2026-06-04 06:46:31.831802+00'),
('3128de77-6109-49e6-aed4-6c60921664a6','86c29170-c5cb-4f87-844e-949f38891406','383f2bde-aa32-4571-8e9a-ce49261d2595','SKIPPED','OUTFIT_GENERATOR',NULL,NULL,'2026-06-13 12:12:34.684353+00'),
('4e2bf14c-6ee1-429f-9916-dfdd36f8ce84','86c29170-c5cb-4f87-844e-949f38891406','383f2bde-aa32-4571-8e9a-ce49261d2595','SKIPPED','OUTFIT_GENERATOR',NULL,NULL,'2026-06-13 12:11:51.085956+00'),
('50c4f094-36f1-4e9c-bd8a-95b50269a050','86c29170-c5cb-4f87-844e-949f38891406','1cce3a54-41ab-4e70-81c5-ddd327410105','SKIPPED','OUTFIT_GENERATOR',NULL,NULL,'2026-06-03 17:53:41.457953+00'),
('560994d2-7627-4d27-8d30-8971eb262205','86c29170-c5cb-4f87-844e-949f38891406','383f2bde-aa32-4571-8e9a-ce49261d2595','WORN','OUTFIT_GENERATOR','CASUAL','b53eb1a4-b855-4d53-85d2-4906e9d2a58d','2026-06-04 06:45:29.047606+00'),
('5d5658e6-c341-42f3-8c60-5326305cc6fd','86c29170-c5cb-4f87-844e-949f38891406','492d6e1e-33c6-42ba-94ae-a66c9fa61e6b','SKIPPED','OUTFIT_GENERATOR',NULL,NULL,'2026-06-03 18:01:54.371973+00'),
('6326facc-8173-44e5-a873-5f806225b4e2','86c29170-c5cb-4f87-844e-949f38891406','383f2bde-aa32-4571-8e9a-ce49261d2595','SKIPPED','OUTFIT_GENERATOR',NULL,NULL,'2026-06-13 12:12:27.210783+00'),
('6c9cbb24-38f2-4bea-b593-d9b7446cd2ae','86c29170-c5cb-4f87-844e-949f38891406','6fe82f20-25cd-4297-a248-a2498c532ec6','WORN','OUTFIT_GENERATOR','CASUAL','f70eb909-647d-476e-ad33-72d2d16b015e','2026-06-04 06:46:32.017583+00'),
('6daeacf0-2db6-4ae8-9bc3-d970db000f63','86c29170-c5cb-4f87-844e-949f38891406','61475ce7-1366-4761-a821-14d3b3d35131','WORN','OUTFIT_GENERATOR','CASUAL','19a9106b-b02e-4579-be33-2c334110a775','2026-06-04 21:32:01.00135+00'),
('72b046da-e9be-49da-a298-6073f566c411','86c29170-c5cb-4f87-844e-949f38891406','1cce3a54-41ab-4e70-81c5-ddd327410105','SKIPPED','OUTFIT_GENERATOR',NULL,NULL,'2026-06-03 18:01:54.241142+00'),
('78d48e9d-3d09-46af-87aa-85ec532c5c64','86c29170-c5cb-4f87-844e-949f38891406','7eb04c06-3c3b-4f76-bf04-9424c9110f15','WORN','OUTFIT_GENERATOR','CASUAL','b53eb1a4-b855-4d53-85d2-4906e9d2a58d','2026-06-04 06:45:29.156128+00'),
('88d98a2c-22a1-468f-96d7-126791dab4d1','86c29170-c5cb-4f87-844e-949f38891406','b8e1c17b-c950-425c-b7e8-6ebeee692057','WORN','ITEM_DETAIL',NULL,NULL,'2026-06-14 13:01:39.10062+00'),
('8b3effc7-3bd3-4625-af9a-0ae0c51b369a','86c29170-c5cb-4f87-844e-949f38891406','383f2bde-aa32-4571-8e9a-ce49261d2595','WORN','ITEM_DETAIL',NULL,NULL,'2026-06-04 06:58:16.789539+00'),
('8c9f3245-9144-466c-8030-ef3f6370db1b','86c29170-c5cb-4f87-844e-949f38891406','1edf334a-14cb-4abb-be1b-2d5fde22bb6a','WORN','OUTFIT_GENERATOR','CASUAL','19a9106b-b02e-4579-be33-2c334110a775','2026-06-04 21:32:01.102396+00'),
('9bd4f9ad-8755-4d2b-813e-42b2f8062883','86c29170-c5cb-4f87-844e-949f38891406','1cce3a54-41ab-4e70-81c5-ddd327410105','WORN','OUTFIT_GENERATOR','CASUAL','faea2d49-12d2-4690-978e-3b489907463f','2026-06-03 18:06:30.085098+00'),
('c17a14b8-eecb-43ba-aef6-3a9ff11debd5','86c29170-c5cb-4f87-844e-949f38891406','383f2bde-aa32-4571-8e9a-ce49261d2595','SKIPPED','OUTFIT_GENERATOR',NULL,NULL,'2026-06-13 12:11:21.191868+00'),
('cc9b3e41-defd-4a9a-93c4-c6a4b6924101','86c29170-c5cb-4f87-844e-949f38891406','492d6e1e-33c6-42ba-94ae-a66c9fa61e6b','WORN','OUTFIT_GENERATOR','CASUAL','faea2d49-12d2-4690-978e-3b489907463f','2026-06-03 18:06:30.201088+00'),
('d159cf6e-5e2f-4ced-8907-732fe4544e48','86c29170-c5cb-4f87-844e-949f38891406','383f2bde-aa32-4571-8e9a-ce49261d2595','SKIPPED','OUTFIT_GENERATOR',NULL,NULL,'2026-06-13 12:13:42.436548+00'),
('e6d57e12-c217-4f24-bace-d9926f18b7d6','86c29170-c5cb-4f87-844e-949f38891406','efccdd63-704a-47af-a08b-8b7b36dfe61e','WORN','OUTFIT_GENERATOR','CASUAL','b53eb1a4-b855-4d53-85d2-4906e9d2a58d','2026-06-04 06:45:29.421415+00'),
('f0863e14-5e54-446a-ae9f-d7a6da993fc2','86c29170-c5cb-4f87-844e-949f38891406','c8b73edf-11a1-4a93-adf0-115495f1a620','WORN','OUTFIT_GENERATOR','CASUAL','b53eb1a4-b855-4d53-85d2-4906e9d2a58d','2026-06-04 06:45:29.30336+00'),
('f904a149-114a-4a0a-9be3-2827edc54aa8','86c29170-c5cb-4f87-844e-949f38891406','1edf334a-14cb-4abb-be1b-2d5fde22bb6a','WORN','OUTFIT_GENERATOR','CASUAL','f70eb909-647d-476e-ad33-72d2d16b015e','2026-06-04 06:46:31.921928+00'),
('fa299a05-ad0a-48e3-8ce6-08b198cbfae2','86c29170-c5cb-4f87-844e-949f38891406','383f2bde-aa32-4571-8e9a-ce49261d2595','SKIPPED','OUTFIT_GENERATOR',NULL,NULL,'2026-06-13 12:12:31.222678+00'),
('fc05c082-8753-417a-b711-c59ed712fe76','86c29170-c5cb-4f87-844e-949f38891406','383f2bde-aa32-4571-8e9a-ce49261d2595','SKIPPED','OUTFIT_GENERATOR',NULL,NULL,'2026-06-13 12:13:17.048804+00');

-- ── Step 6: Restore profile (UPDATE only — auth row is untouched) ─────────────
UPDATE public.profiles SET
  email               = 'suytsenghei@gmail.com',
  display_name        = 'Tseng Hei',
  style_preferences   = '{"disliked_colours":["purple","pink","green"],"preferred_colours":["beige","white","blue"]}'::jsonb,
  laundry_cycle_days  = 3,
  recommendation_mode = 'BALANCED',
  updated_at          = '2026-06-19 09:43:38.487889+00'
WHERE id = '86c29170-c5cb-4f87-844e-949f38891406';

-- ── Verification counts (should match header) ─────────────────────────────────
SELECT 'items'            AS tbl, COUNT(*) FROM public.items            WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406'
UNION ALL
SELECT 'item_events'      AS tbl, COUNT(*) FROM public.item_events      WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406'
UNION ALL
SELECT 'outfit_logs'      AS tbl, COUNT(*) FROM public.outfit_logs      WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406'
UNION ALL
SELECT 'outfit_log_items' AS tbl, COUNT(*) FROM public.outfit_log_items WHERE user_id = '86c29170-c5cb-4f87-844e-949f38891406';

COMMIT;
