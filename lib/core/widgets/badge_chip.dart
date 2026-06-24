import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../../engine/badges/badge_engine.dart';

/// Pill badge chip. Source: FE §39 + §1 semantic colours.
///
/// On grid cards: show one chip (primary badge).
/// On Item Detail: show all chips.
class BadgeChip extends StatelessWidget {
  const BadgeChip({super.key, required this.badge, this.extraCount = 0});

  final BadgeType badge;

  /// Number of *additional* badges to summarise as "+N" (grid card only).
  /// 0 → no suffix. Used on the wardrobe card where only the primary badge
  /// is shown but the user should know more exist.
  final int extraCount;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colours(badge);
    final text = extraCount > 0 ? '${_label(badge)} +$extraCount' : _label(badge);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
          height: 1.2,
        ),
      ),
    );
  }

  static String _label(BadgeType b) => switch (b) {
        BadgeType.wornOut => 'Worn out',
        BadgeType.donationReview => 'Donation review',
        BadgeType.overused => 'Overused',
        BadgeType.skippedOften => 'Skipped often',
        BadgeType.neverWorn => 'Never worn',
        BadgeType.longUnused => 'Long unused',
        BadgeType.isNew => 'New',
        BadgeType.mostWorn => 'Top Worn',
      };

  static (Color, Color) _colours(BadgeType b) => switch (b) {
        BadgeType.wornOut =>
          (AppColors.badgeWornOutBg, AppColors.badgeWornOutText),
        BadgeType.donationReview =>
          (AppColors.badgeDonationReviewBg, AppColors.badgeDonationReviewText),
        BadgeType.overused =>
          (AppColors.badgeOverusedBg, AppColors.badgeOverusedText),
        BadgeType.skippedOften =>
          (AppColors.badgeSkippedBg, AppColors.badgeSkippedText),
        BadgeType.neverWorn =>
          (AppColors.badgeNeverWornBg, AppColors.badgeNeverWornText),
        BadgeType.longUnused =>
          (AppColors.badgeLongUnusedBg, AppColors.badgeLongUnusedText),
        BadgeType.isNew =>
          (AppColors.badgeNewBg, AppColors.badgeNewText),
        BadgeType.mostWorn =>
          (AppColors.badgeMostWornBg, AppColors.badgeMostWornText),
      };
}

/// Grey pill for status overlays (LAUNDRY / LENT / STORED).
class StatusBadgeChip extends StatelessWidget {
  const StatusBadgeChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.badgeNeutralBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.badgeNeutralText,
          height: 1.2,
        ),
      ),
    );
  }
}
