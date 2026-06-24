import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/engine/daily/daily_rotation_display.dart';

import 'support/item_factory.dart';

void main() {
  final now = DateTime(2026, 6, 1);

  group('display score', () {
    test('min(round(FRS×100), 100)', () {
      expect(dailyRotationDisplayScore(0.94), 94);
      expect(dailyRotationDisplayScore(0.945), 95);
      expect(dailyRotationDisplayScore(1.15), 100);
    });
  });

  group('priority label', () {
    test('NIBS > 0 → New Item (regardless of TDS)', () {
      expect(priorityLabel(nibs: 0.5, tds: 0.9), 'New Item');
    });
    test('TDS bands when NIBS 0', () {
      expect(priorityLabel(nibs: 0, tds: 0.70), 'High Rotation Priority');
      expect(priorityLabel(nibs: 0, tds: 0.35), 'Medium Rotation Priority');
      expect(priorityLabel(nibs: 0, tds: 0.34), 'Low Rotation Priority');
    });
  });

  group('last worn label', () {
    test('unknown', () {
      expect(lastWornLabel(makeItem(lastWornUnknown: true), now: now),
          'Last worn unknown');
    });
    test('never worn (null date)', () {
      expect(lastWornLabel(makeItem(lastWornDate: null), now: now), 'Never worn');
    });
    test('X days ago', () {
      expect(
        lastWornLabel(
            makeItem(lastWornDate: now.subtract(const Duration(days: 14))),
            now: now),
        'Last worn: 14d ago',
      );
    });
  });

  group('wear status label', () {
    test('usage unknown', () {
      expect(wearStatusLabel(makeItem(wearCountUnknown: true), now: now),
          'Usage unknown');
    });
    test('never worn', () {
      expect(wearStatusLabel(makeItem(wearCount: 0), now: now), 'Never worn');
    });
    test('rarely worn (wear_rate < 0.05)', () {
      // 3 wears over 100 days = 0.03
      expect(
        wearStatusLabel(
            makeItem(wearCount: 3, dateAdded: now.subtract(const Duration(days: 100))),
            now: now),
        'Rarely worn',
      );
    });
    test('balanced wear (0.05 <= rate < 0.20)', () {
      // 8 wears over 100 days = 0.08
      expect(
        wearStatusLabel(
            makeItem(wearCount: 8, dateAdded: now.subtract(const Duration(days: 100))),
            now: now),
        'Balanced wear',
      );
    });
    test('overused (rate >= 0.20)', () {
      // 30 wears over 100 days = 0.30
      expect(
        wearStatusLabel(
            makeItem(wearCount: 30, dateAdded: now.subtract(const Duration(days: 100))),
            now: now),
        'Overused',
      );
    });
    test('1 wear / 5 days (rate 0.20) → Balanced wear, not Overused '
        '(evidence floor)', () {
      expect(
        wearStatusLabel(
            makeItem(wearCount: 1, dateAdded: now.subtract(const Duration(days: 5))),
            now: now),
        'Balanced wear',
      );
    });
    test('pre-owned item uses initialUsageAgeDays (not overused)', () {
      // 30 wears, added 100 days ago, owned 365 days before the app.
      // Canonical wear rate = 30 / (365 + 100) = 0.065 → Balanced wear,
      // NOT 30 / 100 = 0.30 → Overused.
      expect(
        wearStatusLabel(
            makeItem(
              wearCount: 30,
              dateAdded: now.subtract(const Duration(days: 100)),
              initialUsageAgeDays: 365,
            ),
            now: now),
        'Balanced wear',
      );
    });
  });

  group('wear count label', () {
    test('unknown', () {
      expect(wearCountLabel(makeItem(wearCountUnknown: true)), 'Wears unknown');
    });
    test('singular', () {
      expect(wearCountLabel(makeItem(wearCount: 1)), '1 wear');
    });
    test('plural', () {
      expect(wearCountLabel(makeItem(wearCount: 8)), '8 wears');
    });
  });

  group('rankDailyRotation', () {
    test('excludes OTHERS category and ranks by FRS', () {
      final top = makeItem(
        id: 'top',
        category: ItemCategory.top,
        occasionTags: const [Occasion.casual],
        condition: 4,
        isNewItem: false,
        wearCount: 2,
        lastWornDate: now.subtract(const Duration(days: 40)),
        dateAdded: now.subtract(const Duration(days: 100)),
      );
      final accessory = makeItem(
        id: 'acc',
        category: ItemCategory.others,
        type: 'WATCH',
        occasionTags: const [Occasion.casual],
        condition: 4,
      );
      final ranked = rankDailyRotation(
        [top, accessory],
        occasion: Occasion.casual,
        mode: RecommendationMode.pureRotation,
        now: now,
      );
      final ids = ranked.map((s) => s.item.id);
      expect(ids, contains('top'));
      expect(ids, isNot(contains('acc')));
    });
  });
}
