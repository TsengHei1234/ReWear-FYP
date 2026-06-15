import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/services/notification_eligibility.dart';

void main() {
  const allOn = NotificationToggles(
    n1: true,
    n2: true,
    n3: true,
    n4: true,
    n5: true,
    n6: true,
  );
  final now = DateTime(2026, 6, 14, 10, 0);

  NotificationResult eval({
    int daysSince = 0,
    int longUnworn = 0,
    int donations = 0,
    bool conditionDropped = false,
    bool autoMode = false,
    NotificationToggles toggles = allOn,
    DateTime? lastN3,
    DateTime? lastN4,
  }) =>
      NotificationEligibility.evaluate(
        daysSinceLastLog: daysSince,
        longUnwornCount: longUnworn,
        donationCandidates: donations,
        conditionDropped: conditionDropped,
        isAutoConditionMode: autoMode,
        toggles: toggles,
        lastN3FiredAt: lastN3,
        lastN4FiredAt: lastN4,
        now: now,
      );

  group('N1 — daily reminder', () {
    test('fires when daysSinceLastLog == 1 and enabled', () {
      expect(eval(daysSince: 1).n1, isTrue);
    });

    test('does not fire when daysSinceLastLog is 0 (logged today)', () {
      expect(eval(daysSince: 0).n1, isFalse);
    });

    test('does not fire when daysSinceLastLog is 2', () {
      expect(eval(daysSince: 2).n1, isFalse);
    });

    test('does not fire when daysSinceLastLog >= 3 (N2 territory)', () {
      expect(eval(daysSince: 3).n1, isFalse);
      expect(eval(daysSince: 10).n1, isFalse);
    });

    test('does not fire when N1 toggle is off', () {
      expect(eval(daysSince: 1, toggles: allOn.copyWith(n1: false)).n1, isFalse);
    });
  });

  group('N2 — inactive warning', () {
    test('fires when daysSinceLastLog >= 3 and enabled', () {
      expect(eval(daysSince: 3).n2, isTrue);
      expect(eval(daysSince: 10).n2, isTrue);
    });

    test('does not fire when daysSinceLastLog < 3', () {
      expect(eval(daysSince: 0).n2, isFalse);
      expect(eval(daysSince: 1).n2, isFalse);
      expect(eval(daysSince: 2).n2, isFalse);
    });

    test('does not fire when N2 toggle is off', () {
      expect(eval(daysSince: 5, toggles: allOn.copyWith(n2: false)).n2, isFalse);
    });
  });

  group('N1/N2 mutual exclusion', () {
    test('N2 fires and N1 is suppressed when daysSinceLastLog >= 3', () {
      final r = eval(daysSince: 3);
      expect(r.n1, isFalse);
      expect(r.n2, isTrue);
    });

    test('N1 fires and N2 is suppressed when daysSinceLastLog == 1', () {
      final r = eval(daysSince: 1);
      expect(r.n1, isTrue);
      expect(r.n2, isFalse);
    });

    test('neither fires when daysSinceLastLog is 0', () {
      final r = eval(daysSince: 0);
      expect(r.n1, isFalse);
      expect(r.n2, isFalse);
    });

    test('neither fires when daysSinceLastLog is 2', () {
      final r = eval(daysSince: 2);
      expect(r.n1, isFalse);
      expect(r.n2, isFalse);
    });
  });

  group('N3 — long-unworn alert', () {
    test('fires when longUnwornCount > 0 and never fired before', () {
      expect(eval(longUnworn: 3).n3, isTrue);
    });

    test('does not fire when longUnwornCount is 0', () {
      expect(eval(longUnworn: 0).n3, isFalse);
    });

    test('suppressed when fired within last 7 days', () {
      final recent = now.subtract(const Duration(days: 6));
      expect(eval(longUnworn: 3, lastN3: recent).n3, isFalse);
    });

    test('fires again after more than 7 days since last fire', () {
      final old = now.subtract(const Duration(days: 8));
      expect(eval(longUnworn: 3, lastN3: old).n3, isTrue);
    });

    test('boundary: suppressed at exactly 7 days', () {
      final exactly7 = now.subtract(const Duration(days: 7));
      expect(eval(longUnworn: 3, lastN3: exactly7).n3, isFalse);
    });

    test('does not fire when N3 toggle is off', () {
      expect(eval(longUnworn: 5, toggles: allOn.copyWith(n3: false)).n3, isFalse);
    });
  });

  group('N4 — donation reminder', () {
    test('fires when donationCandidates > 0 and never fired before', () {
      expect(eval(donations: 2).n4, isTrue);
    });

    test('does not fire when donationCandidates is 0', () {
      expect(eval(donations: 0).n4, isFalse);
    });

    test('suppressed when fired within last 7 days', () {
      final recent = now.subtract(const Duration(days: 6));
      expect(eval(donations: 2, lastN4: recent).n4, isFalse);
    });

    test('fires again after more than 7 days since last fire', () {
      final old = now.subtract(const Duration(days: 8));
      expect(eval(donations: 2, lastN4: old).n4, isTrue);
    });

    test('boundary: suppressed at exactly 7 days', () {
      final exactly7 = now.subtract(const Duration(days: 7));
      expect(eval(donations: 2, lastN4: exactly7).n4, isFalse);
    });

    test('does not fire when N4 toggle is off', () {
      expect(eval(donations: 5, toggles: allOn.copyWith(n4: false)).n4, isFalse);
    });
  });

  group('N6 — condition update', () {
    test('fires when condition dropped in AUTO mode and enabled', () {
      expect(eval(conditionDropped: true, autoMode: true).n6, isTrue);
    });

    test('does not fire when condition review mode is MANUAL', () {
      expect(eval(conditionDropped: true, autoMode: false).n6, isFalse);
    });

    test('does not fire when no condition drop occurred', () {
      expect(eval(conditionDropped: false, autoMode: true).n6, isFalse);
    });

    test('does not fire when N6 toggle is off', () {
      expect(
        eval(
          conditionDropped: true,
          autoMode: true,
          toggles: allOn.copyWith(n6: false),
        ).n6,
        isFalse,
      );
    });
  });
}
