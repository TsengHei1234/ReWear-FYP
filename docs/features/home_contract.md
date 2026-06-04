# Contract — Home (UI, Phase 6 Step 6)

**Sources:** FE §16. Engine: `rankDailyRotation` (suggestions) + `computeQuickStats`
(snapshot). **Location:** `lib/features/home/home_page.dart` (shell branch 0,
`Routes.shellHome`), `lib/providers/home_providers.dart`.

## Top bar
Time-based greeting ("Good morning/afternoon/evening, {first name}") + avatar
(initials; tap → Profile, snackbar-stub until Phase 8).

## Section 1 — Occasion chips
All · Casual · Work · Active · Relax (single-select, default All; `FilterChipRow`).
Filters the carousel via `rankDailyRotation(occasion:)`.

## Section 2 — Today's Suggestions (carousel)
`PageView` (viewportFraction 0.88), top 3 of `rankDailyRotation` (individual items;
worn-today items already excluded by F5/G2). Each card: 210px photo + overlays
(score pill bottom-left on black 60%; primary badge bottom-right via `computeAllBadges`),
name (14 bold), Category·Type, then **Wear Today** (logWorn, with confirm sheet) +
**View Item** (→ Item Detail; Back returns to Home). Empty state when no picks.

## Section 3 — Wardrobe Snapshot (`homeSnapshotProvider` → `computeQuickStats`)
- Utilisation Rate = `wornThisMonth / totalItems` (%), progress bar.
- Active Rotation tile = `wornThisMonth` (primary-light) · Dormant tile =
  `totalItems − wornThisMonth` (surface-2).
- "{donationCandidates} items for donation review →" → Donate tab (`context.go`).
- `homeSnapshotProvider` fetches the last 30 days of events; TDD (1).

## Routing
Post-auth landing changed from `/wardrobe` → `/home` (splash, login, onboarding).
