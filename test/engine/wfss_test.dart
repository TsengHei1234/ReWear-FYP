import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/engine/scoring/wfss.dart';

import 'support/item_factory.dart';

void main() {
  final now = DateTime(2026, 6, 1);

  group('wearFrequencySaturationScore', () {
    test('wear_count_unknown → 0.50 neutral fallback', () {
      final item = makeItem(wearCountUnknown: true, wearCount: 0);
      expect(wearFrequencySaturationScore(item, now: now), 0.50);
    });

    test('overused (wear_rate >= 0.20) → clamped to 0.10', () {
      // usage = max(10 + 0, 1) = 10; rate = 10/10 = 1.0 >= 0.20
      final item = makeItem(
        wearCount: 10,
        initialUsageAgeDays: 10,
        dateAdded: now,
      );
      expect(wearFrequencySaturationScore(item, now: now), 0.10);
    });

    test('rarely worn → 1.0 - (rate / 0.20)', () {
      // usage = max(0 + 100, 1) = 100; rate = 1/100 = 0.01; 1 - 0.05 = 0.95
      final item = makeItem(
        wearCount: 1,
        initialUsageAgeDays: 0,
        dateAdded: now.subtract(const Duration(days: 100)),
      );
      expect(
        wearFrequencySaturationScore(item, now: now),
        closeTo(0.95, 1e-9),
      );
    });

    test('brand new, day 0, never worn → 1.0 (max(...,1) guards div-by-zero)', () {
      final item = makeItem(wearCount: 0, initialUsageAgeDays: 0, dateAdded: now);
      expect(wearFrequencySaturationScore(item, now: now), 1.0);
    });

    test('"I don\'t remember" wear count, after a real wear → app-observed days only', () {
      // wearCountUnknown cleared after first logged wear, but the original
      // option is still recorded. Must NOT add initial_usage_age_days.
      // usage = max(10, 1) = 10; rate = 2/10 = 0.20 → overused → 0.10
      final item = makeItem(
        wearCount: 2,
        wearCountUnknown: false,
        initialWearCountOption: 'dontRemember',
        initialUsageAgeDays: 365,
        dateAdded: now.subtract(const Duration(days: 10)),
      );
      expect(wearFrequencySaturationScore(item, now: now), 0.10);
    });
  });
}
