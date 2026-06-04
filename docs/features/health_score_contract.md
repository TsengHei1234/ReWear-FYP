# Contract — Insights Health Score + quick stats

**Source:** RE "Insights — Health Score". Pure Dart.
**Location:** `lib/engine/insights/health_score.dart` + test.

`active_items = items WHERE status NOT IN (DONATED, DELETED)`.
`wear_rate = wear_count / max(days_since_added, 1)`.

## Health Score
```
active==0 → no score, message "Add items to see your wardrobe health".
total_worn_events < 5 → partial=true, message "Keep logging outfits to build your Health Score".
items_worn_last_30 = unique active item_id with WORN event_at within 30 days.
utilisation_rate  = clamp(items_worn_last_30 / active, 0, 1)
utilisation_score = utilisation_rate × 100 × 0.50
overused_items    = active items WHERE wear_rate>=0.20 AND status==IN_WARDROBE
rotation_score    = (1 - overused_items/active) × 100 × 0.50
HealthScore = round(utilisation_score + rotation_score)
```

## Verdict (full, non-partial)
80–100 "Great job! Your wardrobe rotation is healthy." ·
60–79 "Good progress — a few items need more attention." ·
40–59 "Your wardrobe has room for better utilisation." ·
0–39 "Many items in your wardrobe are being neglected."

## Quick stats
total = active count · wornThisMonth = items_worn_last_30 ·
neverWorn = active WHERE wear_count==0 · donationCandidates = active flagged by any D1–D5.

## Attention predicates (status NOT IN DONATED/DELETED unless noted)
- neverWorn: wear_count==0
- longUnused: wear_count>0 AND days_since_worn>60
- skippedOften: raw_skip_ratio>0.50
- overused: wear_rate>=0.20 AND status==IN_WARDROBE
- sleeping: wear_count>0 AND days_since_worn>=90
