import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/data/models/item_event.dart';
import 'package:rewear/engine/insights/health_score.dart';

import 'support/item_factory.dart';

void main() {
  final now = DateTime(2026, 6, 1);

  ItemEvent worn(String itemId, {required int daysAgo, String id = 'e'}) =>
      ItemEvent(
        id: '$id-$itemId-$daysAgo',
        userId: 'u',
        itemId: itemId,
        eventType: EventType.worn,
        source: ItemEventSource.dailyRotation,
        eventAt: now.subtract(Duration(days: daysAgo)),
      );

  group('computeWardrobeHealth', () {
    test('no active items → no score, prompt message', () {
      final h = computeWardrobeHealth(const [], const [], now: now);
      expect(h.hasItems, isFalse);
      expect(h.message, contains('Add items'));
    });

    test('partial indicator when fewer than 5 worn events', () {
      final items = [
        makeItem(id: 'a', wearCount: 1, dateAdded: now.subtract(const Duration(days: 100))),
        makeItem(id: 'b', wearCount: 0, dateAdded: now.subtract(const Duration(days: 100))),
      ];
      final events = [worn('a', daysAgo: 3)];
      final h = computeWardrobeHealth(items, events, now: now);
      expect(h.hasItems, isTrue);
      expect(h.partial, isTrue);
      expect(h.message, contains('Keep logging outfits'));
    });

    test('perfect rotation: all worn recently, none overused → 100', () {
      // 4 active items, all worn in last 30 days, none overused (low wear_rate)
      final items = List.generate(
        4,
        (i) => makeItem(
          id: 'i$i',
          wearCount: 1,
          dateAdded: now.subtract(const Duration(days: 100)),
          lastWornDate: now.subtract(const Duration(days: 2)),
        ),
      );
      final events = [
        for (var i = 0; i < 4; i++) worn('i$i', daysAgo: i + 1),
        // pad to >=5 worn events so it's not partial
        worn('i0', daysAgo: 10, id: 'extra'),
      ];
      final h = computeWardrobeHealth(items, events, now: now);
      // utilisation = 4/4 = 100% ×0.5 = 50 ; overused 0 → rotation 100% ×0.5 = 50
      expect(h.score, 100);
      expect(h.partial, isFalse);
      expect(h.verdict, contains('Great job'));
    });

    test('half utilisation, no overuse → 75', () {
      // 4 active, 2 worn in last 30 days, none overused
      final items = List.generate(
        4,
        (i) => makeItem(
          id: 'i$i',
          wearCount: 1,
          dateAdded: now.subtract(const Duration(days: 100)),
        ),
      );
      final events = [
        worn('i0', daysAgo: 3),
        worn('i1', daysAgo: 5),
        worn('i0', daysAgo: 8),
        worn('i1', daysAgo: 9),
        worn('i0', daysAgo: 11),
      ];
      final h = computeWardrobeHealth(items, events, now: now);
      // util = 2/4 = 50% ×0.5 = 25 ; rotation 100% ×0.5 = 50 → 75
      expect(h.score, 75);
    });
  });

  group('attention predicates', () {
    test('neverWorn', () {
      expect(isNeverWorn(makeItem(wearCount: 0)), isTrue);
      expect(isNeverWorn(makeItem(wearCount: 2)), isFalse);
      expect(isNeverWorn(makeItem(wearCount: 0, status: ItemStatus.donated)),
          isFalse);
    });
    test('longUnused', () {
      expect(
        isLongUnused(
            makeItem(
                wearCount: 3, lastWornDate: now.subtract(const Duration(days: 70))),
            now: now),
        isTrue,
      );
      expect(
        isLongUnused(
            makeItem(
                wearCount: 3, lastWornDate: now.subtract(const Duration(days: 30))),
            now: now),
        isFalse,
      );
    });
    test('overused uses wear_rate >= 0.20 and IN_WARDROBE only', () {
      final overused = makeItem(
          wearCount: 30,
          dateAdded: now.subtract(const Duration(days: 100)),
          status: ItemStatus.inWardrobe);
      expect(isOverused(overused, now: now), isTrue);
      final laundry = makeItem(
          wearCount: 30,
          dateAdded: now.subtract(const Duration(days: 100)),
          status: ItemStatus.laundry);
      expect(isOverused(laundry, now: now), isFalse);
    });
    test('sleeping (>=90 days, worn before)', () {
      expect(
        isSleeping(
            makeItem(
                wearCount: 2, lastWornDate: now.subtract(const Duration(days: 95))),
            now: now),
        isTrue,
      );
    });
  });

  group('itemWearRate (corrected formula)', () {
    test('pre-owned item: uses initialUsageAgeDays + daysSinceAdded', () {
      // 25 wears, added 8 days ago, but pre-owned for 730 days
      // usagePeriodDays = 730 + 8 = 738 → wearRate ≈ 0.034 (NOT overused)
      final item = makeItem(
        wearCount: 25,
        dateAdded: now.subtract(const Duration(days: 8)),
        initialUsageAgeDays: 730,
      );
      expect(itemWearRate(item, now), lessThan(0.20));
      expect(isOverused(item, now: now), isFalse);
    });

    test('dontRemember: ignores initialUsageAgeDays, uses daysSinceAdded only',
        () {
      // Same numbers but user said they don't remember initial wear count
      // usagePeriodDays = 8 only → wearRate = 25/8 = 3.125 (overused)
      final item = makeItem(
        wearCount: 25,
        dateAdded: now.subtract(const Duration(days: 8)),
        initialUsageAgeDays: 730,
        initialWearCountOption: 'dontRemember',
      );
      expect(itemWearRate(item, now), greaterThanOrEqualTo(0.20));
      expect(isOverused(item, now: now), isTrue);
    });
  });

  group('quick stats', () {
    test('counts total / worn-this-month / never worn', () {
      final items = [
        makeItem(id: 'a', wearCount: 1, dateAdded: now.subtract(const Duration(days: 100))),
        makeItem(id: 'b', wearCount: 0, dateAdded: now.subtract(const Duration(days: 100))),
        makeItem(id: 'c', wearCount: 0, status: ItemStatus.donated),
      ];
      final events = [worn('a', daysAgo: 5)];
      final stats = computeQuickStats(items, events, now: now);
      expect(stats.totalItems, 2); // donated excluded
      expect(stats.wornThisMonth, 1);
      expect(stats.neverWorn, 1); // only 'b'
    });
  });
}
