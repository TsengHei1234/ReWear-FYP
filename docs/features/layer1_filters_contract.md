# Contract — Layer 1 Filters

**Source:** RE "Layer 1 — Filter Rules" (F2/F3/F4 + Empty Pool Guard) + **F5
worn-today (authored, DECISIONS G2)**.
**Location:** `lib/engine/filters/layer1_filters.dart` + `test/engine/layer1_filters_test.dart`.
**Purity:** pure Dart. F1 Season is DROPPED from MVP (confirmed with user).

Filters run before any scoring. DELETED always excluded. Filtered-out items still
appear on Donation/Insights — Layer 1 only builds the *recommendation* pool.

## F2 — Occasion
- occasion == null ("All") → keep all.
- else keep iff `item.occasionTags` contains the selected occasion.

## F3 — Condition Gate
- condition == 1 → REMOVE (flagged for disposal review).
- condition >= 2 → KEEP (condition 2 monitored by D5 later).

## F4 — Availability Gate
- status == IN_WARDROBE → KEEP.
- LAUNDRY | LENT | STORED | DONATED | DELETED → REMOVE.

## F5 — Worn-Today Gate (authored, DECISIONS G2; only when `now` supplied)
- `passesWornToday(item, now)`: REMOVE iff `!lastWornUnknown && lastWornDate` is
  the same calendar day as `now`. Unknown / never-worn → KEEP.
- An item logged worn today is not re-recommended for the rest of the day; the
  gate auto-expires at midnight (no stored flag — derived from `last_worn_date`).
- Applied ONLY when `applyLayer1Filters(..., now:)` is passed `now`. Recommendation
  paths pass it (`rankDailyRotation` → `now`; `GeneratorSession` → `cfg.now`); pure
  filter callers omit it and get F2–F4 only (back-compat for engine tests).

## Empty Pool Guard (after all filters)
Final pool = items passing F2 ∧ F3 ∧ F4 ∧ F5. If empty, report the FIRST step (in
order F2 → F3 → F4 → F5) at which the pool became empty:
1. empty after F2 → "No items match this occasion. Try a different occasion or add more items."
2. empty after F3 → "All your items are too worn out to recommend. Update item condition or add new items."
3. empty after F4 → "All your items are currently unavailable. Update item status to get suggestions."
4. empty after F5 → "You've already worn everything suitable today. Check back tomorrow."

If the pool is non-empty → no message.

## Edge
- Empty input list behaves as "empty after F2" (UI normally pre-checks empty wardrobe).
