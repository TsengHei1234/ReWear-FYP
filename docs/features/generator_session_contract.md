# Contract — Generator Session (pure core)

**Source:** RE "Outfit Generator — Full Behaviour" (Steps 1–10, T/B uniqueness,
skip cascade, session lifecycle). Pure Dart; UI orchestration (loading states,
snackbars, Supabase sync, re-display-without-engine) stays in Phase 6.
**Location:** `lib/engine/outfit/generator_session.dart` + test.

## Session state
`excludedItems` (append-only ids), `excludedCombinations` (canonical id-tuple
keys currently displayed), `shownTops`, `shownBottoms`, `initialGenerationDone`,
`useTbUniqueness`, `currentOutfits`. `clear()` resets all.

## Layer→category: TOP→top, BOTTOM→bottom, OUTERWEAR→outerwear, SHOES→footwear.

## generate() (Steps 1–10)
1. Layer 1 (F2/F3/F4) on wardrobe. If pinned: F3/F4 safety on pinned → auto-unpin
   if condition==1 or status≠IN_WARDROBE, then proceed without pin.
2. FRS per passing item (categoryActiveCount per category from full wardrobe).
3. Pools per required layer: category match, ∉ excludedItems, FRS desc, take ≤8.
   Pinned layer pool = [pinned]. Pinned: drop candidates with |Δformality|>1 (Step 0e).
4. Combinations (nested loops); skip if any item ∈ excludedItems, combo ∈
   excludedCombinations, or self-pairing (id repeats across slots).
5. P1a canAssemble; if fails → GenerationResult.failure(message).
6. P1b per combo (pinned slot never swapped). 7. colour. 8. OutfitScore.
9. Sort by OutfitScore desc. If !initialGenerationDone & useTbUniqueness
   (tops≥3 & bottoms≥3): pick combos with unseen top AND unseen bottom, up to 3;
   backfill ignoring uniqueness if <3. Else top 3.
10. Add chosen combos to excludedCombinations; initialGenerationDone=true.

## skip(skippedIds) — cascade + replacement
Add skippedIds to excludedItems. Remove every currentOutfit containing any
excluded item; drop their combos from excludedCombinations. Re-run generation
(initialGenerationDone==true → no uniqueness) to refill up to 3, excluding
current items/combos. If fewer available than empty slots, fill what's possible.

## Notes
- Outerwear/shoes may repeat across cards; only top/bottom uniqueness on initial.
- Empty-pool/P1a failure surfaces the Layer-1 / P1a message.
