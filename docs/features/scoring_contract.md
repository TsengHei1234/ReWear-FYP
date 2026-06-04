# Contract — Scoring engines (Layer 2, S1–S6)

**Source:** RE "Layer 2 — Scoring Formulas" (S1–S6) + "Rotation window examples".
**Location:** `lib/engine/scoring/{tds,sps,wfss,nibs,ps,frs}.dart` + `test/engine/`.
**Purity:** pure Dart. May import `data/models/item.dart`, `core/constants/*`
(all pure Dart). NO Flutter/Supabase. `now` is injected (param), never `DateTime.now()`.

All scores ∈ [0.0, 1.0] unless noted. Higher = recommend more.

## Shared helpers
- `daysSinceAdded = (now - item.dateAdded).inDays`
- `daysSinceWorn  = (now - item.lastWornDate).inDays` (only if lastWornDate != null)

## S1 — TDS (Temporal Decay Score)
```
category_active_count = # IN_WARDROBE items in same category (excl DELETED, DONATED)
rotation_window_days  = clamp(category_active_count × 1.5, 30, 180)

IF is_new_item && wear_count==0 && days_since_added<=14:  TDS = 0.50   (NIBS window)
ELSE IF last_worn_unknown:                                 TDS = 0.50   (neutral)
ELSE:
    days_since_worn = (last_worn_date==NULL) ? days_since_added : today-last_worn_date
    TDS = min(days_since_worn / rotation_window_days, 1.0)
```
**Worked (rotation window):** 10→30, 20→30, 40→60, 60→90, 100→150, 150+→180.

## S2 — SPS (Skip Penalty Score)
```
IF wear_count==0 && skip_count==0:  SPS = 1.0
ELSE: SPS = 1.0 - (skip_count / (wear_count + skip_count + 5))   (+5 smoothing)
```

## S3 — WFSS (Wear Frequency Saturation Score)
```
IF wear_count_unknown:  WFSS = 0.50
ELSE:
    usage_period_days = (initial_wear_count_option=="I don't remember")
        ? max(days_since_added, 1)
        : max(initial_usage_age_days + days_since_added, 1)
    wear_rate = wear_count / usage_period_days
    IF wear_rate >= 0.20:  WFSS = 0.10
    ELSE:                  WFSS = 1.0 - (wear_rate / 0.20)
    WFSS = clamp(WFSS, 0.10, 1.00)
```
NOTE: "I don't remember" detection — `item.initialWearCountOption` stores the enum
NAME (e.g. `WearCountOption.dontRemember.name` == `"dontRemember"`), not the label.
Use `wearCountUnknown` flag (set when dontRemember chosen) as the WFSS==0.50 gate;
for the usage-period branch, treat `wearCountUnknown` (no remembered initial age) as
the "app-observed only" path. See app_constants WearCountOption.dontRemember (null).

## S4 — NIBS (New Item Boost Score)
```
IF wear_count==0 && is_new_item:
    days_since_added<=7:   NIBS = 1.0
    days_since_added<=14:  NIBS = (14 - days_since_added) / 7
    else:                  NIBS = 0.0
ELSE: NIBS = 0.0
```

## S5 — PS (Preference Score) — Mode A only
```
PS = 0.50
IF is_favorite:                      PS += 0.20
IF color_tags[0] in preferred:       PS += 0.15
IF color_tags[0] in disliked:        PS -= 0.20
PS = clamp(PS, 0.00, 1.00)
```
preferred/disliked come from profile.style_preferences (passed in as sets of colour tokens).

## S6 — FRS (Final Recommendation Score)
```
Mode A (Balanced): 0.35·TDS + 0.25·WFSS + 0.20·SPS + 0.20·PS + 0.15·NIBS   (max 1.15)
Mode B (Pure):     0.45·TDS + 0.30·WFSS + 0.25·SPS              + 0.15·NIBS (max 1.15)
```
NIBS is an additive bonus (weights of the others sum to 1.00; NIBS pushes max to 1.15).
**Tiebreaker (equal FRS):** primary last_worn_date asc (NULL first); secondary days_since_added desc.

## Edge cases
- day-0 brand-new item: daysSinceAdded==0; TDS=0.50 (NIBS window), NIBS=1.0.
- never-worn old item (>14d, not new): TDS uses days_since_added proxy.
- divide-by-zero guarded by max(...,1) in WFSS and clamp(...,30,..) in TDS window.
