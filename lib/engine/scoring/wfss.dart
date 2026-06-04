import '../../data/models/item.dart';

/// S3 — Wear Frequency Saturation Score (RE "Layer 2 — Scoring Formulas", S3).
/// Items worn too frequently score lower to give other clothes a chance.

/// The stored value of `WearCountOption.dontRemember.name` (app_constants.dart).
/// Compared as a literal to keep the engine free of Flutter imports
/// (app_constants pulls in flutter/material via kSwatchColours).
const String _dontRememberWearCount = 'dontRemember';

/// Saturation point: 0.20 = worn more than once every 5 days.
const double _saturationPoint = 0.20;

double wearFrequencySaturationScore(Item item, {required DateTime now}) {
  // Unknown history — neutral fallback.
  if (item.wearCountUnknown) return 0.50;

  final daysSinceAdded = now.difference(item.dateAdded).inDays;

  // If the user never remembered their initial wear count, only app-observed
  // wear data is trustworthy → numerator and denominator must match period.
  final int usagePeriodDays;
  if (item.initialWearCountOption == _dontRememberWearCount) {
    usagePeriodDays = daysSinceAdded < 1 ? 1 : daysSinceAdded;
  } else {
    final raw = item.initialUsageAgeDays + daysSinceAdded;
    usagePeriodDays = raw < 1 ? 1 : raw;
  }

  final wearRate = item.wearCount / usagePeriodDays;

  final double wfss;
  if (wearRate >= _saturationPoint) {
    wfss = 0.10; // overused
  } else {
    wfss = 1.0 - (wearRate / _saturationPoint);
  }
  return wfss.clamp(0.10, 1.00);
}
