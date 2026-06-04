# Contract — Outfit Detail (UI, Phase 6 Step 4)

**Sources:** FE §24 + agreed mock. RE "Outfit Detail Explainability Rules" via the
built `buildExplanationForOutfit`. Skip model = **DECISIONS G3**; session = **G1**.
**Location:** `lib/features/outfit/outfit_detail_page.dart` (route `/outfit-detail`,
extra = `OutfitDetailArgs{scored, occasion, optionNumber}`). Reached from a Generator
result-card tap.

## Data
Recompute the explanation on the page (the gotcha — `ScoredOutfit` has no per-item
sub-scores): `buildExplanationForOutfit(outfit, wardrobe, mode, prefs, scored.formality,
scored.colourScore, scored.displayScore, occasion, pinnedItem, now)`.

## Sections
- **Header card** (compact): "Outfit Option N" + occasion pill + "Score N" pill +
  "N items" + one-line summary = `pinned ? "Built around your selected item." :
  exp.scoreMessage` (no occasion-dominant line; occasion is the pill).
- **Items in This Outfit:** one row per filled slot — thumbnail + layer label
  (Top/Bottom/Outerwear/Shoes) + name + `lastWornLabel` + **skip icon** + **chevron**.
  Row tap (not the skip icon) → Item Detail. No wear/skip/condition/score on the row.
- **Why Suggested:** `exp.whyReasons` bullets (engine MD-priority list).
- **Rule Breakdown:** `exp.ruleBreakdown` 5 rows (name + description + status badge).
  **Friendly display names:** Temporal Decay→**Rotation Priority**, Skip Penalty→
  **Skip Feedback**, others unchanged. Badge colour: green good / amber medium / red bad.

## Actions (DECISIONS G3 + G1)
- **Skip Item** (row icon) → confirm ("Skip this item?" / "It'll be replaced here and
  suggested less often.") → `outfitGeneratorProvider.skip([item])` → pop to Generator.
- **Skip Outfit** (bottom, left) → confirm ("Skip this outfit?" / "Every item will be
  replaced where possible and suggested less often.") → `skip(outfit.items)` → pop.
- **Log Outfit** (bottom, right, primary) → confirm ("Log this outfit?" / "All items
  will be marked worn today…") → `WardrobeNotifier.logOutfitWorn(pieces, occasion,
  outfitScore)` → pop + snackbar. Writes `outfit_logs` + `outfit_log_items` + a linked
  WORN `item_events` per item + wear/condition updates; ends session + clears pin (G1)
  and worn items drop from today's recommendations (G2).

## Not here
- Daily Rotation has NO "Why this outfit" (it recommends items, not outfits).
- Per-item full data lives in Item Detail (via the row chevron).
