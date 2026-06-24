import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/engine/badges/badge_engine.dart';

import 'support/item_factory.dart';

/// Golden badge matrix (Stage 4). Verifies the `computeAllBadges` wrapper gates
/// New / Never Worn / Long Unused / Overused / Worn Out correctly. Uses a fixed
/// [now] for determinism.
void main() {
  final now = DateTime(2026, 6, 1);

  group('New vs Never Worn gating', () {
    test('brand new day 3 → New badge, NOT Never Worn', () {
      final item = makeItem(
        isNewItem: true,
        wearCount: 0,
        dateAdded: now.subtract(const Duration(days: 3)),
      );
      final badges = computeAllBadges(item, [item], now: now);
      expect(badges, contains(BadgeType.isNew));
      expect(badges, isNot(contains(BadgeType.neverWorn)));
    });

    test('new item day 15 → Never Worn badge, NOT New', () {
      final item = makeItem(
        isNewItem: true,
        wearCount: 0,
        dateAdded: now.subtract(const Duration(days: 15)),
      );
      final badges = computeAllBadges(item, [item], now: now);
      expect(badges, contains(BadgeType.neverWorn));
      expect(badges, isNot(contains(BadgeType.isNew)));
    });

    test(
        'pre-owned unworn, initialUsageAgeDays > 14, added today → Never Worn '
        'immediately via effectiveAge, no New badge', () {
      final item = makeItem(
        isNewItem: false,
        wearCount: 0,
        initialUsageAgeDays: 30,
        dateAdded: now, // daysSinceAdded == 0
      );
      final badges = computeAllBadges(item, [item], now: now);
      expect(badges, contains(BadgeType.neverWorn));
      expect(badges, isNot(contains(BadgeType.isNew)));
    });
  });

  group('attention badges', () {
    test('long unused 70d → Long Unused badge', () {
      final item = makeItem(
        isNewItem: false,
        wearCount: 3,
        condition: 5,
        lastWornDate: now.subtract(const Duration(days: 70)),
        dateAdded: now.subtract(const Duration(days: 200)),
      );
      final badges = computeAllBadges(item, [item], now: now);
      expect(badges, contains(BadgeType.longUnused));
    });

    test('overused item (wear_rate >= 0.20) → Overused badge', () {
      // 30 wears over 100 days = 0.30, worn recently so not long-unused.
      final item = makeItem(
        isNewItem: false,
        wearCount: 30,
        condition: 5,
        lastWornDate: now.subtract(const Duration(days: 2)),
        dateAdded: now.subtract(const Duration(days: 100)),
      );
      final badges = computeAllBadges(item, [item], now: now);
      expect(badges, contains(BadgeType.overused));
    });

    group('Overused evidence floor (Phase 11: wear_count >= 3)', () {
      test('1 wear / 5 days (rate 0.20) → NOT Overused (the Apple T-shirt bug)',
          () {
        final item = makeItem(
          isNewItem: true,
          wearCount: 1,
          dateAdded: now.subtract(const Duration(days: 5)),
        );
        final badges = computeAllBadges(item, [item], now: now);
        expect(badges, isNot(contains(BadgeType.overused)));
      });

      test('2 wears / 10 days (rate 0.20) → NOT Overused', () {
        final item = makeItem(
          isNewItem: false,
          wearCount: 2,
          dateAdded: now.subtract(const Duration(days: 10)),
        );
        final badges = computeAllBadges(item, [item], now: now);
        expect(badges, isNot(contains(BadgeType.overused)));
      });

      test('3 wears / 15 days (rate 0.20) → Overused (floor reached)', () {
        final item = makeItem(
          isNewItem: false,
          wearCount: 3,
          dateAdded: now.subtract(const Duration(days: 15)),
        );
        final badges = computeAllBadges(item, [item], now: now);
        expect(badges, contains(BadgeType.overused));
      });
    });

    test('condition == 1 → Worn Out badge', () {
      final item = makeItem(condition: 1, status: ItemStatus.inWardrobe);
      final badges = computeAllBadges(item, [item], now: now);
      expect(badges, contains(BadgeType.wornOut));
    });
  });
}
