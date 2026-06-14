import '../../core/constants/enums.dart';
import '../../data/models/item.dart';
import '../donation/donation_rules.dart' as donation;
import '../insights/health_score.dart' as hs;

/// All possible badge types, in priority order.
/// Source: Rule Engine "Item Badge Labels" + FE §39.
enum BadgeType {
  wornOut,       // P1 — condition == 1
  donationReview, // P2 — flagged by any D1–D5 (donation_rules)
  overused,      // P3 — wear_rate >= 0.20
  skippedOften,  // P4 — skip_ratio > 0.50
  neverWorn,     // P5 — wear_count == 0 AND days_since_added > 14 (C1)
  longUnused,    // P6 — wear_count > 0 AND days_since_worn > 60
  isNew,         // P7 — is_new_item AND days_since_added <= 14
  mostWorn,      // P8 — top 10% by wear_count (M5)
}

/// Status overlay labels — shown as a greyed-out overlay, NOT badge chips.
enum StatusOverlay { inLaundry, lentOut, storedAway }

/// Returns status overlay label if the item has a non-active status.
StatusOverlay? statusOverlayFor(Item item) => switch (item.status) {
      ItemStatus.laundry => StatusOverlay.inLaundry,
      ItemStatus.lent => StatusOverlay.lentOut,
      ItemStatus.stored => StatusOverlay.storedAway,
      _ => null,
    };

/// Computes ALL matching badges for [item], ordered by priority (P1 first).
///
/// [allItems] is the full wardrobe list (used for Most Worn top-10%).
/// Excludes DELETED and DONATED items from all calculations.
///
/// On a wardrobe grid card: show badges[0] only (highest priority).
/// On Item Detail: show all badges.
///
/// [now] is injectable for deterministic tests; defaults to DateTime.now() for
/// UI convenience.
List<BadgeType> computeAllBadges(Item item, List<Item> allItems, {DateTime? now}) {
  if (item.status == ItemStatus.deleted || item.status == ItemStatus.donated) {
    return const [];
  }

  final effectiveNow = now ?? DateTime.now();
  final daysSinceAdded = effectiveNow.difference(item.dateAdded).inDays;
  final daysSinceWorn = item.lastWornDate != null
      ? effectiveNow.difference(item.lastWornDate!).inDays
      : null;

  final badges = <BadgeType>[];

  // P1 — Worn out
  if (item.condition == 1) badges.add(BadgeType.wornOut);

  // P2 — Donation review (any D1–D5 via donation_rules; respects kept_until)
  if (_isDonationCandidate(item, effectiveNow)) {
    badges.add(BadgeType.donationReview);
  }

  // P3 — Overused: uses shared itemWearRate() (initialUsageAgeDays + daysSinceAdded)
  if (hs.itemWearRate(item, effectiveNow) >= 0.20) badges.add(BadgeType.overused);

  // P4 — Skipped often: skip_ratio > 0.50 (strict RE — guarded raw ratio,
  // 0 when there are no interactions to avoid divide-by-zero).
  final totalInteractions = item.wearCount + item.skipCount;
  final skipRatio =
      totalInteractions == 0 ? 0.0 : item.skipCount / totalInteractions;
  if (skipRatio > 0.50) badges.add(BadgeType.skippedOften);

  // P5 — Never worn: wear_count == 0 AND effective age > 14 days.
  // Uses initialUsageAgeDays + daysSinceAdded so pre-owned unworn items get
  // the badge immediately rather than waiting 14 real-world days.
  final effectiveAge = item.initialUsageAgeDays + daysSinceAdded;
  if (item.wearCount == 0 && effectiveAge > 14) {
    badges.add(BadgeType.neverWorn);
  }

  // P6 — Long unused: wear_count > 0 AND days_since_worn > 60 (C9)
  if (item.wearCount > 0 && daysSinceWorn != null && daysSinceWorn > 60) {
    badges.add(BadgeType.longUnused);
  }

  // P7 — New: is_new_item AND days_since_added <= 14
  if (item.isNewItem && daysSinceAdded <= 14) badges.add(BadgeType.isNew);

  // P8 — Most worn: top 10% by wear_count (M5: ceil(0.10×N), min 1)
  if (_isMostWorn(item, allItems)) badges.add(BadgeType.mostWorn);

  return badges;
}

/// Convenience: highest-priority badge only (for grid cards).
BadgeType? primaryBadge(Item item, List<Item> allItems, {DateTime? now}) {
  final badges = computeAllBadges(item, allItems, now: now);
  return badges.isEmpty ? null : badges.first;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// D1–D5 donation flag (Phase 5: wired to donation_rules.dart).
/// donation.isDonationCandidate already handles kept_until suppression and
/// DELETED/DONATED exclusion.
bool _isDonationCandidate(Item item, DateTime now) =>
    donation.isDonationCandidate(item, now: now);

bool _isMostWorn(Item item, List<Item> allItems) {
  final eligible = allItems
      .where((i) =>
          i.status != ItemStatus.deleted && i.status != ItemStatus.donated)
      .toList();
  if (eligible.isEmpty) return false;
  final n = eligible.length;
  final threshold = (n * 0.10).ceil().clamp(1, n);
  final sorted = [...eligible]
    ..sort((a, b) => b.wearCount.compareTo(a.wearCount));
  final cutoff = sorted[threshold - 1].wearCount;
  return item.wearCount > 0 && item.wearCount >= cutoff;
}
