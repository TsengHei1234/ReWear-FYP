import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/engine/filters/layer1_filters.dart';

import 'support/item_factory.dart';

void main() {
  group('individual filter predicates', () {
    test('F2 occasion: null (All) keeps everything', () {
      final item = makeItem(occasionTags: [Occasion.work]);
      expect(passesOccasion(item, null), isTrue);
    });
    test('F2 occasion: keeps only items tagged with the occasion', () {
      final work = makeItem(occasionTags: [Occasion.work, Occasion.casual]);
      final casualOnly = makeItem(occasionTags: [Occasion.casual]);
      expect(passesOccasion(work, Occasion.work), isTrue);
      expect(passesOccasion(casualOnly, Occasion.work), isFalse);
    });
    test('F3 condition gate: condition 1 removed, >=2 kept', () {
      expect(passesConditionGate(makeItem(condition: 1)), isFalse);
      expect(passesConditionGate(makeItem(condition: 2)), isTrue);
      expect(passesConditionGate(makeItem(condition: 5)), isTrue);
    });
    test('F4 availability: only IN_WARDROBE kept', () {
      expect(passesAvailability(makeItem(status: ItemStatus.inWardrobe)), isTrue);
      for (final s in [
        ItemStatus.laundry,
        ItemStatus.lent,
        ItemStatus.stored,
        ItemStatus.donated,
        ItemStatus.deleted,
      ]) {
        expect(passesAvailability(makeItem(status: s)), isFalse, reason: '$s');
      }
    });
  });

  group('applyLayer1Filters — happy path', () {
    test('returns items passing all three filters, no empty-pool message', () {
      final keep = makeItem(
        id: 'keep',
        occasionTags: [Occasion.casual],
        condition: 4,
        status: ItemStatus.inWardrobe,
      );
      final wrongOccasion = makeItem(
        id: 'wrong',
        occasionTags: [Occasion.work],
        condition: 4,
        status: ItemStatus.inWardrobe,
      );
      final wornOut = makeItem(
        id: 'worn',
        occasionTags: [Occasion.casual],
        condition: 1,
        status: ItemStatus.inWardrobe,
      );
      final inLaundry = makeItem(
        id: 'laundry',
        occasionTags: [Occasion.casual],
        condition: 4,
        status: ItemStatus.laundry,
      );
      final result = applyLayer1Filters(
        [keep, wrongOccasion, wornOut, inLaundry],
        occasion: Occasion.casual,
      );
      expect(result.pool.map((i) => i.id), ['keep']);
      expect(result.isEmpty, isFalse);
      expect(result.emptyReason, isNull);
      expect(result.message, isNull);
    });
  });

  group('applyLayer1Filters — empty pool guard message priority', () {
    test('empty after F2 → no occasion match', () {
      final result = applyLayer1Filters(
        [makeItem(occasionTags: [Occasion.casual], condition: 4)],
        occasion: Occasion.work,
      );
      expect(result.isEmpty, isTrue);
      expect(result.emptyReason, EmptyPoolReason.noOccasionMatch);
      expect(result.message, contains('No items match this occasion'));
    });

    test('passes F2 but empty after F3 → all worn out', () {
      final result = applyLayer1Filters(
        [makeItem(occasionTags: [Occasion.casual], condition: 1)],
        occasion: Occasion.casual,
      );
      expect(result.emptyReason, EmptyPoolReason.allWornOut);
      expect(result.message, contains('too worn out'));
    });

    test('passes F2+F3 but empty after F4 → all unavailable', () {
      final result = applyLayer1Filters(
        [
          makeItem(
            occasionTags: [Occasion.casual],
            condition: 4,
            status: ItemStatus.laundry,
          )
        ],
        occasion: Occasion.casual,
      );
      expect(result.emptyReason, EmptyPoolReason.allUnavailable);
      expect(result.message, contains('currently unavailable'));
    });

    test('empty input list → treated as no occasion match (F2)', () {
      final result = applyLayer1Filters(const [], occasion: Occasion.casual);
      expect(result.isEmpty, isTrue);
      expect(result.emptyReason, EmptyPoolReason.noOccasionMatch);
    });
  });

  group('F5 worn-today gate (authored, DECISIONS G2)', () {
    final now = DateTime(2026, 6, 1, 14, 30); // mid-afternoon

    test('predicate: item worn earlier today is excluded', () {
      final wornToday = makeItem(lastWornDate: DateTime(2026, 6, 1, 8));
      final wornYesterday = makeItem(lastWornDate: DateTime(2026, 5, 31, 23));
      final neverWorn = makeItem(lastWornDate: null);
      final unknown = makeItem(
          lastWornUnknown: true, lastWornDate: DateTime(2026, 6, 1, 8));
      expect(passesWornToday(wornToday, now), isFalse);
      expect(passesWornToday(wornYesterday, now), isTrue);
      expect(passesWornToday(neverWorn, now), isTrue);
      expect(passesWornToday(unknown, now), isTrue);
    });

    test('without [now] the worn-today gate is not applied (pure filter)', () {
      final wornToday = makeItem(
        occasionTags: [Occasion.casual],
        condition: 4,
        lastWornDate: DateTime(2026, 6, 1, 8),
      );
      final result =
          applyLayer1Filters([wornToday], occasion: Occasion.casual);
      expect(result.pool.map((i) => i.id), [wornToday.id]);
    });

    test('with [now], items worn today are dropped from the pool', () {
      final fresh = makeItem(
        id: 'fresh',
        occasionTags: [Occasion.casual],
        condition: 4,
        lastWornDate: DateTime(2026, 5, 20),
      );
      final wornToday = makeItem(
        id: 'wornToday',
        occasionTags: [Occasion.casual],
        condition: 4,
        lastWornDate: DateTime(2026, 6, 1, 8),
      );
      final result = applyLayer1Filters(
        [fresh, wornToday],
        occasion: Occasion.casual,
        now: now,
      );
      expect(result.pool.map((i) => i.id), ['fresh']);
    });

    test('pool empties only at F5 → allWornToday reason', () {
      final wornToday = makeItem(
        occasionTags: [Occasion.casual],
        condition: 4,
        lastWornDate: DateTime(2026, 6, 1, 8),
      );
      final result = applyLayer1Filters(
        [wornToday],
        occasion: Occasion.casual,
        now: now,
      );
      expect(result.isEmpty, isTrue);
      expect(result.emptyReason, EmptyPoolReason.allWornToday);
      expect(result.message, contains('today'));
    });
  });
}
