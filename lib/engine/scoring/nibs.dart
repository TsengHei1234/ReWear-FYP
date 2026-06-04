import '../../data/models/item.dart';

/// S4 — New Item Boost Score (RE "Layer 2 — Scoring Formulas", S4).
/// Brand new never-worn items get a 14-day boost to surface in recommendations.
/// Already-owned items (is_new_item == false) never receive NIBS.
double newItemBoostScore(Item item, {required DateTime now}) {
  if (item.wearCount != 0 || !item.isNewItem) return 0.0;

  final daysSinceAdded = now.difference(item.dateAdded).inDays;
  if (daysSinceAdded <= 7) return 1.0; // full boost — first week
  if (daysSinceAdded <= 14) return (14 - daysSinceAdded) / 7; // smooth taper
  return 0.0; // grace period expired
}
