# Contract — Outfit Assembler (Layer 3: P1a/P1b/P1c + OutfitScore)

**Source:** RE "Layer 3 — Post-Processing Rules" (P1a, P1b, P1c, OutfitScore).
**Location:** `lib/engine/outfit/outfit.dart` (model) + `outfit_assembler.dart` + tests.
**Purity:** pure Dart. Reuses `colourScore` (M1) and `frs.dart`.

## Outfit model
Slots: TOP + BOTTOM (required), OUTERWEAR + SHOES (optional). `items` = present
items; `itemIds` = their ids. SHOES slot holds a FOOTWEAR-category item.

## P1a — Category Completeness (hard rule)
A valid outfit = 1 TOP + 1 BOTTOM minimum. If Outerwear toggle ON → must include
outerwear; if Shoes toggle ON → must include shoes. Pre-check `canAssemble`:
- tops pool empty OR bottoms pool empty → fail "Cannot build outfit — check item availability".
- outerwear ON but outerwear pool empty → fail "No available outerwear for this occasion".
- shoes ON but shoes pool empty → fail "No available shoes for this occasion".
- With a pinned item, that layer is auto-satisfied.

## P1b — Formality Matching (hard rule)
```
diff = max(formality) - min(formality) over outfit items
diff <= 1 → ACCEPT (Matched)
diff  > 1 → find most-mismatched item: max |formality - avg|,
            tiebreak = HIGHER formality; pinned item NEVER targeted.
            Try candidates in that slot's pool (FRS desc); the first swap that
            yields diff<=1 → ACCEPT (Matched). If none, target next-mismatched.
            Max 20 total candidate attempts. If exhausted → accept best-available
            (min diff seen) with soft warning (Loose).
```
NOTE: stated tiebreaker rule (higher formality) is authoritative; one worked
example targets the lower-formality item on a tie — treated as illustrative.
Self-pairing guard: a candidate already used in another slot is skipped.

**Worked (unambiguous):** Dress shirt(4)+Jeans(2)+Oxford(4): diff=2 REJECT →
most-mismatched Jeans(2) (dist 1.33) → swap Bottom-B(3) → 4,3,4 diff=1 ACCEPT.

## P1c — Colour Compatibility Score
Pairs evaluated (each only if both present):
Top↔Bottom (always), Top↔Outerwear, Bottom↔Shoes, Outerwear↔Shoes.
`ColorCompatibilityScore = average(colourScore(primary_a, primary_b))` over
evaluated pairs. Uses color_tags[0]. Bands → see M1.
**Worked:** White Top + Navy Bottom + Brown Shoes (no outerwear):
Top↔Bottom White+Navy=1.00; Bottom↔Shoes Navy+Brown=0.80 → avg 0.90.

## OutfitScore
```
AverageItemFRS = average(FRS of all outfit items)
OutfitScore = 0.70·AverageItemFRS + 0.30·ColorCompatibilityScore
Display = min(round(OutfitScore × 100), 100)   (internal score uncapped, ~1.105 max)
```
Ranking uses internal (uncapped) OutfitScore.
