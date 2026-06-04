# Contract — Daily Rotation (backend + display labels)

**Source:** RE "Daily Rotation — Backend Behaviour". Pure Dart. Recommends
individual items (not outfits). Excludes category==OTHERS.
**Location:** `lib/engine/daily/daily_rotation_display.dart` + test.

## Ranking (Steps 1–4)
Layer 1 (F2/F3/F4) → exclude OTHERS → FRS per item → sort FRS desc.
Minimum threshold does NOT apply.

## Display labels (display-only; no effect on data)
- **display_score** = min(round(FRS × 100), 100).
- **priority label**: NIBS>0 "New Item" · TDS≥0.70 "High Rotation Priority" ·
  TDS≥0.35 "Medium Rotation Priority" · else "Low Rotation Priority".
- **last worn label**: last_worn_unknown "Last worn unknown" · last_worn_date null
  "Never worn" · else "Last worn: [X]d ago".
- **wear status label** (wear_rate = wear_count/max(days_since_added,1)):
  wear_count_unknown "Usage unknown" · wear_count==0 "Never worn" ·
  wear_rate<0.05 "Rarely worn" · <0.20 "Balanced wear" · else "Overused".
- **wear count label**: wear_count_unknown "Wears unknown" · ==1 "1 wear" · else "[n] wears".
