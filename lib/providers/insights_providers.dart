import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/enums.dart';
import '../data/models/item.dart';
import '../engine/insights/health_score.dart';
import 'wardrobe_providers.dart';

/// Identifies which attention list the View-All sub-page shows (FE §30).
enum InsightViewAllType {
  neverWorn,
  longUnused,
  skippedOften,
  overused,
  sleeping,
}

/// All Insights page data in one shot — health score, quick stats,
/// sub-score percentages, and the 5 attention lists.
class InsightsData {
  const InsightsData({
    required this.health,
    required this.stats,
    required this.utilisationPct,
    required this.rotationPct,
    required this.neverWornItems,
    required this.longUnusedItems,
    required this.skippedOftenItems,
    required this.overusedItems,
    required this.sleepingItems,
  });

  final WardrobeHealth health;
  final InsightsQuickStats stats;

  /// 0–100. Drives the Utilisation card progress bar + sub-score tile.
  final int utilisationPct;

  /// 0–100. Drives the Rotation sub-score tile.
  final int rotationPct;

  /// Attention tab — Never Worn (wear_count == 0, active items).
  final List<Item> neverWornItems;

  /// Attention tab — Long Unused (wear_count > 0, days_since_worn > 60).
  final List<Item> longUnusedItems;

  /// Attention tab — Skipped Often (skip_ratio > 0.50).
  final List<Item> skippedOftenItems;

  /// Attention tab — Overused (itemWearRate >= 0.20 AND wear_count >= 3
  /// [Phase 11 evidence floor], IN_WARDROBE only).
  final List<Item> overusedItems;

  /// Utilisation section "View All" + View-All sub-page (days_since_worn >= 90,
  /// wear_count > 0). Subset of longUnused but stricter threshold.
  final List<Item> sleepingItems;
}

/// Fetches health score + attention data for the Insights page.
/// Re-evaluates whenever the wardrobe changes.
/// Returns null when not logged in.
final insightsProvider = FutureProvider.autoDispose<InsightsData?>((ref) async {
  final items = await ref.watch(wardrobeProvider.future);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final now = DateTime.now();

  // 90-day window: enough to detect "< 5 total worn events" for partial flag
  // while keeping the query lightweight for MVP.
  final events = await ref.read(itemEventRepositoryProvider).getEventsInRange(
        userId: userId,
        from: now.subtract(const Duration(days: 90)),
        to: now.add(const Duration(days: 1)),
      );

  final health = computeWardrobeHealth(items, events, now: now);
  final stats = computeQuickStats(items, events, now: now);

  // Derive the utilisation% and rotation% sub-scores that the Health Score
  // card tiles show (mirrors the computation inside computeWardrobeHealth).
  final active = items
      .where((i) =>
          i.status != ItemStatus.donated && i.status != ItemStatus.deleted)
      .toList();

  int utilisationPct = 0;
  int rotationPct = 100;
  if (active.isNotEmpty) {
    final activeIds = active.map((i) => i.id).toSet();
    final cutoff = now.subtract(const Duration(days: 30));
    final wornLast30 = events
        .where((e) =>
            e.eventType == EventType.worn &&
            activeIds.contains(e.itemId) &&
            e.eventAt.isAfter(cutoff))
        .map((e) => e.itemId)
        .toSet()
        .length;

    utilisationPct =
        ((wornLast30 / active.length) * 100).round().clamp(0, 100);

    // Overused via the shared predicate (itemWearRate >= 0.20 AND
    // wear_count >= 3 [Phase 11 evidence floor], IN_WARDROBE only) so the
    // count matches computeWardrobeHealth + insights.
    final overusedCount = active.where((i) => isOverused(i, now: now)).length;
    rotationPct =
        ((1 - (overusedCount / active.length)) * 100).round().clamp(0, 100);
  }

  return InsightsData(
    health: health,
    stats: stats,
    utilisationPct: utilisationPct,
    rotationPct: rotationPct,
    neverWornItems: items.where(isNeverWorn).toList(),
    longUnusedItems: items.where((i) => isLongUnused(i, now: now)).toList(),
    skippedOftenItems: items.where(isSkippedOften).toList(),
    overusedItems: items.where((i) => isOverused(i, now: now)).toList(),
    sleepingItems: items.where((i) => isSleeping(i, now: now)).toList(),
  );
});
