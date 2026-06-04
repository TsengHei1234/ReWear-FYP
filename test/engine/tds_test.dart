import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/engine/scoring/tds.dart';

import 'support/item_factory.dart';

void main() {
  group('rotationWindowDays — RE worked examples', () {
    test('10 or fewer active items → 30 (minimum)', () {
      expect(rotationWindowDays(10), 30);
      expect(rotationWindowDays(5), 30);
      expect(rotationWindowDays(0), 30);
    });
    test('20 active → 30', () => expect(rotationWindowDays(20), 30));
    test('40 active → 60', () => expect(rotationWindowDays(40), 60));
    test('60 active → 90', () => expect(rotationWindowDays(60), 90));
    test('100 active → 150', () => expect(rotationWindowDays(100), 150));
    test('150+ active → 180 (maximum)', () {
      expect(rotationWindowDays(150), 180);
      expect(rotationWindowDays(300), 180);
    });
  });

  group('temporalDecayScore', () {
    final now = DateTime(2026, 6, 1);

    test('new unworn item inside 14-day window → 0.50 (NIBS suppression)', () {
      final item = makeItem(
        isNewItem: true,
        wearCount: 0,
        dateAdded: now.subtract(const Duration(days: 5)),
      );
      expect(
        temporalDecayScore(item, categoryActiveCount: 10, now: now),
        0.50,
      );
    });

    test('last_worn_unknown → 0.50 (neutral fallback)', () {
      final item = makeItem(
        isNewItem: false,
        lastWornUnknown: true,
        wearCount: 3,
        dateAdded: now.subtract(const Duration(days: 100)),
      );
      expect(
        temporalDecayScore(item, categoryActiveCount: 10, now: now),
        0.50,
      );
    });

    test('worn 15 days ago, window 30 → 0.50', () {
      final item = makeItem(
        isNewItem: false,
        wearCount: 4,
        lastWornDate: now.subtract(const Duration(days: 15)),
        dateAdded: now.subtract(const Duration(days: 100)),
      );
      expect(
        temporalDecayScore(item, categoryActiveCount: 10, now: now),
        closeTo(0.50, 1e-9),
      );
    });

    test('worn beyond rotation window → clamped to 1.0', () {
      final item = makeItem(
        isNewItem: false,
        wearCount: 4,
        lastWornDate: now.subtract(const Duration(days: 90)),
        dateAdded: now.subtract(const Duration(days: 200)),
      );
      expect(
        temporalDecayScore(item, categoryActiveCount: 10, now: now),
        1.0,
      );
    });

    test('never-worn non-new item uses days_since_added proxy', () {
      // 30 days in app, window 30 → 30/30 = 1.0
      final item = makeItem(
        isNewItem: false,
        wearCount: 0,
        lastWornDate: null,
        dateAdded: now.subtract(const Duration(days: 30)),
      );
      expect(
        temporalDecayScore(item, categoryActiveCount: 10, now: now),
        closeTo(1.0, 1e-9),
      );
    });
  });
}
