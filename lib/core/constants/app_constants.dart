import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'enums.dart';

/// Misc app-wide constants and the locked "approximate history" mappings.
///
/// Source of truth: Rule Engine "Add Item — Initial History Handling" and
/// Database §12 (storage).
class AppConstants {
  AppConstants._();

  static const String appName = 'ReWear';
  static const String appVersion = '1.0.0';

  /// Supabase Storage bucket for clothing photos (Database §12).
  static const String storageBucket = 'wardrobe-items';

  /// Storage path pattern: {user_id}/{item_id}/main.jpg
  static String itemImagePath(String userId, String itemId) =>
      '$userId/$itemId/main.jpg';

  static const int defaultLaundryCycleDays = 3;
  static const int laundryCycleMin = 1;
  static const int laundryCycleMax = 14;
  static const int maxColourSelections = 3; // per section (locked #12)
  static const int defaultCondition = 5; // Excellent
}

/// "Approximate last worn" → days_since_worn used (Rule Engine).
/// The "I don't remember" option is handled separately (last_worn_unknown=true).
enum LastWornOption {
  thisWeek('This week', 4),
  thisMonth('This month', 15),
  oneToThreeMonths('1–3 months ago', 60),
  threeToSixMonths('3–6 months ago', 135),
  sixPlusMonths('6+ months ago', 210),
  dontRemember("I don't remember", null);

  const LastWornOption(this.label, this.mappedDays);
  final String label;

  /// Null = unknown → caller sets last_worn_unknown = true, TDS fallback 0.50.
  final int? mappedDays;
}

/// "Approximate wear count" → wear_count stored (Rule Engine).
enum WearCountOption {
  oneToFive('1–5 times', 3),
  sixToTwenty('6–20 times', 10),
  twentyPlus('20+ times', 25),
  dontRemember("I don't remember", null);

  const WearCountOption(this.label, this.mappedCount);
  final String label;

  /// Null = unknown → wear_count=0, wear_count_unknown=true, WFSS fallback 0.50.
  final int? mappedCount;
}

/// "Approximate owned duration" → initial_usage_age_days (Rule Engine).
/// Uses the backend's fuller list (plan C4).
enum OwnedDurationOption {
  lessThan1Month('Less than 1 month', 30),
  oneToThreeMonths('1–3 months', 90),
  threeToSixMonths('3–6 months', 180),
  sixToTwelveMonths('6–12 months', 365),
  oneToTwoYears('1–2 years', 730),
  twoPlusYears('2+ years', 1095),
  dontRemember("I don't remember", 365); // safe default

  const OwnedDurationOption(this.label, this.mappedDays);
  final String label;
  final int mappedDays;
}

/// Maps a clothing swatch token to its display [Color] (Frontend §1).
const Map<SwatchColour, Color> kSwatchColours = {
  SwatchColour.black: AppColors.swatchBlack,
  SwatchColour.white: AppColors.swatchWhite,
  SwatchColour.grey: AppColors.swatchGrey,
  SwatchColour.beige: AppColors.swatchBeige,
  SwatchColour.navy: AppColors.swatchNavy,
  SwatchColour.blue: AppColors.swatchBlue,
  SwatchColour.red: AppColors.swatchRed,
  SwatchColour.green: AppColors.swatchGreen,
  SwatchColour.brown: AppColors.swatchBrown,
  SwatchColour.yellow: AppColors.swatchYellow,
  SwatchColour.pink: AppColors.swatchPink,
  SwatchColour.purple: AppColors.swatchPurple,
};
