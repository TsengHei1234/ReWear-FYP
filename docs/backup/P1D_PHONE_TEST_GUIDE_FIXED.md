# ReWear P1D Phone Test Guide — Fixed

Use `/mnt/data/p1d_phone_test_fixed.sql`. Run only ONE scenario block at a time, not the whole file.

## Shared phone steps for every scenario

1. Restore `rewear_backup_2026-06-19.sql` in Supabase SQL Editor.
2. Run only ONE scenario block from `p1d_phone_test_fixed.sql`.
3. Fully cold restart the app after running SQL. Do not rely on pull-to-refresh for these tests, because the SQL also changes the profile recommendation mode.
4. Go to Outfit Generator.
5. Occasion = Casual.
6. Layers = Top + Bottom only.
7. Clear pinned item.
8. Clear type filters.
9. Tap Generate Outfit.

## Scenario 1 — T1 Enough
Expected:
1. S1 White Anchor Top + S1 Black Chino A — Score 74 — no warning
2. S1 White Anchor Top + S1 Grey Chino B — Score 72 — no warning
3. S1 White Anchor Top + S1 Beige Chino C — Score 71 — no warning

Fail if S1 Red Gym Top Hidden or S1 Navy Formal Bottom Hidden appears.

## Scenario 2 — T2 Before T3
Expected:
1. S2 Red Matched Top + S2 Green Matched Bottom A — Score 53 — Weak colour match
2. S2 Red Matched Top + S2 Green Matched Bottom B — Score 51 — Weak colour match
3. S2 Red Matched Top + S2 Green Matched Bottom C — Score 50 — Weak colour match

Fail if S2 White Loose Top Hidden appears.

## Scenario 3 — Final Display Score Sort
Expected visible cards:
1. S3 White Loose Top + S3 Green Bottom A — Score 84 — Loose formality
2. S3 Red Matched Top + S3 Green Bottom A — Score 53 — Weak colour match
3. S3 Red Matched Top + S3 Green Bottom B — Score 51 — Weak colour match

This proves the selected set is tier-picked first, then visually sorted by score.
Fail if the visible order is T2, T2, T3.

## Scenario 4 — T4 Fallback
Expected:
1. S4 White Matched Top + S4 Green Matched Bottom A — Score 71 — no warning
2. S4 White Matched Top + S4 Green Matched Bottom B — Score 69 — no warning
3. S4 Red Loose Top + S4 Green Matched Bottom A — Score 66 — Loose formality +1

Card 3 is T4. Fail if card 3 does not appear or if it does not show Loose formality +1.

## Scenario 5 — Skip Item Replacement Follows P1D
Initial expected:
1. S5 Red Matched Top + S5 Black Bottom A — Score 71 — no warning
2. S5 Red Matched Top + S5 Grey Bottom B — Score 69 — no warning
3. S5 Red Matched Top + S5 Beige Bottom C Skip — Score 68 — no warning

Action:
Open card 3. Use the item-row skip icon for `S5 Beige Bottom C Skip`. Do NOT press bottom `Skip Outfit`.

After skip expected:
1. S5 Red Matched Top + S5 Black Bottom A — Score 71 — no warning
2. S5 Red Matched Top + S5 Grey Bottom B — Score 69 — no warning
3. S5 Red Matched Top + S5 Green Replacement Bottom — Score 49 — Weak colour match

Fail if S5 White Loose Top Higher Score appears after skip.

## Restore
After testing, restore `rewear_backup_2026-06-19.sql` again.
