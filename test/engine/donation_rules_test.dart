import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/engine/donation/donation_rules.dart';

import 'support/item_factory.dart';

void main() {
  final now = DateTime(2026, 6, 1);

  group('D1–D5 eligibility', () {
    test('D1 long-term unused', () {
      final item = makeItem(
        wearCount: 5,
        lastWornDate: now.subtract(const Duration(days: 100)),
        dateAdded: now.subtract(const Duration(days: 200)),
      );
      final r = evaluateDonationRules(item, now: now);
      expect(r.rules, contains(DonationRule.d1LongUnused));
      expect(r.messages, contains('Not worn in 3+ months'));
    });

    test('D2 never worn old item (any is_new_item)', () {
      final item = makeItem(
        wearCount: 0,
        lastWornDate: null,
        isNewItem: false,
        dateAdded: now.subtract(const Duration(days: 100)),
      );
      expect(evaluateDonationRules(item, now: now).rules,
          contains(DonationRule.d2NeverWornOld));
    });

    test('D3 frequently skipped (skip>=10 AND raw ratio>0.75)', () {
      final item = makeItem(wearCount: 2, skipCount: 12);
      expect(evaluateDonationRules(item, now: now).rules,
          contains(DonationRule.d3FrequentlySkipped));
    });

    test('D3 does NOT fire below 10 skips even with high ratio', () {
      final item = makeItem(wearCount: 0, skipCount: 8);
      expect(evaluateDonationRules(item, now: now).rules,
          isNot(contains(DonationRule.d3FrequentlySkipped)));
    });

    test('D4 poor condition', () {
      final item = makeItem(condition: 1);
      expect(evaluateDonationRules(item, now: now).rules,
          contains(DonationRule.d4PoorCondition));
    });

    test('D5 worn condition unused', () {
      final item = makeItem(
        wearCount: 3,
        condition: 2,
        lastWornDate: now.subtract(const Duration(days: 70)),
        dateAdded: now.subtract(const Duration(days: 200)),
      );
      expect(evaluateDonationRules(item, now: now).rules,
          contains(DonationRule.d5WornUnused));
    });
  });

  group('pre-check suppression', () {
    test('kept_until in future suppresses all rules', () {
      final item = makeItem(
        condition: 1, // would be D4
        keptUntil: now.add(const Duration(days: 30)),
      );
      expect(evaluateDonationRules(item, now: now).rules, isEmpty);
    });

    test('DONATED / DELETED are not candidates', () {
      final donated = makeItem(condition: 1, status: ItemStatus.donated);
      final deleted = makeItem(condition: 1, status: ItemStatus.deleted);
      expect(evaluateDonationRules(donated, now: now).rules, isEmpty);
      expect(evaluateDonationRules(deleted, now: now).rules, isEmpty);
    });
  });

  group('tier + isDonationCandidate', () {
    test('one rule → Worth Reviewing', () {
      // recent dateAdded + worn recently so only D4 (condition 1) fires
      final item = makeItem(
        condition: 1,
        wearCount: 2,
        lastWornDate: now.subtract(const Duration(days: 5)),
        dateAdded: now.subtract(const Duration(days: 30)),
      );
      final r = evaluateDonationRules(item, now: now);
      expect(r.tier, DonationTier.worthReviewing);
      expect(r.isCandidate, isTrue);
    });

    test('two rules → Strong Candidate', () {
      // D4 (condition 1) + D1 (worn, 100 days unused)
      final item = makeItem(
        condition: 1,
        wearCount: 5,
        lastWornDate: now.subtract(const Duration(days: 100)),
        dateAdded: now.subtract(const Duration(days: 200)),
      );
      final r = evaluateDonationRules(item, now: now);
      expect(r.rules.length, greaterThanOrEqualTo(2));
      expect(r.tier, DonationTier.strongCandidate);
    });

    test('no rules → not a candidate, null tier', () {
      final item = makeItem(
        wearCount: 5,
        condition: 5,
        lastWornDate: now.subtract(const Duration(days: 5)),
        dateAdded: now.subtract(const Duration(days: 30)),
      );
      final r = evaluateDonationRules(item, now: now);
      expect(r.isCandidate, isFalse);
      expect(r.tier, isNull);
    });

    test('isDonationCandidate convenience matches', () {
      final flagged = makeItem(
        condition: 1,
        wearCount: 2,
        lastWornDate: now.subtract(const Duration(days: 5)),
        dateAdded: now.subtract(const Duration(days: 30)),
      );
      final healthy = makeItem(
        condition: 5,
        wearCount: 5,
        lastWornDate: now.subtract(const Duration(days: 5)),
        dateAdded: now.subtract(const Duration(days: 30)),
      );
      expect(isDonationCandidate(flagged, now: now), isTrue);
      expect(isDonationCandidate(healthy, now: now), isFalse);
    });
  });

  group('DPS — Donation Priority Score', () {
    test('never worn, 365d in app, pristine → 0.50', () {
      final item = makeItem(
        wearCount: 0,
        lastWornDate: null,
        skipCount: 0,
        condition: 5,
        dateAdded: now.subtract(const Duration(days: 365)),
      );
      expect(donationPriorityScore(item, now: now), closeTo(0.50, 1e-9));
    });

    test('worn 365d ago, no skips, condition 1 → 0.70', () {
      final item = makeItem(
        wearCount: 4,
        skipCount: 0,
        condition: 1,
        lastWornDate: now.subtract(const Duration(days: 365)),
        dateAdded: now.subtract(const Duration(days: 400)),
      );
      // days_norm=1.0, skip_ratio=0, condition_score=(5-1)/4=1.0
      // 0.5*1 + 0.3*0 + 0.2*1 = 0.70
      expect(donationPriorityScore(item, now: now), closeTo(0.70, 1e-9));
    });

    test('days_norm caps at 1.0 beyond a year', () {
      final item = makeItem(
        wearCount: 1,
        skipCount: 0,
        condition: 5,
        lastWornDate: now.subtract(const Duration(days: 800)),
        dateAdded: now.subtract(const Duration(days: 900)),
      );
      // days_norm=1.0 → DPS = 0.5
      expect(donationPriorityScore(item, now: now), closeTo(0.50, 1e-9));
    });
  });
}
