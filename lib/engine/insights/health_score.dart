import '../../core/constants/enums.dart';
import '../../data/models/item.dart';
import '../../data/models/item_event.dart';
import '../donation/donation_rules.dart' as donation;

/// Insights — Health Score + quick stats + attention predicates (RE "Insights
/// — Health Score"). Pure Dart.

bool _isActive(Item i) =>
    i.status != ItemStatus.donated && i.status != ItemStatus.deleted;

int _daysSinceAdded(Item i, DateTime now) => now.difference(i.dateAdded).inDays;

double _wearRate(Item i, DateTime now) {
  final days = _daysSinceAdded(i, now);
  return i.wearCount / (days < 1 ? 1 : days);
}

int? _daysSinceWorn(Item i, DateTime now) =>
    i.lastWornDate == null ? null : now.difference(i.lastWornDate!).inDays;

double _rawSkipRatio(Item i) {
  final total = i.wearCount + i.skipCount;
  return total == 0 ? 0.0 : i.skipCount / total;
}

/// The computed wardrobe health result.
class WardrobeHealth {
  const WardrobeHealth({
    required this.hasItems,
    required this.partial,
    required this.score,
    required this.message,
  });

  final bool hasItems;
  final bool partial;
  final int score;
  final String message;

  /// The full verdict sentence for the current score (regardless of partial).
  String get verdict => healthVerdict(score);
}

/// Verdict sentence for a 0–100 score.
String healthVerdict(int score) {
  if (score >= 80) return 'Great job! Your wardrobe rotation is healthy.';
  if (score >= 60) return 'Good progress — a few items need more attention.';
  if (score >= 40) return 'Your wardrobe has room for better utilisation.';
  return 'Many items in your wardrobe are being neglected.';
}

/// Computes the wardrobe Health Score (RE).
WardrobeHealth computeWardrobeHealth(
  List<Item> items,
  List<ItemEvent> events, {
  required DateTime now,
}) {
  final active = items.where(_isActive).toList();
  if (active.isEmpty) {
    return const WardrobeHealth(
      hasItems: false,
      partial: false,
      score: 0,
      message: 'Add items to see your wardrobe health',
    );
  }

  final wornEvents = events.where((e) => e.eventType == EventType.worn).toList();
  final partial = wornEvents.length < 5;

  final activeIds = active.map((i) => i.id).toSet();
  final cutoff = now.subtract(const Duration(days: 30));
  final wornLast30 = wornEvents
      .where((e) => activeIds.contains(e.itemId) && e.eventAt.isAfter(cutoff))
      .map((e) => e.itemId)
      .toSet()
      .length;

  final utilisationRate = (wornLast30 / active.length).clamp(0.0, 1.0);
  final utilisationScore = utilisationRate * 100 * 0.50;

  final overused = active
      .where((i) =>
          i.status == ItemStatus.inWardrobe && _wearRate(i, now) >= 0.20)
      .length;
  final rotationScore = (1 - (overused / active.length)) * 100 * 0.50;

  final score = (utilisationScore + rotationScore).round();
  final message =
      partial ? 'Keep logging outfits to build your Health Score' : healthVerdict(score);

  return WardrobeHealth(
    hasItems: true,
    partial: partial,
    score: score,
    message: message,
  );
}

/// Insights quick stats.
class InsightsQuickStats {
  const InsightsQuickStats({
    required this.totalItems,
    required this.wornThisMonth,
    required this.neverWorn,
    required this.donationCandidates,
  });

  final int totalItems;
  final int wornThisMonth;
  final int neverWorn;
  final int donationCandidates;
}

InsightsQuickStats computeQuickStats(
  List<Item> items,
  List<ItemEvent> events, {
  required DateTime now,
}) {
  final active = items.where(_isActive).toList();
  final activeIds = active.map((i) => i.id).toSet();
  final cutoff = now.subtract(const Duration(days: 30));
  final wornThisMonth = events
      .where((e) =>
          e.eventType == EventType.worn &&
          activeIds.contains(e.itemId) &&
          e.eventAt.isAfter(cutoff))
      .map((e) => e.itemId)
      .toSet()
      .length;

  return InsightsQuickStats(
    totalItems: active.length,
    wornThisMonth: wornThisMonth,
    neverWorn: active.where((i) => i.wearCount == 0).length,
    donationCandidates:
        active.where((i) => donation.isDonationCandidate(i, now: now)).length,
  );
}

// ── Attention predicates (View-All filters) ─────────────────────────────────

bool isNeverWorn(Item i) => _isActive(i) && i.wearCount == 0;

bool isLongUnused(Item i, {required DateTime now}) {
  if (!_isActive(i) || i.wearCount == 0) return false;
  final d = _daysSinceWorn(i, now);
  return d != null && d > 60;
}

bool isSkippedOften(Item i) => _isActive(i) && _rawSkipRatio(i) > 0.50;

bool isOverused(Item i, {required DateTime now}) =>
    i.status == ItemStatus.inWardrobe && _wearRate(i, now) >= 0.20;

bool isSleeping(Item i, {required DateTime now}) {
  if (!_isActive(i) || i.wearCount == 0) return false;
  final d = _daysSinceWorn(i, now);
  return d != null && d >= 90;
}
