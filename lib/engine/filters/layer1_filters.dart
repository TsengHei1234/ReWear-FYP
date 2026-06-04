import '../../core/constants/enums.dart';
import '../../data/models/item.dart';

/// Layer 1 — Filter Rules (RE "Layer 1 — Filter Rules"). Pure Dart.
/// Builds the recommendation pool. F1 Season is dropped from MVP.
/// Filtered-out items still appear on Donation/Insights — this only gates
/// recommendations.

/// F2 — Occasion. [occasion] == null means "All" (keep everything).
bool passesOccasion(Item item, Occasion? occasion) =>
    occasion == null || item.occasionTags.contains(occasion);

/// F3 — Condition gate. condition == 1 is removed (flagged for disposal review).
bool passesConditionGate(Item item) => item.condition >= 2;

/// F4 — Availability gate. Only IN_WARDROBE items are recommendable.
bool passesAvailability(Item item) => item.status == ItemStatus.inWardrobe;

/// F5 — Worn-today gate (authored, DECISIONS G2). An item already logged worn
/// today is not re-recommended for the rest of the day (worn count survives in
/// the DB; the gate auto-expires at midnight). Unknown/never-worn items pass.
bool passesWornToday(Item item, DateTime now) {
  final worn = item.lastWornDate;
  if (item.lastWornUnknown || worn == null) return true;
  return !(worn.year == now.year &&
      worn.month == now.month &&
      worn.day == now.day);
}

/// Why the recommendation pool came back empty (drives the UI message).
enum EmptyPoolReason {
  noOccasionMatch,
  allWornOut,
  allUnavailable,
  allWornToday,
}

extension EmptyPoolReasonMessage on EmptyPoolReason {
  String get message => switch (this) {
        EmptyPoolReason.noOccasionMatch =>
          'No items match this occasion. Try a different occasion or add more items.',
        EmptyPoolReason.allWornOut =>
          'All your items are too worn out to recommend. Update item condition or add new items.',
        EmptyPoolReason.allUnavailable =>
          'All your items are currently unavailable. Update item status to get suggestions.',
        EmptyPoolReason.allWornToday =>
          "You've already worn everything suitable today. Check back tomorrow.",
      };
}

/// Result of running Layer 1: the filtered pool plus an optional empty-pool
/// reason/message when nothing survived.
class Layer1Result {
  const Layer1Result({required this.pool, this.emptyReason});

  final List<Item> pool;
  final EmptyPoolReason? emptyReason;

  bool get isEmpty => pool.isEmpty;
  String? get message => emptyReason?.message;
}

/// Applies F2 → F3 → F4 → F5 and the Empty Pool Guard. When the pool is empty,
/// the reason reflects the FIRST step at which it emptied. F5 (worn-today) only
/// runs when [now] is supplied (the recommendation paths); pure filter callers
/// omit it and get F2–F4 only.
Layer1Result applyLayer1Filters(
  List<Item> items, {
  Occasion? occasion,
  DateTime? now,
}) {
  final afterF2 = items.where((i) => passesOccasion(i, occasion)).toList();
  final afterF3 = afterF2.where(passesConditionGate).toList();
  final afterF4 = afterF3.where(passesAvailability).toList();
  final afterF5 = now == null
      ? afterF4
      : afterF4.where((i) => passesWornToday(i, now)).toList();

  if (afterF5.isNotEmpty) {
    return Layer1Result(pool: afterF5);
  }

  final EmptyPoolReason reason;
  if (afterF2.isEmpty) {
    reason = EmptyPoolReason.noOccasionMatch;
  } else if (afterF3.isEmpty) {
    reason = EmptyPoolReason.allWornOut;
  } else if (afterF4.isEmpty) {
    reason = EmptyPoolReason.allUnavailable;
  } else {
    reason = EmptyPoolReason.allWornToday;
  }
  return Layer1Result(pool: const [], emptyReason: reason);
}
