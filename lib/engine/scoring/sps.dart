import '../../data/models/item.dart';

/// S2 — Skip Penalty Score (RE "Layer 2 — Scoring Formulas", S2).
/// Items the user repeatedly rejects score lower. +5 smoothing buffer prevents
/// a single early skip from unfairly penalising an item.
double skipPenaltyScore(Item item) {
  if (item.wearCount == 0 && item.skipCount == 0) return 1.0;
  return 1.0 - (item.skipCount / (item.wearCount + item.skipCount + 5));
}
