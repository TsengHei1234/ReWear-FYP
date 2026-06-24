import '../../core/constants/enums.dart';
import '../../core/constants/item_type_dictionary.dart';
import '../../data/models/item.dart';

/// Pure Dart — no Flutter/Supabase imports.
/// Source: Rule Engine "Condition Review Thresholds".

/// Returns the wears-per-drop threshold for the given type stored value.
/// Delegates to [ItemTypeDictionary] which already encodes the full table.
int conditionThreshold(String typeStoredValue) =>
    ItemTypeDictionary.conditionThreshold(typeStoredValue);

/// Computes [Item.conditionNextDrop] from scratch.
/// Returns null when condition == 1 or conditionReviewMode == MANUAL.
int? computeConditionNextDrop(Item item) {
  if (item.conditionReviewMode.value == 'MANUAL') return null;
  if (item.condition <= 1) return null;
  final threshold = conditionThreshold(item.type);
  return item.wearCount + threshold;
}

/// Checks whether [item] has crossed its AUTO drop threshold.
/// If so, returns a new [Item] with condition decremented and next_drop
/// advanced (or nulled when condition reaches 1).
///
/// Returns the SAME item (unchanged) if no drop applies.
/// Caller is responsible for persisting the returned item and firing N6.
Item checkAutoConditionDrop(Item item) {
  if (item.conditionReviewMode.value == 'MANUAL') return item;
  if (item.condition <= 1) return item;
  final nextDrop = item.conditionNextDrop;
  if (nextDrop == null) return item;
  if (item.wearCount < nextDrop) return item;

  final newCondition = item.condition - 1;
  final threshold = conditionThreshold(item.type);

  if (newCondition <= 1) {
    // Floor reached — no more drops; condition_next_drop must be NULL.
    return item.copyWith(condition: newCondition, clearConditionNextDrop: true);
  }

  return item.copyWith(
    condition: newCondition,
    conditionNextDrop: item.wearCount + threshold,
  );
}

/// Called when the user manually changes condition (AUTO mode).
/// Also called when switching mode AUTO→AUTO or MANUAL→AUTO.
int? recalcNextDropAfterManualConditionChange(Item item) =>
    computeConditionNextDrop(item);

/// Called when category or type changes on Edit Item — recalculates threshold.
int? recalcNextDropAfterTypeChange(Item item) =>
    computeConditionNextDrop(item);

/// Resolves `condition_next_drop` when an item is saved from Edit Item.
///
/// Source: Rule Engine "condition_next_drop logic". The existing absolute drop
/// schedule is **preserved** unless something that affects it changed, so an
/// unrelated edit (name/photo/colour/occasion/favourite) does NOT delay the
/// next AUTO condition drop:
///   - new mode == MANUAL → null
///   - new condition == 1 → null
///   - condition changed, or type/threshold changed, or mode went MANUAL→AUTO
///     → recompute `wear_count + new_threshold`
///   - otherwise → preserve [existingNextDrop]
int? resolveConditionNextDropOnEdit({
  required ConditionReviewMode newMode,
  required int newCondition,
  required String newType,
  required int wearCount,
  required ConditionReviewMode existingMode,
  required int existingCondition,
  required String existingType,
  required int? existingNextDrop,
}) {
  if (newMode == ConditionReviewMode.manual) return null;
  if (newCondition <= 1) return null;

  final conditionChanged = newCondition != existingCondition;
  final thresholdChanged = newType != existingType;
  final reactivatedAuto = existingMode == ConditionReviewMode.manual;

  if (conditionChanged || thresholdChanged || reactivatedAuto) {
    return wearCount + conditionThreshold(newType);
  }
  return existingNextDrop;
}
