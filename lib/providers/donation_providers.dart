import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/item.dart';
import '../engine/donation/donation_rules.dart';
import 'wardrobe_providers.dart';

/// Pairs an item with its donation assessment + priority score.
class DonationCandidateEntry {
  const DonationCandidateEntry({
    required this.item,
    required this.assessment,
    required this.dps,
  });

  final Item item;
  final DonationAssessment assessment;
  final double dps;
}

/// All current donation candidates, sorted by DPS descending (most urgent first).
/// Re-evaluates whenever the wardrobe changes. Source: RE "Donation Decision Support".
final donationCandidatesProvider =
    FutureProvider.autoDispose<List<DonationCandidateEntry>>((ref) async {
  final items = await ref.watch(wardrobeProvider.future);
  final now = DateTime.now();
  final candidates = <DonationCandidateEntry>[];
  for (final item in items) {
    final assessment = evaluateDonationRules(item, now: now);
    if (assessment.isCandidate) {
      candidates.add(DonationCandidateEntry(
        item: item,
        assessment: assessment,
        dps: donationPriorityScore(item, now: now),
      ));
    }
  }
  candidates.sort((a, b) => b.dps.compareTo(a.dps));
  return candidates;
});

/// Items currently deferred from donation (kept_until > now).
/// Sorted so soonest-returning items appear first; indefinite items last.
final keptItemsProvider =
    FutureProvider.autoDispose<List<Item>>((ref) async {
  final items = await ref.watch(wardrobeProvider.future);
  final now = DateTime.now();
  final kept = items
      .where((i) => i.keptUntil != null && i.keptUntil!.isAfter(now))
      .toList();
  kept.sort((a, b) {
    final aInfinite = a.keptUntil!.year >= 2099;
    final bInfinite = b.keptUntil!.year >= 2099;
    if (aInfinite && bInfinite) return 0;
    if (aInfinite) return 1; // indefinite after dated
    if (bInfinite) return -1;
    return a.keptUntil!.compareTo(b.keptUntil!);
  });
  return kept;
});

/// Items currently deferred from donation, for the Kept Items page.
/// Same pattern as donationHistoryProvider: watches wardrobeProvider (non-future)
/// as a refresh trigger, then makes a direct repository call.
final keptItemsPageProvider =
    FutureProvider.autoDispose<List<Item>>((ref) async {
  ref.watch(wardrobeProvider); // re-evaluate when wardrobe changes
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final items = await ref.read(itemRepositoryProvider).getKeptItems(userId);
  items.sort((a, b) {
    final aInfinite = a.keptUntil!.year >= 2099;
    final bInfinite = b.keptUntil!.year >= 2099;
    if (aInfinite && bInfinite) return 0;
    if (aInfinite) return 1; // indefinite after dated
    if (bInfinite) return -1;
    return a.keptUntil!.compareTo(b.keptUntil!);
  });
  return items;
});

/// All DONATED items, newest donation first.
/// Watches wardrobeProvider so a freshly confirmed donation refreshes the list.
final donationHistoryProvider =
    FutureProvider.autoDispose<List<Item>>((ref) async {
  ref.watch(wardrobeProvider); // re-fetch when wardrobe changes
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.read(itemRepositoryProvider).getDonatedItems(userId);
});
