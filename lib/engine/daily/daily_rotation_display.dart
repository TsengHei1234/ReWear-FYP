import '../../core/constants/enums.dart';
import '../../data/models/item.dart';
import '../filters/layer1_filters.dart';
import '../scoring/frs.dart';

/// Daily Rotation — Backend Behaviour (RE). Recommends individual items.
/// Display labels are display-only and never affect data. Pure Dart.

/// Steps 1–4: Layer 1 filters, exclude OTHERS, FRS, sort descending.
List<ItemScore> rankDailyRotation(
  List<Item> wardrobe, {
  Occasion? occasion,
  required RecommendationMode mode,
  required DateTime now,
  Set<String> preferredColours = const {},
  Set<String> dislikedColours = const {},
}) {
  final filtered = applyLayer1Filters(wardrobe, occasion: occasion, now: now);
  final pool = filtered.pool.where((i) => i.category != ItemCategory.others);

  final scores = pool.map((item) {
    final activeCount = wardrobe
        .where((i) =>
            i.category == item.category && i.status == ItemStatus.inWardrobe)
        .length;
    return scoreItem(
      item,
      categoryActiveCount: activeCount,
      now: now,
      mode: mode,
      preferredColours: preferredColours,
      dislikedColours: dislikedColours,
    );
  }).toList();

  return rankByFrs(scores, now: now);
}

/// display_score = min(round(FRS × 100), 100).
int dailyRotationDisplayScore(double frs) {
  final scaled = (frs * 100).round();
  return scaled < 100 ? scaled : 100;
}

/// Priority label — the main recommendation reason.
String priorityLabel({required double nibs, required double tds}) {
  if (nibs > 0) return 'New Item';
  if (tds >= 0.70) return 'High Rotation Priority';
  if (tds >= 0.35) return 'Medium Rotation Priority';
  return 'Low Rotation Priority';
}

/// Factual recency label.
String lastWornLabel(Item item, {required DateTime now}) {
  if (item.lastWornUnknown) return 'Last worn unknown';
  if (item.lastWornDate == null) return 'Never worn';
  final d = now.difference(item.lastWornDate!).inDays;
  return 'Last worn: ${d}d ago';
}

/// Factual usage-pattern label (wear_rate = wear_count / max(days_since_added, 1)).
String wearStatusLabel(Item item, {required DateTime now}) {
  if (item.wearCountUnknown) return 'Usage unknown';
  if (item.wearCount == 0) return 'Never worn';
  final days = now.difference(item.dateAdded).inDays;
  final wearRate = item.wearCount / (days < 1 ? 1 : days);
  if (wearRate < 0.05) return 'Rarely worn';
  if (wearRate < 0.20) return 'Balanced wear';
  return 'Overused';
}

/// Factual wear-count label.
String wearCountLabel(Item item) {
  if (item.wearCountUnknown) return 'Wears unknown';
  if (item.wearCount == 1) return '1 wear';
  return '${item.wearCount} wears';
}
