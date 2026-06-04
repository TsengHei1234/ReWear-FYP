# Contract — Daily Rotation Tab (UI, Phase 6 Step 2)

**Sources:** FE §22 (UI authority), FE §6.17 (segmented control), §6.18 (score pill),
§38 (confirm sheet), §2353 (Skip = destructive). RE "Daily Rotation — Backend
Behaviour" + the already-built engine `lib/engine/daily/daily_rotation_display.dart`.
**Location:** `lib/features/outfit/` + `lib/core/widgets/confirm_sheet.dart`.

## Screen structure (one shell screen, two tabs)
The shell "Outfit" branch → `OutfitPage`: top bar ("Outfit" + history clock + avatar),
a **segmented control** (Daily Rotation | Outfit Generator, FE §6.17), and a body that
switches between `DailyRotationTab` and the Generator (Step 3 — placeholder for now).

## DailyRotationTab
- **Occasion chips** (single-select, scrollable): All · Casual · Work · Active · Relax.
  Default All. "All" → `occasion: null` into `rankDailyRotation`.
- **Layer chips** (single-select, scrollable): All · Top · Bottom · Outerwear · Shoes.
  Default All. Filters the ranked list by `ItemCategory` (Shoes→footwear); All → no
  category filter (OTHERS already excluded by the engine).
- **Section label:** "Top N Rotation Picks". Show the **top 5** of the filtered list.
- Data: watch `wardrobeProvider` + `profileProvider`; call
  `rankDailyRotation(items, occasion:, mode: profile.recommendationMode, now: DateTime.now(),
  preferredColours:, dislikedColours:)`. Loading→spinner, empty→friendly empty state.

## Decision — priority label/colours (CONFLICT resolved)
FE §22 lists TDS≥0.8 High / 0.5–0.8 Medium. The locked engine `priorityLabel(nibs, tds)`
uses **NIBS>0 New · TDS≥0.70 High · TDS≥0.35 Medium · else Low**. **Authority = RE (logic).**
Use the engine function for the label; apply FE §22 *colours* by label (brand-fixed,
do NOT flip — `AppColors.*`):
- High → bg #FEF2F2 / text #B91C1C · Medium → #FFFBEB / #92400E ·
- New Item → #EFF6FF / #1D4ED8 · Low → neutral #F3F4F6 / #374151.

## Card (FE §22 + agreed mock — layout LOCKED, do not change)
White surface, 0.5px border, radius 16, padding 12. Row 1: left = photo 88×88 r10 +
score pill below (4px gap, bg primary, white 11 semibold = `dailyRotationDisplayScore(frs)`);
right = name (13 semibold) · "Category · Type" (11 tertiary) · priority badge ·
last-worn line (clock + `lastWornLabel(item, now:)`) · wear-count line (rotate +
`wearCountLabel(item)`). Row 2: Wear + Skip outlined (36h, r10, 8px gap), Build Outfit
primary full-width (36h, r10) 6px below. Photo via `itemImageUrlProvider(item.imagePath)`.

## Actions (RE "Daily Rotation — Actions")
- **Wear** → `WardrobeNotifier.logWorn(item, source: DAILY_ROTATION)` + snackbar. Natural
  re-rank (FRS drops) moves it down/out.
- **Skip** → confirm sheet (destructive, confirm label "Skip") → on confirm:
  `logSkipped(item, source: DAILY_ROTATION)` + remove the card from the **session list**
  (local excluded-id set; FE §22 "removed from the session list without animation").
- **Build Outfit** → `outfitGeneratorProvider.notifier.setPinnedItem(item)` + switch the
  segmented control to the Generator tab (real generation lands Step 3).

## Notes / out of scope for Step 2
- Generator tab body = placeholder (shows pinned item if set); built in Step 3.
- History clock icon → Outfit History (Step 5); snackbar-stub for now.
- Wardrobe-card / Item-Detail "Build Outfit" buttons wired in Step 5.
- No new pure logic → no new unit tests; verified via `flutter analyze` + on-device run.
