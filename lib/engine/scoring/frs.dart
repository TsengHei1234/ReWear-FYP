import '../../core/constants/enums.dart';
import '../../data/models/item.dart';
import 'nibs.dart';
import 'ps.dart';
import 'sps.dart';
import 'tds.dart';
import 'wfss.dart';

/// S6 — Final Recommendation Score (RE "Layer 2 — Scoring Formulas", S6).
/// Combines all sub-scores into one ranking number per item.

/// Weighted combination. NIBS is an additive bonus on top of the weighted base
/// (the base weights sum to 1.00), so the maximum FRS is 1.15.
/// PS is used only in Mode A (Balanced); ignored in Mode B (Pure Rotation).
double finalRecommendationScore({
  required double tds,
  required double wfss,
  required double sps,
  required double nibs,
  required double ps,
  required RecommendationMode mode,
}) {
  switch (mode) {
    case RecommendationMode.balanced:
      return (0.35 * tds) +
          (0.25 * wfss) +
          (0.20 * sps) +
          (0.20 * ps) +
          (0.15 * nibs);
    case RecommendationMode.pureRotation:
      return (0.45 * tds) + (0.30 * wfss) + (0.25 * sps) + (0.15 * nibs);
  }
}

/// All Layer-2 scores for a single item, plus the combined FRS.
class ItemScore {
  const ItemScore({
    required this.item,
    required this.tds,
    required this.sps,
    required this.wfss,
    required this.nibs,
    required this.ps,
    required this.frs,
  });

  final Item item;
  final double tds;
  final double sps;
  final double wfss;
  final double nibs;
  final double ps;
  final double frs;
}

/// Computes every Layer-2 score for [item] and the final FRS.
/// [categoryActiveCount] feeds TDS's rotation window; [mode] selects the
/// FRS weighting and whether PS is applied.
ItemScore scoreItem(
  Item item, {
  required int categoryActiveCount,
  required DateTime now,
  required RecommendationMode mode,
  required Set<String> preferredColours,
  required Set<String> dislikedColours,
}) {
  final tds = temporalDecayScore(item,
      categoryActiveCount: categoryActiveCount, now: now);
  final sps = skipPenaltyScore(item);
  final wfss = wearFrequencySaturationScore(item, now: now);
  final nibs = newItemBoostScore(item, now: now);
  final ps = mode == RecommendationMode.balanced
      ? preferenceScore(item,
          preferredColours: preferredColours, dislikedColours: dislikedColours)
      : 0.0;

  final frs = finalRecommendationScore(
    tds: tds,
    wfss: wfss,
    sps: sps,
    nibs: nibs,
    ps: ps,
    mode: mode,
  );

  return ItemScore(
    item: item,
    tds: tds,
    sps: sps,
    wfss: wfss,
    nibs: nibs,
    ps: ps,
    frs: frs,
  );
}

/// Ranks scored items by FRS descending, applying the RE tiebreaker:
///   primary:   last_worn_date ascending (NULL = never worn comes first)
///   secondary: days_since_added descending (older in wardrobe wins)
/// Stable, non-mutating — returns a new list.
List<ItemScore> rankByFrs(List<ItemScore> scores, {required DateTime now}) {
  final sorted = [...scores];
  sorted.sort((a, b) {
    final byFrs = b.frs.compareTo(a.frs);
    if (byFrs != 0) return byFrs;

    // Primary tiebreaker: last_worn_date ascending, NULL first.
    final aWorn = a.item.lastWornDate;
    final bWorn = b.item.lastWornDate;
    if (aWorn == null && bWorn != null) return -1;
    if (aWorn != null && bWorn == null) return 1;
    if (aWorn != null && bWorn != null) {
      final byWorn = aWorn.compareTo(bWorn);
      if (byWorn != 0) return byWorn;
    }

    // Secondary tiebreaker: days_since_added descending (older first).
    return a.item.dateAdded.compareTo(b.item.dateAdded);
  });
  return sorted;
}
