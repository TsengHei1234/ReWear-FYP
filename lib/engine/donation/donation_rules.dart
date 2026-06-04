import '../../core/constants/enums.dart';
import '../../data/models/item.dart';

/// Donation Decision Support (RE "Donation Decision Support"). Pure Dart.
/// Decision support only — the user makes all final decisions.

/// The five donation eligibility rules.
enum DonationRule {
  d1LongUnused,
  d2NeverWornOld,
  d3FrequentlySkipped,
  d4PoorCondition,
  d5WornUnused,
}

extension DonationRuleMessage on DonationRule {
  String get message => switch (this) {
        DonationRule.d1LongUnused => 'Not worn in 3+ months',
        DonationRule.d2NeverWornOld => 'Added 3+ months ago, never worn',
        DonationRule.d3FrequentlySkipped => 'You keep skipping this item',
        DonationRule.d4PoorCondition =>
          'Worn out — consider disposal, not donation',
        DonationRule.d5WornUnused =>
          'This item is showing wear and hasn\'t been used in 2+ months',
      };
}

/// Candidate strength tier.
enum DonationTier { worthReviewing, strongCandidate }

/// The donation assessment for one item.
class DonationAssessment {
  const DonationAssessment(this.rules);

  final List<DonationRule> rules;

  bool get isCandidate => rules.isNotEmpty;

  List<String> get messages => rules.map((r) => r.message).toList();

  DonationTier? get tier {
    if (rules.isEmpty) return null;
    return rules.length >= 2
        ? DonationTier.strongCandidate
        : DonationTier.worthReviewing;
  }
}

/// Evaluates D1–D5 for [item]. Returns an empty assessment when the item is
/// DELETED/DONATED or suppressed by a future kept_until.
DonationAssessment evaluateDonationRules(Item item, {required DateTime now}) {
  // Pre-check: never a candidate.
  if (item.status == ItemStatus.donated ||
      item.status == ItemStatus.deleted) {
    return const DonationAssessment([]);
  }
  if (item.keptUntil != null && item.keptUntil!.isAfter(now)) {
    return const DonationAssessment([]);
  }

  final daysSinceAdded = now.difference(item.dateAdded).inDays;
  final daysSinceWorn = item.lastWornDate == null
      ? null
      : now.difference(item.lastWornDate!).inDays;

  final rules = <DonationRule>[];

  // D1 — Long-term unused.
  if (item.wearCount > 0 && daysSinceWorn != null && daysSinceWorn >= 90) {
    rules.add(DonationRule.d1LongUnused);
  }

  // D2 — Never worn old item (fires regardless of is_new_item).
  if (item.wearCount == 0 && daysSinceAdded > 90) {
    rules.add(DonationRule.d2NeverWornOld);
  }

  // D3 — Frequently skipped (raw skip ratio, guarded).
  final totalInteractions = item.wearCount + item.skipCount;
  final rawSkipRatio =
      totalInteractions == 0 ? 0.0 : item.skipCount / totalInteractions;
  if (item.skipCount >= 10 && rawSkipRatio > 0.75) {
    rules.add(DonationRule.d3FrequentlySkipped);
  }

  // D4 — Poor condition.
  if (item.condition == 1) {
    rules.add(DonationRule.d4PoorCondition);
  }

  // D5 — Worn condition unused.
  if (item.wearCount > 0 &&
      item.condition == 2 &&
      daysSinceWorn != null &&
      daysSinceWorn >= 60) {
    rules.add(DonationRule.d5WornUnused);
  }

  return DonationAssessment(rules);
}

/// Convenience: does any donation rule fire? (used by badge_engine P2).
bool isDonationCandidate(Item item, {required DateTime now}) =>
    evaluateDonationRules(item, now: now).isCandidate;

/// DPS — Donation Priority Score (RE). Ranks candidates; higher = more urgent.
double donationPriorityScore(Item item, {required DateTime now}) {
  final daysSinceAdded = now.difference(item.dateAdded).inDays;
  final neverWorn = item.lastWornDate == null;
  final days = neverWorn
      ? daysSinceAdded
      : now.difference(item.lastWornDate!).inDays;
  final daysNorm = (days / 365) < 1.0 ? (days / 365) : 1.0;

  final skipRatio = item.skipCount / (item.wearCount + item.skipCount + 1);
  final conditionScore = (5 - item.condition) / 4;

  return (0.50 * daysNorm) + (0.30 * skipRatio) + (0.20 * conditionScore);
}
