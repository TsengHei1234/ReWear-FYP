# Phase 4 Step 1 — Foundation Contract
## Engines + Shared Widgets + Nav Shell

**Sources:** FE §1 (badge colours) · FE §6 (component specs) · FE §7 (nav) ·
FE §39 (badge system) · RE "Item Badge Labels" · RE "Condition Review Thresholds"

---

## 1. badge_engine  (`lib/engine/badges/badge_engine.dart`)

Pure Dart — no Flutter/Supabase imports. Input: one `Item` + the full wardrobe
list (for Most Worn top-10% calc). Output: `List<BadgeType>` ordered by priority.

| Priority | BadgeType | Trigger |
|---|---|---|
| 1 | wornOut | condition == 1 |
| 2 | donationReview | flagged by any D1–D5 (stub: always false until Phase 5) |
| 3 | overused | wearRate >= 0.20 (wearRate = wear_count / days_since_added, min 1 day) |
| 4 | skippedOften | skip_count / (wear_count + skip_count) > 0.50, and (wear_count + skip_count) >= 3 |
| 5 | neverWorn | wear_count == 0 AND days_since_added > 14 (C1 resolution) |
| 6 | longUnused | wear_count > 0 AND days_since_worn > 60 |
| 7 | isNew | is_new_item == true AND days_since_added <= 14 |
| 8 | mostWorn | top 10% by wear_count (ceil(0.10×N), min 1) — M5 resolution |

Status badges (LAUNDRY / LENT / STORED) are separate — shown via overlay, not
via this function.
Exclude DELETED + DONATED items entirely.

---

## 2. condition_engine  (`lib/engine/condition/condition_engine.dart`)

Pure Dart. Functions:
- `int conditionThreshold(ItemCategory category, String type)` → wear count per drop
- `int? computeConditionNextDrop(Item item)` → null if MANUAL or condition==1
- `Item checkAutoConditionDrop(Item item)` → returns item with condition/next_drop
  updated if threshold crossed; caller persists + fires N6

Thresholds: TOP=28, BOTTOM=58, OUTERWEAR=34, FOOTWEAR=25 (SPORT_SHOES=50), OTHERS=25.
SPORT_SHOES detection: `item.type == 'SPORT_SHOES'` (matches Item Type Dictionary key).

---

## 3. Shared widgets

| Widget | File | Spec |
|---|---|---|
| BadgeChip | `core/widgets/badge_chip.dart` | FE §39 + §1 semantic colours |
| PrimaryButton | `core/widgets/primary_button.dart` | FE §6.1 |
| OutlinedButton | `core/widgets/outlined_button.dart` | FE §6.2 |
| AppFilterChip | `core/widgets/app_filter_chip.dart` | FE §6.5 |
| WardrobeItemCard | `core/widgets/wardrobe_item_card.dart` | uses BadgeChip + CachedNetworkImage |

WardrobeItemCard grid card:
- Square aspect ratio, border radius 18px
- Item photo (CachedNetworkImage) or grey placeholder
- Item name at bottom (12px semibold, white, shadow)
- Status overlay (grey + label) when LAUNDRY/LENT/STORED
- BadgeChip top-left if any badge matches
- Taps → Item Detail

---

## 4. Main nav shell  (`features/shell/main_shell.dart`)

5-tab StatefulShellRoute (go_router). Tabs: Home · Wardrobe · Outfit · Donate · Insights.
Bottom nav spec: FE §6.14 (pill active state, #4A7055 icon + label).
4 tabs show `PlaceholderPage` until their phases. Wardrobe tab wired to
WardrobePage (built in Step 2).
Router updated: after login/onboarding → `/shell/wardrobe` (temp default until
Home is built in Phase 6 → then switches to `/shell/home`).

---

## Checklist
- [ ] badge_engine computes all 8 badge types correctly (D2 stub = never flags)
- [ ] condition_engine threshold lookup correct for all 6 categories
- [ ] checkAutoConditionDrop returns mutated item when wear_count >= next_drop
- [ ] BadgeChip renders correct background + text colour per badge type
- [ ] PrimaryButton + OutlinedButton match FE §6.1/6.2 spec
- [ ] AppFilterChip selected/unselected states correct
- [ ] WardrobeItemCard shows photo OR placeholder, badge top-left, status overlay
- [ ] Main shell renders 5-tab nav; active tab shows pill + green icon
- [ ] flutter analyze clean
