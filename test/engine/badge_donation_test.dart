import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/engine/badges/badge_engine.dart';

import 'support/item_factory.dart';

void main() {
  final now = DateTime(2026, 6, 1);

  group('badge P2 — donation review wired to donation_rules', () {
    test('condition-1 item is flagged as donation review (D4)', () {
      final item = makeItem(condition: 1, status: ItemStatus.inWardrobe);
      final badges = computeAllBadges(item, [item], now: now);
      expect(badges, contains(BadgeType.donationReview));
    });

    test('kept_until in future suppresses the donation badge', () {
      final item = makeItem(
        condition: 1,
        status: ItemStatus.inWardrobe,
        keptUntil: now.add(const Duration(days: 365)),
      );
      final badges = computeAllBadges(item, [item], now: now);
      expect(badges, isNot(contains(BadgeType.donationReview)));
    });

    test('healthy item is not flagged for donation', () {
      final item = makeItem(
        condition: 5,
        wearCount: 5,
        lastWornDate: now.subtract(const Duration(days: 3)),
        status: ItemStatus.inWardrobe,
      );
      final badges = computeAllBadges(item, [item], now: now);
      expect(badges, isNot(contains(BadgeType.donationReview)));
    });
  });

  group('badge P4 skipped often', () {
    test('uses skip_ratio > 0.50 without an extra interaction guard', () {
      final item = makeItem(
        wearCount: 1,
        skipCount: 2,
        dateAdded: now.subtract(const Duration(days: 10)),
      );

      final badges = computeAllBadges(item, [item], now: now);

      expect(badges, contains(BadgeType.skippedOften));
    });
  });
}
