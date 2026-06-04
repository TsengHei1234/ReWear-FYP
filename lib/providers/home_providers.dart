import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/insights/health_score.dart';
import 'wardrobe_providers.dart';

/// Home "Wardrobe Snapshot" stats (FE §16 §3). Reuses the tested engine
/// `computeQuickStats` over the wardrobe + the last 30 days of events:
///   Utilisation = wornThisMonth / totalItems · Active Rotation = wornThisMonth ·
///   Dormant = totalItems − wornThisMonth · Donation review = donationCandidates.
final homeSnapshotProvider =
    FutureProvider.autoDispose<InsightsQuickStats?>((ref) async {
  final items = ref.watch(wardrobeProvider).asData?.value;
  if (items == null) return null;
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final now = DateTime.now();
  final events = await ref.read(itemEventRepositoryProvider).getEventsInRange(
        userId: userId,
        from: now.subtract(const Duration(days: 30)),
        to: now.add(const Duration(days: 1)),
      );
  return computeQuickStats(items, events, now: now);
});
