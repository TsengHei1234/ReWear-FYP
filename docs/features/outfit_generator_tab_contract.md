# Contract — Outfit Generator Tab (UI, Phase 6 Step 3)

**Sources:** FE §23 (UI authority), §6.17/§6.18/§38, RE "Outfit Generator — Full
Behaviour" + the built `engine/outfit/generator_session.dart` & `outfit_explanation.dart`.
**Session lifecycle:** see **DECISIONS.md G1**, as superseded by Phase 10 — filter
changes are guarded by `hasGenerated` for all sessions (pinned does NOT protect the
session). **Location:** `lib/features/outfit/` (replaces `_GeneratorPlaceholder`).

## State / provider
Driven by `outfitGeneratorProvider` (Step 1, reworked per G1). The tab is a thin
`ConsumerWidget` reading `OutfitGeneratorState` and calling notifier methods. No new provider.

## New PURE logic (TDD)
`buildExplanationForOutfit(...)` in `engine/outfit/outfit_explanation.dart`: re-runs
`scoreItem` per outfit item → `OutfitItemScores` → calls existing `buildOutfitExplanation`.
Inputs: outfit, full wardrobe (for categoryActiveCount), mode, preferred/disliked colours,
FormalityResult, colourScore, displayScore, occasion, pinnedItem, now. Reused by Step 4.

## UI (FE §23), top→bottom
- **OCCASION** label + chips: Casual · Work · Active · Relax (NO "All"), single-select,
  default **Casual**. When pinned, chips limited to the pin's `occasion_tags`; if the
  current occasion isn't supported by a new pin, snap to the pin's first supported one.
- **LAYERS** label + chips: Top · Bottom **locked** (always-on, lock icon, non-tappable)
  + Outerwear · Shoes **toggles** → `requireOuterwear`/`requireShoes`. When pinned, the
  pin's own layer is locked-on too (cannot toggle off until pin cleared).
- **Pinned strip** (only if `pinnedItem != null`): 36px thumb + PINNED badge + name + ✕
  (✕ → `_clearPin()`: if `hasGenerated == true` it confirms first, then clears the pin +
  resets the session; if nothing is generated it clears directly).
- **Generate/Start Over**: before first gen → primary "Generate Outfit" (`generate()`).
  After gen → outlined "Start Over" (`_startOver()` → `clearGenerated()`) + "Generated
  Outfits" divider + cards.
- **3 result cards**: top row = score pill (FE §6.18 dark-green) + occasion chip +
  "?" circle (→ Quick Why sheet, lists `whyReasons`); thumbnails row (2→80 / 3→66 / 4→58px);
  one-line reason tag (occasion + first why reason). Whole card → Outfit Detail (Step 4 stub).

## Behaviours (per DECISIONS.md G1, as superseded by Phase 10)
- Generate is synchronous (pure) → render instantly; spinner only while wardrobe/profile load.
- **Failure** (`state.failureMessage`: empty pool / P1a / pinned-formality) → inline message
  card in place of cards (not a snackbar).
- **Filter change orchestration (UI layer) — `_changeFilter()` keys on `hasGenerated`
  for ALL sessions, pinned or not (Phase 10; no pinned staging):**
  - `hasGenerated == true` (pinned or not) → confirm sheet: title "Change filters?",
    body "This will clear your current generated outfits and skipped items for this
    session.", confirm label "Change Filters". Confirm = apply setX + `clearGenerated()`;
    Cancel = keep current cards + previous filter (setX deferred, so it is not called).
  - `hasGenerated == false` → apply setX directly.
- Provider auto-clears + clears pin on any real wardrobe mutation (G1); Generator Skip
  preserves (Step 1 `_preserveSessionOnce`).

## Deferred to Step 4 (snackbar stub now)
- Card-tap → Outfit Detail screen; Skip Item / Skip Outfit (live in Outfit Detail; provider
  `skip` stays unused until then). Outfit Log Wear (ends session) also lands with Step 4.
