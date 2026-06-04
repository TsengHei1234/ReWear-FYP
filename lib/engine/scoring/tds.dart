import '../../data/models/item.dart';

/// S1 — Temporal Decay Score (RE "Layer 2 — Scoring Formulas", S1).
/// Pure Dart. Items not worn for a long time score higher.

/// rotation_window_days = clamp(category_active_count × 1.5, 30, 180).
/// [categoryActiveCount] = # IN_WARDROBE items in the same category
/// (excludes DELETED, DONATED) — computed by the caller.
int rotationWindowDays(int categoryActiveCount) {
  final raw = categoryActiveCount * 1.5;
  return raw.clamp(30, 180).round();
}

/// TDS ∈ [0.0, 1.0]. Higher = longer unused / never worn.
double temporalDecayScore(
  Item item, {
  required int categoryActiveCount,
  required DateTime now,
}) {
  final daysSinceAdded = now.difference(item.dateAdded).inDays;

  // NIBS window active — suppress TDS to prevent double-boost with NIBS.
  if (item.isNewItem && item.wearCount == 0 && daysSinceAdded <= 14) {
    return 0.50;
  }

  // Unknown history — neutral fallback.
  if (item.lastWornUnknown) return 0.50;

  final window = rotationWindowDays(categoryActiveCount);
  final daysSinceWorn = item.lastWornDate == null
      ? daysSinceAdded // never-worn proxy: time in app as urgency signal
      : now.difference(item.lastWornDate!).inDays;

  final tds = daysSinceWorn / window;
  return tds < 1.0 ? tds : 1.0;
}
