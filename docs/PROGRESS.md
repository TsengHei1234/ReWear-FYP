# ReWear — Build Progress / Handoff

**Read this first when resuming in a new chat.** Then read the plan
(`~/.claude/plans/hi-claude-my-guy-snoopy-hummingbird.md`), `docs/DECISIONS.md`,
and the one `docs/features/<feature>_contract.md` for what you're building.
Do NOT re-read the big MD reference files whole — use `docs/INDEX.md` to find
the exact sections you need.

**Stack:** Flutter 3.41 · Dart 3.11 · Supabase · Riverpod v3 · go_router · Plus Jakarta Sans
**Run:** `flutter run --dart-define-from-file=config/supabase.local.json`
(Android emulator daily; physical phone for checks).

**Supabase project:** "Tseng Hei Rewear FYP" · ref `kuopofvucpnmudtifkho` ·
URL `https://kuopofvucpnmudtifkho.supabase.co`. Keys live in the gitignored
`config/supabase.local.json` (publishable key — public-safe). Connected to
Claude Code via the `supabase` MCP server (OAuth, same account).

---

## Phase status

- [x] **Phase 0 — Foundation + index** ✅
  - Flutter project scaffolded, deps installed, `flutter analyze` clean, smoke test passes.
  - Theme + tokens: `lib/core/theme/` (colors, text_styles, dimens, theme).
  - Constants as code: `lib/core/constants/` (enums, item_type_dictionary, app_constants incl. history mappings + swatch colours).
  - Supabase stub: `lib/core/supabase/` (config via dart-define, lazy init no-op until configured).
  - `lib/main.dart` + `lib/app.dart` (foundation placeholder home).
  - Docs: `INDEX.md`, `DECISIONS.md`, `PROGRESS.md`, `features/_CONTRACT_TEMPLATE.md`.
- [x] **Phase 1 — Database & Supabase** ✅
  - Connected via Supabase MCP server (OAuth). Project `kuopofvucpnmudtifkho`, Postgres 17, Singapore.
  - 5 migrations applied + verified (mirrored in `supabase/migrations/`):
    create_core_tables · enable_rls_policies · auth_signup_profiles_trigger ·
    storage_bucket_and_policies · harden_function_security.
  - All 5 tables: RLS on, per-user policies + child cross-link guards, Data-API reachable.
  - Storage: private `wardrobe-items` bucket + owner-folder policies (incl. UPDATE for upsert).
  - Security advisor clean except the pre-existing Supabase-managed `rls_auto_enable` event trigger (left intentionally).
  - Keys saved in `config/supabase.local.json` (gitignored).
  - NOTE: `Supabase.initialize` is lazy in `main.dart` and reads dart-define — will activate
    in Phase 2 when we run with `--dart-define-from-file=config/supabase.local.json`.
- [x] **Phase 2 — Auth + Onboarding** ✅ (backend verified; on-device UI walkthrough optional)
  - Data: `Profile` model, `AuthRepository`, `ProfileRepository`, `providers/auth_providers.dart`.
  - Routing: `go_router` (`routing/app_router.dart`), wired in `app.dart` via MaterialApp.router.
  - Shared widgets: `app_text_field`, `app_icon_tile`, `progress_dots`.
  - Screens: splash (session check), login, signup, forgot_password (+ `auth_form_helpers.dart`),
    onboarding 1–4 (`onboarding_flow.dart`), colour picker V1 + recommendation_mode_card widgets.
  - Temp `home_placeholder` (with Log Out) until Phase 6.
  - `flutter analyze` clean; ProgressDots widget test passes.
  - ✅ Android debug APK builds & links (added core-library desugaring to
    `android/app/build.gradle.kts` for flutter_local_notifications).
  - ✅ Backend verified headlessly: REST signup → trigger auto-created the `profiles`
    row with correct defaults; test user cleaned up.
  - OPTIONAL: on-device UI walkthrough (sign up → onboarding → home) when an emulator/phone is up.
  - ⚠️ ACTION (user): in Supabase dashboard, **disable "Confirm email"** (Authentication →
    Sign In/Providers → Email). Confirmed it is currently ON, so signup returns no session and
    the code routes to login with "check your email". Turning it off enables signup → onboarding.
- [x] **Phase 3 — Data layer (models, repos, core providers)** ✅
  - Models: `item.dart`, `item_event.dart`, `outfit_log.dart`, `outfit_log_item.dart`
    (full `fromJson`/`toInsertJson`/`toUpdateJson`/`copyWith`; mirror DB §4–7 schema).
  - Repositories: `item_repository.dart` (CRUD + photo upload to `{user_id}/{item_id}/main.jpg`
    via `StorageRepository`), `item_event_repository.dart`, `outfit_log_repository.dart`,
    `storage_repository.dart`.
  - Core providers: `wardrobe_providers.dart` (`WardrobeNotifier` + all mutation stubs:
    addItem/editItem/deleteItem/updateItemStatus/confirmDonation/setKeptUntil —
    each calls `ref.invalidateSelf()`; cross-provider invalidation (Insights/Donation/
    OutfitGenerator) wired in Phase 4 when those providers exist).
    `profile_providers.dart` (`ProfileNotifier`).
    `currentUserIdProvider` (watches `authStateProvider`).
  - `flutter analyze` clean; debug APK builds.
- [x] **Phase 4 — Wardrobe CRUD + shared widgets + badges/condition** ✅
  **Step 1 ✅** — Engines + shared widgets + nav shell:
  - `lib/engine/badges/badge_engine.dart` (computeAllBadges, all 8 priorities, D2 stubbed)
  - `lib/engine/condition/condition_engine.dart` (conditionThreshold, checkAutoConditionDrop)
  - Shared widgets: `badge_chip.dart`, `primary_button.dart`, `outlined_button_widget.dart`,
    `app_filter_chip.dart`, `wardrobe_item_card.dart` (rebuilt to spec: photo+info layout)
  - `features/shell/main_shell.dart` — 5-tab bottom nav with pill active state
  - `features/shell/placeholder_page.dart` — stub for tabs not yet built
  - `routing/app_router.dart` — replaced with `StatefulShellRoute` (5 branches)
  - `core/utils/date_x.dart` — lastWornLabel, daysSince helpers
  - `providers/wardrobe_providers.dart` — added `itemImageUrlProvider` (FutureProvider.family)
  **Step 2 ✅** — Wardrobe list/grid page (`features/wardrobe/wardrobe_page.dart`):
  - 2-column grid, search bar, category chips, count row, Filter bottom sheet
  - Filter: occasion (multi), status (multi), sort-by (4 options), favourites toggle
  - "Filter" label + tune icon on count row; both turn green when filter active
  - Empty state (wardrobe empty vs no filter matches)
  **Dark mode centralised ✅** — `lib/core/theme/app_color_scheme.dart`:
  - `AppColorsTheme` ThemeExtension with light + dark token variants
  - `context.colors.X` accessor (`AppColorsX` extension on BuildContext)
  - Swept ALL 15 files: wardrobe page, shell, all auth screens, onboarding, core widgets
  - `app_theme.dart` registers the extension; search bar border rectangle fixed (all
    InputBorder.none states set explicitly)
  - Post-frame unfocus after filter sheet dismiss (kills keyboard auto-focus bug)
  **Step 3 ✅** — Add Item + Edit Item + image_cropper (`features/wardrobe/add_edit_item_page.dart`):
  - `ItemFormPage` (single ConsumerStatefulWidget, `existingItem` param switches Add/Edit mode)
  - `AddItemPage` + `EditItemPage` thin wrappers for clean route builders
  - Full form: photo picker (gallery/camera), name field, category chips (5), type dropdown,
    colour swatches (12, multi-select min 1 max 3), occasion chips (allowedOccasions only,
    auto-set to defaultOccasions on type select), history section (BRAND_NEW/WORN/UNWORN with
    bucket dropdowns), condition stepper (1–5) + AUTO/MANUAL toggle, favourite switch
  - `condition_next_drop` = wearCount + conditionThreshold(type) on save
  - Edit mode: pre-fills all fields, hides history section, recalculates conditionNextDrop
  - Routes added: `/add-item` + `/edit-item` (top-level, no nav bar)
  - FAB in wardrobe_page wired to `/add-item`; unfocuses search before navigating
  - **Keyboard bug fix (definitive):** `FocusNode _searchFocusNode` added to `_WardrobePageState`;
    double post-frame callback in `_openFilterSheet` outlasts Flutter's focus-restoration pass
  - `image_cropper ^12.0.0` added: gallery/camera → 1:1 crop UI → confirms → form
    (NOTE: 6.0.0 failed — used removed `PluginRegistry.Registrar`; 12.x is the working one)
  - `AndroidManifest.xml` updated: `UCropActivity` added for image_cropper Android
  - Colour changed to single-select (primary colour only); section label updated
  **Step 4 ✅** — Item Detail + card redesign + wear history (matches agreed mock):
  - **Wardrobe card redesign** (`wardrobe_item_card.dart`): photo now 1:1 (grid
    childAspectRatio 0.70); primary badge moved ONTO photo bottom-left with "+N"
    suffix (BadgeChip gained `extraCount`); two quick-action buttons bottom-right
    of info area — Log Wear (✓, functional) + Build Outfit (✦, deferred snackbar);
    status label centred on greyed non-active photos
  - **Item Detail** (`item_detail_page.dart`) rebuilt to mock: 1:1 photo with floating
    circle buttons (back/star-toggle/edit/trash); name + Category·Type·Colour;
    read-only occasion chips; all badges; 3 stat tiles (Wears/Last Worn/Skipped);
    Status + Condition pills; **Rule-Based Usage Summary** card (Rotation Priority /
    Wear Balance / Skip Feedback / Donation Review — computed from badge_engine +
    days-since-worn, Donation Review stays "Not needed" until Phase 5 D-rules);
    Consider Donating button (hidden until D-rule flags); **Recent Wear History**
    card (2 events + View All); sticky Log Wear / Build Outfit buttons
  - **Full Wear History** (`full_wear_history_page.dart`, FE §21) for View All;
    route `/wear-history`
  - **Log Wear functional** — `WardrobeNotifier.logWorn()`: writes WORN item_event,
    bumps wear_count + last_worn_date, clears unknown flags, applies AUTO condition
    drop via condition_engine. Phase 6 reuses this for rotation/generator logging.
  - `itemEventsProvider(itemId)` FutureProvider.family (re-fetches after wardrobe invalidate)
  - Star toggle uses `editItem(copyWith(isFavorite:))`; routes: `/item-detail`, `/wear-history`
  - **Single-colour** Add/Edit (primary colour only); app name "ReWear"; keyboard
    lift fixed (`MainShell` resizeToAvoidBottomInset:false)
  **Step 4 polish ✅** (mock-match round 2):
  - Card quick-action buttons moved BELOW category·type, right-aligned (grid ratio 0.64)
  - Item Detail: condition kept as pill (not circles); Status pill now has a status
    dot + Condition pill has check-circle icon (matches mock)
  - Rule-Based Usage card: fixed extra bottom gap (last row no bottom padding)
  - **Consider Donating always shown** (any non-donated item) — "Consider Donating"
    when D-flagged else "Donate This Item"
  - Recent Wear History: "View All →" moved to card header (trailing); rows now use
    shared `HistoryRow`
  - **`core/widgets/history_row.dart`** — reusable leading-icon + title + subtitle +
    trailing row. Used by Recent + Full Wear History; reuse for kept items / donation
    history / Insights View-All later. Worn=green check, Skipped=grey skip icon.
- [x] **Phase 5 — Rule engine (pure Dart, TDD)** ✅
  - **All pure Dart, no Flutter/Supabase imports; 145 engine tests pass, `flutter analyze` clean.**
  - `engine/scoring/` — tds, sps, wfss, nibs, ps, frs (S1–S6). `scoreItem()` wires all
    sub-scores; `rankByFrs()` applies the equal-FRS tiebreaker. Validated vs rotation-window table.
  - `core/constants/colour_compatibility.dart` — **M1 authored + user-reviewed.**
    `colourScore(a,b)` over the 12 swatches; White+Navy=1.00, Navy+Brown=0.80→avg 0.90.
    Same-colour diagonal tiered per user: achromatic 0.80 / navy·brown 0.70 / chromatic 0.65.
    (0.70 is an authored off-band value — see DECISIONS.md M1.)
  - `engine/filters/layer1_filters.dart` — F2/F3/F4 + Empty Pool Guard (F2→F3→F4 message
    priority). **F1 Season confirmed dropped from MVP.**
  - `engine/outfit/` — `outfit.dart` (Outfit model + slots), `outfit_assembler.dart`
    (P1a canAssemble, P1b formality swap, P1c colour, OutfitScore + display cap),
    `outfit_explanation.dart` (rule-breakdown badges, why-reasons, score sentence),
    `generator_session.dart` (Steps 1–10, T/B uniqueness, pinned lock + Step 0 safety/
    pre-filter, skip cascade + replacement). UI orchestration deferred to Phase 6.
  - `engine/donation/donation_rules.dart` — D1–D5 + tiers + DPS; `isDonationCandidate()`.
    **Wired into `badge_engine._isDonationCandidate` (P2 badge now live).**
  - `engine/insights/health_score.dart` — Health Score + verdict + quick stats +
    attention predicates (neverWorn/longUnused/skippedOften/overused/sleeping).
  - `engine/daily/daily_rotation_display.dart` — `rankDailyRotation` (excl OTHERS) +
    display labels (score, priority, last-worn, wear-status, wear-count).
  - Test helper: `test/engine/support/item_factory.dart` (`makeItem(...)`).
  - Lazy per-engine contracts in `docs/features/` (scoring, layer1_filters, outfit_assembler,
    outfit_explanation, generator_session, donation_rules, health_score, daily_rotation).
  - **Post-review hardening (external review findings, all fixed + tested):**
    1. Generator now enforces P1c colour reject/fallback (split normal≥0.40 / clash<0.40;
       drop clashes when ≥3 compatible exist, else best-clash fallback) — applies on
       initial + replacement paths.
    2. Pinned formality pre-filter that empties a required layer now returns the specific
       "Cannot find items matching [name]'s formality" message.
    3. `skip()` re-sorts all displayed cards by OutfitScore desc after replacement.
    4. `computeAllBadges`/`primaryBadge` take optional `{DateTime? now}` (deterministic
       tests; defaults to DateTime.now()).
    5. P4 "Skipped often" badge guard `>=3 interactions` removed → strict RE
       `skip_ratio > 0.50` (guarded raw ratio). Now consistent with insights `isSkippedOften`.
- [x] **Phase 6 — Recommendation features (Home, Daily Rotation, Generator, Outfit Detail, Outfit History)** ✅
  **Step 1 ✅** — Shared plumbing (TDD, no UI yet):
  - `WardrobeNotifier.logSkipped(item, {occasion, source=DAILY_ROTATION})` — RE
    skip semantics: writes a SKIPPED `item_events` row + `skip_count += 1` ONLY.
    Does NOT touch last_worn_date, the unknown flags, or condition (unlike logWorn).
  - `WardrobeNotifier.logSkippedItems(items, {source=OUTFIT_GENERATOR})` — batch
    skip (skip-item=1, skip-outfit=N); writes all events + bumps, invalidates ONCE
    so the generator session sees a single wardrobe refresh. Shared private `_writeSkip`.
  - `providers/outfit_generator_provider.dart` — `outfitGeneratorProvider`
    (`NotifierProvider`, NOT autoDispose so the session survives tab switches).
    `OutfitGeneratorState` (occasion/requireOuterwear/requireShoes/pinnedItem/
    outfits/isGenerating/failureMessage/hasGenerated, sentinel copyWith for the
    nullable fields). Drives `GeneratorSession.generate/skip/regenerate`; config
    setters (setOccasion/setRequireOuterwear/setRequireShoes/setPinnedItem) each
    reset the session (RE "Session cleared" on filter/pin change).
  - **Lifecycle (RE Data Sync Strategy):** `ref.listen(wardrobeProvider)` (listen,
    not watch → notifier+session persist). Any settled wardrobe refresh clears the
    session, EXCEPT the generator's own skip (`_preserveSessionOnce` one-shot guard).
    GOTCHA captured: `invalidateSelf` emits TWO AsyncData events (refreshing
    `isLoading==true`, then settled) — only act on the settled one or the guard is
    consumed early. Mode + preferred/disliked colours pulled from `profileProvider`.
  - Tests: `test/providers/wardrobe_logging_test.dart` (4) +
    `test/providers/outfit_generator_provider_test.dart` (4). Established the
    mocktail + ProviderContainer harness (mock item/event/profile repos, override
    currentUserIdProvider). **154 tests pass; flutter analyze clean.**
  - NOT yet built: the §16/§22/§23/§24/§25 screens, route wiring, "Build Outfit"
    button hookups, outfit_logs writes. Next: Step 2 (Daily Rotation tab).
  **Step 2 ✅** — Daily Rotation tab (§22) + Outfit shell:
  - `features/outfit/outfit_page.dart` — shell "Outfit" destination: top bar
    ("Outfit" + history clock [snackbar-stub→Step 5] + profile avatar initials),
    segmented control, body switches Daily Rotation ⇄ Generator. Holds `_tabIndex`;
    `_buildOutfit(item)` = `outfitGeneratorProvider.setPinnedItem` + switch to tab 1.
  - `features/outfit/widgets/outfit_segmented_control.dart` — FE §6.17 pill switch
    (own file, reused by both tabs; `c.surface2` track, `c.surface` active).
  - `features/outfit/daily_rotation_tab.dart` — occasion + layer chip rows
    (single-select, reuse `FilterChipRow`), "Top N Rotation Picks", top-5 list.
    Watches wardrobe+profile → `rankDailyRotation`. Layer chip filters by category
    (Shoes→footwear). Wear=`logWorn(source:DAILY_ROTATION)`+snackbar; Skip=confirm
    sheet→`logSkipped`+session-excluded set (FE §22 "removed from session list");
    Build Outfit=pin+switch tab. Empty states (no items vs no filter match).
  - `features/outfit/widgets/daily_rotation_card.dart` — LOCKED mock layout
    (ConsumerWidget, resolves photo via `itemImageUrlProvider`). All labels from
    engine `daily_rotation_display.dart`; score pill = `dailyRotationDisplayScore`.
  - `core/widgets/confirm_sheet.dart` — universal `showConfirmSheet(...)` (FE §38,
    destructive variant) returning Future<bool>. Reuse for donate/delete later.
  - **CONFLICT resolved (logged in contract):** FE §22 priority thresholds
    (TDS≥0.8/0.5) differ from engine `priorityLabel` (NIBS>0 New · ≥0.70 High ·
    ≥0.35 Medium · else Low). Used the **engine** (RE=logic authority) for the
    label; applied FE §22 *colours* per label (brand-fixed `AppColors.*`, +Low=grey).
  - Router: Outfit branch now → `OutfitPage` (was placeholder). All `context.colors.X`.
  - No new pure logic → no new tests (UI consumes tested engine). **154 tests pass;
    flutter analyze clean.** Contract: `docs/features/daily_rotation_tab_contract.md`.
  **Step 3 ✅** — Outfit Generator tab (§23) + session-rule override:
  - **DECISIONS.md G1 (user-confirmed override of RE session lifecycle):** pinned
    protects the session — changing occasion/layer while pinned is STAGED (outfits
    stay, applies on next Regenerate); pin's own layer locked-on; occasion chips
    limited to pin's tags. No-pin + already generated → "This will clear your
    generated outfits. Continue?" confirm before regenerate. Set/clear pin → reset.
    Generator Skip → preserve; Generator Log Wear + any wardrobe mutation → reset +
    clear pin (no auto-LAUNDRY). Regenerate = fresh gen, keeps pin+filters.
  - **Provider reworked (TDD, 6 tests):** `outfit_generator_provider.dart` — filter
    setters are now DUMB field-updates (no auto-reset; the tab orchestrates);
    `_onWardrobeChanged` resets + clears the pin (except the skip preserve-guard);
    added `clearPin()`; `regenerate()` keeps the pin. Updated the Step-1 tests to G1.
  - **New PURE logic (TDD, 2 tests):** `buildExplanationForOutfit(...)` in
    `engine/outfit/outfit_explanation.dart` — re-runs `scoreItem` per outfit item
    (the ScoredOutfit-has-no-sub-scores gotcha) → `buildOutfitExplanation`. Shared
    by the Generator (reason tag + Quick Why) and Step 4 Outfit Detail.
  - **UI** (`features/outfit/outfit_generator_tab.dart`, replaces the placeholder):
    OCCASION chips (Casual default, no All), LAYERS (Top/Bottom locked + Outerwear/
    Shoes toggles; pin's layer locked), pinned strip (✕ = clearPin), Generate→
    Regenerate, "Generated Outfits" divider, 3 result cards (score pill + occasion
    chip + "?" Quick Why sheet + thumbnails sized by count + reason tag), inline
    failure card. Filter-change orchestration per G1. Card-tap → snackbar stub.
  - **Deferred to Step 4 (stubbed):** card-tap → Outfit Detail; Skip Item/Outfit +
    outfit Log Wear (provider `skip` unused until then). All `context.colors.X`.
  - **158 tests pass; flutter analyze clean.** Contracts: `outfit_generator_tab_contract.md`.
  **Step 3 polish (user UI review):**
  - Result card redesigned to match the agreed mock: top row = light-green
    "Score N" pill (matches Daily Rotation) + "?"; second row = "Occasion ·
    {primary highlight}" + small "+N" pill; then thumbnails. Removed the long
    reason sentence + the inline occasion chip (details live in "?"/Outfit Detail).
  - New `OutfitExplanation.highlights` (TDD) — notable rotation positives only
    (High Rotation / Balanced Wear / Low Skip Rate / New Item; colour+formality
    excluded so cards aren't always "+4"). Primary = first, rest = "+N".
  - **Build Outfit wired** from Wardrobe card + Item Detail → `setPinnedItem` +
    `outfitTabIndexProvider.set(1)` + `context.go('/outfit')` (no more "later
    update" snackbar). New `outfitTabIndexProvider` lets OutfitPage open on the
    Generator sub-tab cross-branch. Pin constraints (occasion limited to pin +
    pin's layer forced-on) moved INTO `setPinnedItem` (provider, TDD).
  - No-pin filter change after generation: confirm → apply filter + `clearGenerated()`
    (button returns to "Generate Outfit"); does NOT auto-generate (user re-taps).
    Cancel keeps cards + filter. New `clearGenerated()` (TDD).
  - **163 tests pass; flutter analyze clean.**
  **Step 3 recommendation-bug fixes (user QA round 2):**
  - **F5 worn-today gate (DECISIONS G2, TDD):** `layer1_filters.dart` gains
    `passesWornToday(item, now)` + `applyLayer1Filters(..., now:)` + new
    `EmptyPoolReason.allWornToday`. Items worn today (`last_worn_date == today`)
    drop from BOTH Daily Rotation + Generator pools for the day. `rankDailyRotation`
    passes `now`; `GeneratorSession` passes `cfg.now`. (F4 already gates IN_WARDROBE
    only — status filtering was already correct.) Existing engine tests use past
    dates → unaffected.
  - **Refresh after Log Wear:** logWorn invalidates wardrobe → Daily Rotation
    re-ranks (worn item drops via F5; `skipLoadingOnReload: true` keeps the list
    stable, no spinner flash) + Generator session resets (G1). Worn item gone
    immediately, no app restart.
  - **Log Wear confirmation:** new `showLogWearSheet(context, name)` in
    `confirm_sheet.dart` ("It won't appear in today's rotation again.") wired into
    Daily Rotation Wear, Wardrobe card Log Wear, and Item Detail Log Wear.
  - **Confirm sheet redesigned:** buttons now side-by-side — Cancel (left, neutral
    outlined, visible border light+dark) + action (right, filled; red for
    destructive Skip, primary otherwise). Applies to Skip, Log Wear, filter-change.
  - **167 tests pass; flutter analyze clean.**
  **Step 4 ✅** — Outfit Detail (§24) + day-based Daily-Rotation skip + card touch-ups:
  - **DECISIONS G3 (skip-scope model):** Daily Rotation skip = day-scoped, DB-backed
    (`providers/daily_rotation_providers.dart` → `dailyRotationSkippedTodayProvider`
    reads today's SKIPPED/DAILY_ROTATION events; survives restart, resets midnight;
    hides from Daily Rotation only). Generator skip = session-scoped only (unchanged).
    Wear = hard-exclude both (G2). Daily Rotation tab unions the day-set with an
    in-memory set for instant removal.
  - **`logOutfitWorn` (TDD):** `WardrobeNotifier` — writes one `outfit_logs` +
    `outfit_log_items` (via `OutfitLogRepository.logOutfit`) + a linked WORN
    `item_events` per item + wear/AUTO-condition updates; invalidates once. Takes
    `pieces: List<({Item item, LayerType layer})>`.
  - **Outfit Detail** (`features/outfit/outfit_detail_page.dart`, route `/outfit-detail`,
    `OutfitDetailArgs{scored, occasion, optionNumber}`): compact header card (Outfit
    Option N + occasion pill + Score pill + N items + summary = pinned override else
    `exp.scoreMessage`), clean item rows (thumb + layer + name + last-worn + skip icon
    + chevron→Item Detail), Why Suggested (`whyReasons`), Rule Breakdown (5 rows,
    friendly labels: Rotation Priority/Skip Feedback/Wear Balance/Formality Match/
    Colour Compatibility, colour-coded badges), sticky Skip Outfit + Log Outfit.
    Skip Item/Outfit confirms (light); Log Outfit confirm. Skips drive
    `outfitGeneratorProvider.skip(...)` then pop; Log Outfit calls `logOutfitWorn`.
  - **Step-3 card touch-ups:** "Outfit Option N" title + center-right chevron; result
    cards now navigate to Outfit Detail (was a stub). Thumbnails made responsive
    (Expanded+AspectRatio) so they fit beside the chevron. Score pill = light-green
    "Score N" (consistent with Daily Rotation).
  - Contract: `docs/features/outfit_detail_contract.md`. **168 tests pass; analyze clean.**
  **Step 4 polish (user QA round):**
  - **Occasion now stages like layers (pinned session):** added
    `OutfitGeneratorState.generatedOccasion` + notifier `_activeConfig`. Cards +
    Outfit Detail display `generatedOccasion` (the occasion the cards were made
    with); chips show the selected/staged occasion. Skip/replacement reuse
    `_activeConfig` so a staged occasion/layer doesn't leak in before Regenerate.
  - **Confirm-before-replace:** pin "✕" confirms only when outfits exist
    (`_clearPin`). "Build Outfit" from Wardrobe/Item Detail/Daily Rotation routes
    through new `features/outfit/build_outfit_action.dart` → confirms ("Start a new
    outfit?") if a session/pin is active before replacing.
  - **Card label ordering fix:** `OutfitExplanation.highlights` reordered to the RE
    "Why this outfit" priority (New Item → High Rotation → Low Skip Rate → Balanced
    Wear) so the card's PRIMARY label is the engine's strongest reason. Verified all
    rule-breakdown/why thresholds match RE §"Outfit Detail Explainability" (1063–1127).
  - **UI:** result card "?" (top-right) + chevron (bottom-right) aligned via Stack;
    Outfit Detail Rule Breakdown last row drops its bottom padding (even spacing).
  - **169 tests pass; flutter analyze clean.**
  **Step 5 ✅** — Outfit History (§25):
  - `providers/outfit_history_providers.dart` — `outfitHistoryProvider`
    (FutureProvider.autoDispose) → `OutfitHistoryEntry{log, imagePaths}` newest-first,
    resolved in 3 batched queries (history → log items → items), grouped per log in
    layer order. Watches `wardrobeProvider` so a freshly-logged outfit shows. TDD (2).
  - New repo reads: `ItemRepository.getItemsByIds` (status-agnostic),
    `OutfitLogRepository.getOutfitItemsForLogs` (batched).
  - `features/outfit/outfit_history_page.dart` (route `/outfit-history`): one white
    card, rows = date · occasion pill · ≤4×40px thumbnails, dividers, display-only
    (not tappable); empty state. Top-bar history clock now navigates here (was stub).
  - Contract: `docs/features/outfit_history_contract.md`. **171 tests pass; analyze clean.**
  **Step 6 ✅** — Home (§16) — Phase 6 COMPLETE:
  - `providers/home_providers.dart` — `homeSnapshotProvider`
    (FutureProvider.autoDispose) → `InsightsQuickStats` via `computeQuickStats` over
    wardrobe + last-30d events (Utilisation = wornThisMonth/total · Active Rotation =
    wornThisMonth · Dormant = total−worn · Donation = candidates). TDD (1).
  - `features/home/home_page.dart` (shell branch 0, replaces placeholder): time-based
    greeting + avatar (Profile snackbar-stub, Phase 8); occasion chips; Today's
    Suggestions carousel (PageView 0.88, top 3 `rankDailyRotation`; card = 210px photo
    + score-pill/badge overlays + Wear Today [confirm+logWorn] + View Item [→ Item
    Detail]); Wardrobe Snapshot card (utilisation bar + Active/Dormant tiles + donation
    review link → Donate tab). Worn-today (G2) keeps the carousel fresh.
  - Post-auth landing now `/home` (was `/wardrobe`): splash, login, onboarding.
  - Contract: `docs/features/home_contract.md`. **172 tests pass; analyze clean.**
- [x] **Hotfix — Storage Egress + edited-photo image fix (post-Phase 6)** ✅
  - **Root cause (egress):** `CachedNetworkImage` had no `cacheKey` anywhere. Supabase
    `createSignedUrl` produces a new token on every call; `itemImageUrlProvider` is
    `autoDispose` so it regenerates on every navigation. Without a stable key,
    `CachedNetworkImage` treated each new URL as a cache miss and re-downloaded the
    full image from Supabase Storage → ~1 GB egress in 3 days of testing.
  - **Fix A — stable `cacheKey` (initial step, all call sites):** added
    `cacheKey: item.imagePath` to all `CachedNetworkImage` widgets — 9 call sites
    across 8 files. The storage path is stable across URL regenerations; the disk
    cache now survives tab switches and navigation. **Later superseded on live item
    widgets by Fix C (versioned key) below.** `outfit_history_page.dart` keeps
    `cacheKey: imagePath` permanently (history thumbnails are immutable records).
  - **Fix B — upload resolution cap:** added `maxWidth: 1600, maxHeight: 1600` to
    `ImageCropper().cropImage(...)` in `add_edit_item_page.dart`
    (`compressQuality: 85` unchanged). New uploads cap at 1600×1600 px (≈ 200–400 KB
    vs the previous ~770 KB). Existing stored images are not affected.
  - **Signed URL TTL cache (keepAlive, unchanged):** `itemImageUrlProvider` keeps a
    successful signed URL alive for 1 hour after its last listener leaves
    (`ref.keepAlive()` + 1-hour `onCancel` timer; cancelled on `onResume`; cleaned up
    on `onDispose`). Reduces repeated `createSignedUrl` API calls on scroll/navigation.
    Not full offline support. **This logic was not touched by Fix C.**
  - **Fix C — Versioned `cacheKey` (edited-photo bug, FINAL fix):** Changed all
    live/current item image widgets from `cacheKey: imagePath` to:
      `imagePath != null ? '${imagePath}_v${updatedAt.millisecondsSinceEpoch}' : null`
    **Why it works:** when a photo is replaced, the Supabase storage path stays the
    same but `updatedAt` changes (the `trg_items_updated_at` DB trigger sets it on
    every UPDATE). New `_v{ms}` suffix → `flutter_cache_manager` cache miss →
    downloads new image exactly once → cached for all later views. Same `updatedAt`
    across URL regenerations → same key → disk cache hit → zero egress. Removed the
    broken `evictFromCache` + `ref.invalidate(itemImageUrlProvider)` block from
    `WardrobeNotifier.editItem` (Codex's earlier attempt, replaced entirely by this
    strategy). Also removed Codex's `ValueKey('${imagePath}-${updatedAt}')` on
    `CachedNetworkImage` widgets (redundant with the versioned key approach).
    Files changed by Fix C (8 files; outfit_history_page.dart intentionally skipped):
    `lib/providers/wardrobe_providers.dart` (editItem simplified),
    `lib/core/widgets/wardrobe_item_card.dart`,
    `lib/features/wardrobe/item_detail_page.dart`,
    `lib/features/home/home_page.dart`,
    `lib/features/outfit/widgets/daily_rotation_card.dart`,
    `lib/features/outfit/outfit_generator_tab.dart` (×2: pinned strip + thumb),
    `lib/features/outfit/outfit_detail_page.dart`,
    `lib/features/wardrobe/add_edit_item_page.dart` (edit-form photo preview).
  - **Future rule → DECISIONS.md I1 (updated):** every new clothing-image widget —
    Phase 7 Donate, Insights, and all later phases — MUST use the versioned cacheKey
    form above. Exception: display-only historical thumbnails (like outfit history)
    may use `cacheKey: imagePath` since the underlying item never changes after
    logging. Rule also recorded as a doc-comment on `itemImageUrlProvider`.
  - **Edited-photo bug: FIXED** by Fix C. After replacing a photo and saving, the
    new image appears immediately in Item Detail and Wardrobe cards — no scroll or
    restart needed.
  - **Remaining open image issue (UI polish only):** general visual flicker during
    fast scrolling, filter switching, and page/tab navigation. Not a Supabase egress
    or photo-refresh issue — defer to Phase 9 polish.
  - **`flutter analyze` clean.** No schema, engine, routing, or unrelated UI changes.
- [x] **Phase 7 — Donate + Insights** ✅
  **Step 1 ✅** — Repository extensions + WardrobeNotifier:
  - `ItemRepository.getDonatedItems(userId)` — fetches DONATED items (Donation History).
  - `ItemRepository.clearKeptUntil(itemId)` — sets `kept_until = NULL` (Undo Keep).
  - `WardrobeNotifier.clearKeptUntil(itemId)` — calls repo + invalidateSelf.
  **Step 2 ✅** — Providers (TDD, 8 new tests → 180 total):
  - `donation_providers.dart`: `DonationCandidateEntry` model, `donationCandidatesProvider`
    (FutureProvider, watches wardrobe.future, evaluates D1–D5, sorts by DPS desc),
    `keptItemsProvider` (FutureProvider, filters future kept_until, soonest first),
    `donationHistoryProvider` (FutureProvider, calls getDonatedItems).
  - `insights_providers.dart`: `InsightViewAllType` enum (5 predicates),
    `InsightsData` model (health + stats + utilisationPct + rotationPct + 5 attention lists),
    `insightsProvider` (FutureProvider, 90d events window, mirrors health_score.dart
    utilisation/rotation computation, builds all attention lists).
  **Step 3 ✅** — Donate UI (§26, §27, §28):
  - `features/donate/donate_page.dart` — top bar (title + red count badge + profile avatar),
    header card, shortcut tiles (Kept Items / Donation History), 5 filter chips (C5 confirmed:
    All / Never Worn / Long Unused / Skipped Often / Poor Condition), candidate cards
    (72×72 versioned-cacheKey photo + D-rule reason + condition label + Keep/Donate buttons),
    Keep Duration bottom sheet (1 Week / 1 Month / 3 Months / 6 Months / Indefinitely=2099),
    Donate confirm sheet (isDestructive). All `context.colors.X`.
  - `features/donate/kept_items_page.dart` — rows with versioned-cacheKey photo, "Returns in N
    days" / "Kept indefinitely" label, Undo Keep outlined button (clears kept_until).
  - `features/donate/donation_history_page.dart` — category filter chips (All/Tops/Bottoms/
    Outerwear/Shoes), rows with stable cacheKey (historical thumbnails, per I1 exception),
    donated-on date, chevron → Item Detail.
  **Step 4 ✅** — Insights UI (§29, §30, §41):
  - `features/insights/insights_page.dart` — top bar (title + profile avatar), Health Score
    card (130×130 ring via `_RingPainter` CustomPainter + score/100 + verdict + partial message
    + two sub-score tiles), Quick Stats 2×2 grid (Total/Worn/NeverWorn/Donate→Donate tab),
    Utilisation card (progress bar via `AppColors.utilisationFill` + sleeping items "View All →"),
    Items That Need Attention card (scrollable TabBar with gradient fade + 4 tabs: Never Worn /
    Long Unused / Skipped Often / Overused, 3 rows per tab with badge chips + "View All N →").
  - `features/insights/view_all_page.dart` — reusable for all 5 predicates, title shows
    "Section · N" count, category filter chips, full list with sub-label metrics + metric badge
    (not section-name badge per FE §30 note), chevron → Item Detail.
  **Step 5 ✅** — Routes:
  - `Routes.keptItems = '/kept-items'`, `Routes.donationHistory = '/donation-history'`,
    `Routes.viewAll = '/view-all'` (extra = InsightViewAllType).
  - Branch 3 → DonatePage, Branch 4 → InsightsPage (both were PlaceholderPage).
  - 3 new top-level GoRoutes for sub-pages.
  - `flutter analyze` clean; 180 tests pass (8 new: 5 donation + 3 insights providers).
- [x] **Phase 8 — Profile/Settings + notifications + laundry** ✅ (Steps 1–5 complete)
  **Step 1 ✅** — Settings hub + profile avatar:
  - `features/profile/settings_page.dart` — Settings & Profile hub with nav tiles (My Profile /
    Style Preferences / App Theme / Notification Settings / Data & Privacy / Help & About) + log-out
    button. Profile avatar initials chip in Home/Outfit/Donate/Insights top-bars now routes here.
  - `core/widgets/profile_avatar.dart` — reusable `ProfileAvatar` widget (initials circle, taps
    to `/settings`). Used across all 4 top-bars.
  - `lib/providers/theme_mode_provider.dart` — `themeModeProvider` (AsyncNotifierProvider,
    SharedPreferences-backed). 8 TDD tests.
  **Step 2 ✅** — Sub-screens (all manually tested):
  - `features/profile/my_profile_page.dart` — editable Display Name (TextField, dirty-check,
    `FocusScope.unfocus()` before save, snackbar on success), read-only Email + lock icon, 72px
    avatar with initials. ConsumerStatefulWidget.
  - `features/profile/style_prefs_edit_page.dart` — Preferred / Disliked colour pickers (reuses
    onboarding `ColourPreferencePicker`), mutual exclusion, max-selection guard, canSave dirty-check.
  - `features/profile/data_privacy_page.dart` — Your Data info, Sign Out (GestureDetector,
    confirm sheet, signOut + go to login), Account Deletion info + danger notice.
  - `features/profile/help_about_page.dart` — static app info (Version 1.0.0, Flutter 3.41,
    Supabase). Pure StatelessWidget.
  **Step 3 ✅** — App Theme screen + theme persistence:
  - `features/profile/app_theme_screen.dart` — Light/Dark/System selector (`_ThemeTile`,
    `GestureDetector`, selected = checkmark in `c.primary`). Reads `themeModeProvider`.
  - `lib/app.dart` — `themeMode: ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system`
    (replaces hardcoded system). Dark/light switches immediately on selection.
  - `settings_page.dart` — App Theme nav tile subtitle dynamically reflects current mode
    ('Light' / 'Dark' / 'System default') via `_themeLabel(themeMode)`.
  - **Tap-effect fix:** All 4 `InkWell`s introduced in new Settings files replaced with
    `GestureDetector(behavior: HitTestBehavior.opaque)` to match the rest of the app (no
    ripple leaking past rounded card edges via the Scaffold `Material` ancestor).
  **Step 4 ✅** — Laundry auto-return (TDD, manually tested):
  - `lib/services/laundry_return_service.dart` — `LaundryReturnService.isDue(started, cycleDays, now)`
    (pure, calendar-day diff, `>= cycleDays`) + `run(userId, laundryCycleDays, now)` (fetches
    LAUNDRY items, calls `returnFromLaundry` for due ones, returns count).
  - `lib/data/repositories/item_repository.dart` — `returnFromLaundry(itemId)`: atomically sets
    `status = IN_WARDROBE` and `laundry_started_at = null` in one DB call (separate from
    `updateStatus` which cannot null-clear the field).
  - `WardrobeNotifier.build()` — awaits `profileProvider.future` for `laundryCycleDays`, runs
    `LaundryReturnService.run()` before `getWardrobeItems`. Auto-return fires on every wardrobe
    load (app open, tab switch, pull-to-refresh).
  - **Test fixes:** 5 provider test files updated to add `profileProvider.overrideWith(_StubProfileNotifier.new)`
    and `getLaundryItems` stubs after the new `WardrobeNotifier.build()` dependency was introduced.
    `home_snapshot_test.dart` additionally adds `await c.read(wardrobeProvider.future)` before
    reading the snapshot (extra async steps made the wardrobe settle later).
  - 15 service tests + 210 total tests pass; `flutter analyze` clean.
  **Step 5 ✅** — Local notifications N1–N6 (TDD, 34 new tests → 244 total):
  - `lib/services/notification_eligibility.dart` — pure logic, 28 tests. `NotificationToggles`
    (6 booleans, defaults N1/N2/N3/N5=ON, N4/N6=OFF), `NotificationResult`, `NotificationEligibility.evaluate()`.
    Rules: N1 fires `daysSinceLastLog==1` (suppressed by N2), N2 fires `daysSinceLastLog>=3`,
    N3 `longUnwornCount>0` + 7-day throttle, N4 `donationCandidates>0` + 7-day throttle,
    N6 `conditionDropped && isAutoMode`.
  - `lib/providers/notification_settings_provider.dart` — `NotificationSettingsNotifier`
    (AsyncNotifierProvider, SharedPreferences-backed, setN1–setN6), 6 tests.
  - `lib/services/notification_service.dart` — singleton `NotificationService.instance`
    wrapping `flutter_local_notifications ^21.0.0`. `initialize()` sets up Android channel +
    permission + `tz_data.initializeTimeZones()`. `showN1/N2/N3/N4/N6`, `scheduleN5Weekly()`
    (one-shot to next Sunday 20:00 local via `zonedSchedule`), `recordN3/N4Fired()` + timestamps.
    `isInitialized` guard silently skips all calls in test environments.
  - `lib/features/profile/notification_settings_page.dart` — full 6-toggle UI replacing stub.
    `_SectionHeader` + `_ToggleTile` (GestureDetector + Switch, context.colors.X). Sections:
    Logging Reminders (N1 Daily Reminder, N2 Inactive Warning), Wardrobe Insights (N3–N5),
    Item Updates (N6).
  - `WardrobeNotifier.build()` — `_checkNotificationsOnOpen()` fires once per notifier lifetime
    (`_sessionChecked` flag). Computes `daysSinceLastLog` from item `lastWornDate` fields (no
    extra API call), `longUnwornCount` via `isLongUnused`, `donationCandidates`, then evaluates
    eligibility and fires N1–N4. Reschedules N5 weekly summary with fresh stats.
  - `WardrobeNotifier.logWorn()` — N6 inline: fires after condition drop if toggle enabled + AUTO.
  - `lib/main.dart` — calls `NotificationService.instance.initialize(onTap: ...)` before `runApp`;
    tap routes to Insights (`appRouter.go(Routes.shellInsights)`).
  - `pubspec.yaml` — added `timezone: ^0.11.0` (required by flutter_local_notifications v21 for
    `zonedSchedule` with `TZDateTime`).
  - `AndroidManifest.xml` — added `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `WAKE_LOCK`,
    `RECEIVE_BOOT_COMPLETED` permissions.
  - **244 tests pass; `flutter analyze` clean.**
  **Step 5 post-session refinements (2026-06-15) — all manually tested and confirmed:**
  - **B1:** `_checkNotificationsOnOpen` cancels pending N5 when toggle is OFF (`else { await ns.cancelN5(); }`)
  - **B2:** N6 tap → Item Detail via new `/item-detail-id/:id` GoRoute + `_ItemDetailByIdPage`
    adapter widget (watches `wardrobeProvider`, looks up item by UUID, renders `ItemDetailPage`).
    N6 payload changed to `'item:<uuid>'`.
  - **B3:** N6 check wired in `logOutfitWorn` item loop — same pattern as `logWorn`.
  - **Tap routing locked (DECISIONS N5):** N1/N2 → Wardrobe (payload `'wardrobe'`),
    N4 → Donate (payload `'donate'`), N3/N5 → Insights (null payload),
    N6 → Item Detail (payload `'item:<uuid>'`). Routed in `main.dart` onTap by prefix.
  - **N1 body copy:** "Did you wear something yesterday? Log it to keep your wardrobe history updated."
  - **N6 body copy:** "[item] is now in [label] condition. Tap to review."
  - **Onboarding page 4:** added hint below feature card — "You can customise which alerts you
    receive anytime in Settings → Notifications." (consistent with pages 2–3 pattern).
  - **Background notifications:** documented as known limitation / future enhancement in DECISIONS N4.
    N1–N4 fire on app-open only; WorkManager needed for fixed-time background firing — deferred.
  - Stale `// Real OS permission request is wired in Phase 8.` comment removed from onboarding.
  - **244 tests pass; `flutter analyze` clean. Phase 8 fully complete.**
- [x] **Phase 9 — Polish + real-device UX fixes** ✅ (2026-06-19)
  **Cold start fixes (Home + Wardrobe):**
  - Home: `wardrobeProvider` watched as `wardrobeAsync`; when `(isLoading || hasError) && items.isEmpty`
    the entire content area (chips, suggestions, snapshot) is replaced with a single centered
    `CircularProgressIndicator`. Header/greeting always visible. No misleading 0-data shown.
  - Wardrobe: `loading:` and `error:` callbacks now include `MainPageHeader` so the header is
    always present. Spinner / error text in `Expanded` below.
  **Add 11 — Kept Items tap navigation:**
  - `_KeptItemRow` wrapped in `GestureDetector(behavior: HitTestBehavior.opaque)` → pushes to
    Item Detail. Chevron at far right (after Undo Keep button, `SizedBox(width: 4)` gap), matching
    `_AttentionRow` pattern from Insights. Added `go_router` + `app_router` imports.
  **Add 12 — HitTestBehavior.opaque on tappable rows:**
  - `_DonationHistoryRow` and `_AttentionRow` (insights_page.dart): `behavior: HitTestBehavior.opaque`
    added to existing `GestureDetector`. Transparent padding areas now register taps.
  **Add 13 — Donate badge → inline text format:**
  - Removed `titleBadge` (red circle) from `MainPageHeader` in DonatePage entirely.
  - `_HeaderCard`: ` ·` appended to "Donation Candidates" title string (normal text color);
    count shown as separate `Text` with `AppColors.danger` ("N item/items"). See P9-B.
  **Add 14 — My Profile keyboard reappear after Save:**
  - `_save()` adds `WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) FocusScope.of(context).unfocus(); })`
    after `runMutation`. Post-frame callback fires AFTER Flutter's focus-restoration from the
    dialog pop, correctly keeping keyboard down. See P9-D.
  **Add 10 — Full offline overlay: DEFERRED to Phase 11.** See P9-E in DECISIONS.md.
  - **244 tests pass; `flutter analyze` clean.**

- [ ] **Phase 10 — Polish Outfit Generator**
- [ ] **Phase 11 — Supabase Realtime + offline overlay**

## How to resume (next action)

**NEXT: Phase 10 — Polish Outfit Generator.** Phase 9 complete. **244 tests pass, `flutter analyze` clean.**

Phase 9 manual testing confirmed (2026-06-19):
- ✅ Home cold start: spinner shown (not "Add items") while wardrobe loads
- ✅ Wardrobe cold start: header always visible during loading/error
- ✅ Kept Items: tap row → Item Detail; chevron at far right after Undo Keep button
- ✅ Donation History + Insights attention rows: tap in padding gap → Item Detail
- ✅ Donate page: "Donation Candidates · N items" (dot = normal color, count = red)
- ✅ My Profile: keyboard stays down after Save Changes (incl. Android back-button flow)

Phase 8 notification manual testing — all confirmed working (2026-06-15):
- ✅ N6 Case A: direct Log Wear triggers condition drop → N6 fires → tap → Item Detail
- ✅ N6 Case B: Log Outfit triggers condition drop → N6 fires → tap → Item Detail
- ✅ N5: toggling OFF cancels pending OS notification; toggling ON reschedules on next app open
- ✅ N1/N2 tap → Wardrobe tab; N4 tap → Donate tab; N3/N5 tap → Insights tab
- ⬜ N1/N2/N3: app-open only — fires when daysSinceLastLog matches; N3 throttled 7 days
- ⬜ N5 schedule: set device to Saturday → open app → advance to Sunday 19:59 → fires at 20:00

**Phase 10 goal:** Outfit Generator UI/UX polish. User will bring specific questions, issues,
and a new feature idea at session start. Read this file, DECISIONS.md, and
`docs/features/outfit_generator_tab_contract.md` before doing anything.

**Phase 11 goal (after Phase 10):**
- Supabase Realtime subscription for one key live count (TBD — user to specify)
- Full offline overlay (Add 10, deferred from Phase 9) — discuss with mentor first (see P9-E)
- Data freshness on app resume (S2 Option A or B, see DECISIONS.md)

### Phase 7 — behaviour/UI DELTAS a new chat MUST know
These were authored/locked during Phase 7 (Donate + Insights) and are the source of truth:
- **Badge engine P3 (Overused):** uses shared `hs.itemWearRate(item, now)` from
  `health_score.dart`. Do NOT inline the formula — reuse the helper.
- **Badge engine P5 (Never Worn):** `effectiveAge = initialUsageAgeDays + daysSinceAdded > 14`.
  Pre-owned unworn items get the badge immediately, not after 14 real-world days.
- **Never Worn sub-label & badge pill:** "New" threshold uses `totalDays = initialUsageAgeDays +
  daysSinceAdded ≤ 14`. Sub-label: "Owned N days, never worn" when `initialUsageAgeDays > 0`;
  otherwise "Added today" (0d) / "Added 1 day ago" (1d) / "Added N days ago" (2+d).
- **Sleeping (90+ days) ≠ Long Unused (60+ days):** both predicates exist in `health_score.dart`
  (`isSleeping` ≥ 90d, `isLongUnused` > 60d). They are intentionally separate. The Utilisation
  card shows `sleepingItems.length` + "90+ days" → "View All →" → `InsightViewAllType.sleeping`
  (its own View-All page). The attention tab shows Long Unused (60+). Do NOT merge them.
- **Insights attention lists do NOT filter by keptUntil.** A kept item (keptUntil in future)
  still appears in Long Unused / Sleeping lists. This is a design decision, not a bug.
- **Skipped Often formula is LOCKED:** `skipCount / (wearCount + skipCount) > 0.50`. Uses
  lifetime `wearCount` (includes initial history). Do NOT add a noise-floor or change threshold.
- **Overused threshold is LOCKED at 0.20** (wear_rate ≥ 0.20). Do not change.
  **Phase 11 evidence floor (commit 6755909 "low-evidence Overused detection"):**
  Overused now ALSO requires `wear_count >= 3` — the 0.20 threshold is unchanged,
  the floor is an additional gate so one wear on a brand-new item (rate 1.0) is
  NOT flagged Overused. Shared via `health_score.dart` `kOverusedMinWears = 3` +
  `isOverusedRate(item, now)` (`wear_count >= 3 && itemWearRate >= 0.20`), used by
  badges P3, daily-rotation "Overused" label, `computeWardrobeHealth` rotation
  score, and insights overused list/count. See DECISIONS.md **M7** (Overused evidence floor).
- **Kept Items page** has 6 category filter chips (All/Tops/Bottoms/Outerwear/Shoes/Others)
  via `FilterChipRow`. Filter is pure client-side — no provider/schema change.
- **keptItemsPageProvider** (direct DB call) is the data source for Kept Items page, NOT
  `keptItemsProvider` (which is for tests only). Pattern mirrors DonationHistoryPage.
- **Most Worn / Least Worn** are NOT View-All pages. Only `BadgeType.mostWorn` exists (P8
  badge on grid cards). There are no `InsightViewAllType.mostWorn/leastWorn` values.
- **versioned cacheKey rule (I1) applies to all Phase 7 widgets.** Donate, Kept Items,
  Insights, View-All rows — all use `'${imagePath}_v${updatedAt.millisecondsSinceEpoch}'`.

### Phase 6 — behaviour/engine DELTAS a new chat MUST know (NOT in the v7 MD)
These were authored/changed during Phase 6 and are the source of truth (see
`DECISIONS.md` G1/G2/G3 for the full text + the "Engine deltas vs v7" index):
- **G2 — Worn-today exclusion (F5):** an item logged worn TODAY
  (`!last_worn_unknown && last_worn_date==today`) is hidden from BOTH Daily Rotation
  and Outfit Generator pools for the rest of the day. Implemented as Layer-1 **F5** in
  `layer1_filters.dart`, applied only when `now` is passed (recommendation paths).
- **G3 — Skip scope model:** Daily-Rotation skip = day-scoped + DB-backed
  (`dailyRotationSkippedTodayProvider`, hides from Daily Rotation only). Generator
  skip = session-scoped only (cascade-replace). Wear = hard-exclude both (G2).
- **G1 — Generator session lifecycle (overrides RE):** pinned protects the session
  (occasion/layer changes STAGE until Regenerate; `generatedOccasion` + `_activeConfig`
  hold the as-generated config). No-pin filter change after generation → confirm →
  clear (no auto-generate). Generator Log Wear/Log Outfit + any wardrobe mutation →
  reset + clear pin. Skip preserves. Regenerate keeps pin/filters, clears skip history.
- **Engine additions:** `buildExplanationForOutfit(...)` + `OutfitExplanation.highlights`
  (ordered by RE Why-priority: New Item → High Rotation → Low Skip Rate → Balanced Wear)
  in `outfit_explanation.dart`.

### What's already built (do NOT rebuild) — Phase 7 additions:
- **Phase 7 providers:** `donation_providers.dart` (`donationCandidatesProvider`,
  `keptItemsPageProvider`, `keptItemsProvider`, `donationHistoryProvider`);
  `insights_providers.dart` (`insightsProvider`, `InsightsData`, `InsightViewAllType` enum).
- **Phase 7 screens:** `features/donate/donate_page.dart`, `features/donate/kept_items_page.dart`
  (with 6-chip category filter), `features/donate/donation_history_page.dart`;
  `features/insights/insights_page.dart`, `features/insights/view_all_page.dart` (all 5 predicates).
- **Phase 7 routes:** `Routes.keptItems`, `Routes.donationHistory`, `Routes.viewAll`
  (`extra = InsightViewAllType`).
- **Repo additions:** `ItemRepository.getDonatedItems(userId)`, `ItemRepository.getKeptItems(userId)`,
  `ItemRepository.clearKeptUntil(itemId)`; `WardrobeNotifier.clearKeptUntil(itemId)`.

### What's already built (do NOT rebuild) — Phase 4 + earlier reference:
- **Engines (Phase 5, see Phase 5 block above for full list):** all `lib/engine/*`
  pure-Dart engines + tests are done. `badge_engine.dart` (computeAllBadges;
  `_isDonationCandidate` now wired to donation_rules — P2 live),
  `condition_engine.dart` (conditionThreshold, computeConditionNextDrop,
  checkAutoConditionDrop, recalc helpers — DONE, reuse, do not rewrite)
- **Wardrobe UI (Phase 4 complete):** `wardrobe_page.dart`, `add_edit_item_page.dart`
  (Add+Edit), `item_detail_page.dart`, `full_wear_history_page.dart`
- **Shared widgets:** `wardrobe_item_card`, `badge_chip` (+extraCount), `app_filter_chip`,
  `primary_button`, `outlined_button_widget`, `history_row.dart` (reusable list row),
  `main_shell`, `app_color_scheme.dart` (dark-mode ThemeExtension — use `context.colors.X`)
- **Constants (engines read these — DO NOT re-derive from MD):** `enums.dart`,
  `item_type_dictionary.dart` (types + default/allowed occasions + defaultFormality +
  conditionThreshold), `app_constants.dart` (history bucket → value mappings),
  `kSwatchColours` (12 swatches)
- **Data/providers:** all 5 models + repos; `wardrobe_providers.dart` (WardrobeNotifier
  with addItem/editItem/deleteItem/logWorn/**logSkipped/logSkippedItems/logOutfitWorn**/
  updateItemStatus/confirmDonation/setKeptUntil; `itemEventsProvider`, `itemImageUrlProvider`,
  `currentUserIdProvider`). Repos gained `ItemRepository.getItemsByIds`,
  `OutfitLogRepository.logOutfit/getOutfitItemsForLogs/getOutfitHistory`.
- **Phase 6 providers (reuse, do NOT rebuild):** `outfit_generator_provider.dart`
  (`outfitGeneratorProvider` + `outfitTabIndexProvider`), `daily_rotation_providers.dart`
  (`dailyRotationSkippedTodayProvider`), `outfit_history_providers.dart`, `home_providers.dart`.
- **Phase 6 shared widgets/helpers:** `core/widgets/confirm_sheet.dart`
  (`showConfirmSheet` side-by-side + `showLogWearSheet`), `features/outfit/build_outfit_action.dart`
  (`openGeneratorWithPin` — pins + confirms + opens Generator), `AppColors.scoreBandColours`
  (outfit score 80/60) + `AppColors.utilisationFill` (utilisation 70/40 — for Insights).
- **Phase 6 screens (DONE):** `features/outfit/` (outfit_page, daily_rotation_tab,
  outfit_generator_tab, outfit_detail_page, outfit_history_page), `features/home/home_page.dart`.

### Phase 5 — DONE. See the Phase 5 block in "Phase status" above for the full
inventory of engines + contracts. Engine entry points live in `lib/engine/`,
mirrored by `test/engine/` (139 tests). DECISIONS.md M1 records the reviewed colour matrix.

### Critical pattern: dark mode
ALL new widgets must use `context.colors.X` (from `lib/core/theme/app_color_scheme.dart`)
instead of hardcoded `AppColors.*` constants. This is now enforced — any hardcoded light
color will break dark mode. Import `app_color_scheme.dart`, use `final c = context.colors;`.

Run: `flutter run --dart-define-from-file=config/supabase.local.json`

## Verify commands
- `flutter analyze` — must be clean.
- `flutter test` — engine tests (Phase 5+) must pass.
- `flutter run --dart-define=...` — manual flow on emulator.

## Update rule
At the end of each phase: tick its box, add a one-line "what landed", set the
"next action", and note any new open decisions.
