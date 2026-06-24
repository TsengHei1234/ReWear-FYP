import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/engine/condition/condition_engine.dart';

import 'support/item_factory.dart';

/// Tests for [resolveConditionNextDropOnEdit] — the edit-save rule that
/// preserves an AUTO item's drop schedule unless something relevant changed
/// (Stage 3 BUG-2). T_SHIRT threshold = 28, JEANS threshold = 58.
void main() {
  group('resolveConditionNextDropOnEdit', () {
    test('unrelated edit preserves existing condition_next_drop', () {
      // AUTO T-shirt, next drop at wear 28, currently worn 12 times, user
      // edits only the name/colour → schedule must stay at 28.
      final result = resolveConditionNextDropOnEdit(
        newMode: ConditionReviewMode.auto,
        newCondition: 5,
        newType: 'T_SHIRT',
        wearCount: 12,
        existingMode: ConditionReviewMode.auto,
        existingCondition: 5,
        existingType: 'T_SHIRT',
        existingNextDrop: 28,
      );
      expect(result, 28);
    });

    test('type/category threshold change recomputes to wear_count + new threshold', () {
      // T_SHIRT (28) → JEANS (58), worn 12 times.
      final result = resolveConditionNextDropOnEdit(
        newMode: ConditionReviewMode.auto,
        newCondition: 5,
        newType: 'JEANS',
        wearCount: 12,
        existingMode: ConditionReviewMode.auto,
        existingCondition: 5,
        existingType: 'T_SHIRT',
        existingNextDrop: 28,
      );
      expect(result, 12 + 58);
    });

    test('condition change recomputes to wear_count + threshold', () {
      final result = resolveConditionNextDropOnEdit(
        newMode: ConditionReviewMode.auto,
        newCondition: 4,
        newType: 'T_SHIRT',
        wearCount: 12,
        existingMode: ConditionReviewMode.auto,
        existingCondition: 5,
        existingType: 'T_SHIRT',
        existingNextDrop: 28,
      );
      expect(result, 12 + 28);
    });

    test('switching to MANUAL returns null', () {
      final result = resolveConditionNextDropOnEdit(
        newMode: ConditionReviewMode.manual,
        newCondition: 5,
        newType: 'T_SHIRT',
        wearCount: 12,
        existingMode: ConditionReviewMode.auto,
        existingCondition: 5,
        existingType: 'T_SHIRT',
        existingNextDrop: 28,
      );
      expect(result, isNull);
    });

    test('switching from MANUAL to AUTO recomputes to wear_count + threshold', () {
      final result = resolveConditionNextDropOnEdit(
        newMode: ConditionReviewMode.auto,
        newCondition: 5,
        newType: 'T_SHIRT',
        wearCount: 12,
        existingMode: ConditionReviewMode.manual,
        existingCondition: 5,
        existingType: 'T_SHIRT',
        existingNextDrop: null,
      );
      expect(result, 12 + 28);
    });

    test('condition == 1 returns null even when nothing else changed', () {
      final result = resolveConditionNextDropOnEdit(
        newMode: ConditionReviewMode.auto,
        newCondition: 1,
        newType: 'T_SHIRT',
        wearCount: 12,
        existingMode: ConditionReviewMode.auto,
        existingCondition: 1,
        existingType: 'T_SHIRT',
        existingNextDrop: null,
      );
      expect(result, isNull);
    });
  });

  group('checkAutoConditionDrop', () {
    test('drops condition and advances next_drop when wear_count reaches '
        'threshold', () {
      // AUTO T-shirt (threshold 28), condition 5, worn exactly 28 times.
      final item = makeItem(
        conditionReviewMode: ConditionReviewMode.auto,
        type: 'T_SHIRT',
        condition: 5,
        wearCount: 28,
        conditionNextDrop: 28,
      );
      final dropped = checkAutoConditionDrop(item);
      expect(dropped.condition, 4);
      expect(dropped.conditionNextDrop, 28 + 28); // wear_count + threshold
    });

    test('sets condition_next_drop to null when condition reaches 1', () {
      // AUTO T-shirt, condition 2 → dropping reaches the floor.
      final item = makeItem(
        conditionReviewMode: ConditionReviewMode.auto,
        type: 'T_SHIRT',
        condition: 2,
        wearCount: 28,
        conditionNextDrop: 28,
      );
      final dropped = checkAutoConditionDrop(item);
      expect(dropped.condition, 1);
      expect(dropped.conditionNextDrop, isNull);
    });

    test('MANUAL item never auto-drops', () {
      final item = makeItem(
        conditionReviewMode: ConditionReviewMode.manual,
        type: 'T_SHIRT',
        condition: 5,
        wearCount: 100,
        conditionNextDrop: 28,
      );
      final result = checkAutoConditionDrop(item);
      expect(result.condition, 5);
      expect(identical(result, item), isTrue);
    });

    test('no drop when wear_count is below next_drop', () {
      final item = makeItem(
        conditionReviewMode: ConditionReviewMode.auto,
        type: 'T_SHIRT',
        condition: 5,
        wearCount: 27,
        conditionNextDrop: 28,
      );
      final result = checkAutoConditionDrop(item);
      expect(result.condition, 5);
      expect(result.conditionNextDrop, 28);
    });
  });

  group('computeConditionNextDrop (on add)', () {
    test('AUTO, condition > 1 → wear_count + threshold', () {
      expect(
        computeConditionNextDrop(makeItem(
          conditionReviewMode: ConditionReviewMode.auto,
          type: 'T_SHIRT',
          condition: 5,
          wearCount: 0,
        )),
        28,
      );
      expect(
        computeConditionNextDrop(makeItem(
          conditionReviewMode: ConditionReviewMode.auto,
          type: 'JEANS',
          condition: 5,
          wearCount: 10,
        )),
        10 + 58,
      );
    });

    test('null for MANUAL or condition == 1', () {
      expect(
        computeConditionNextDrop(makeItem(
          conditionReviewMode: ConditionReviewMode.manual,
          type: 'T_SHIRT',
          condition: 5,
        )),
        isNull,
      );
      expect(
        computeConditionNextDrop(makeItem(
          conditionReviewMode: ConditionReviewMode.auto,
          type: 'T_SHIRT',
          condition: 1,
        )),
        isNull,
      );
    });
  });
}
