import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/enums.dart';
import 'wardrobe_providers.dart';

/// Item ids skipped via **Daily Rotation today** (DECISIONS G3).
///
/// Day-scoped + DB-backed: derived from today's `SKIPPED` `item_events` with
/// `source == DAILY_ROTATION`, so it survives an app restart and resets at
/// midnight. Daily Rotation hides these for the rest of the day; the Outfit
/// Generator is unaffected (generator skips are session-scoped only).
final dailyRotationSkippedTodayProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  ref.watch(wardrobeProvider); // re-fetch after a skip writes an event
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return {};

  final now = DateTime.now();
  final dayStart = DateTime(now.year, now.month, now.day);
  final dayEnd = dayStart.add(const Duration(days: 1));

  final events = await ref.read(itemEventRepositoryProvider).getEventsInRange(
        userId: userId,
        from: dayStart,
        to: dayEnd,
      );
  return events
      .where((e) =>
          e.eventType == EventType.skipped &&
          e.source == ItemEventSource.dailyRotation)
      .map((e) => e.itemId)
      .toSet();
});
