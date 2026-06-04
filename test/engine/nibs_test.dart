import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/engine/scoring/nibs.dart';

import 'support/item_factory.dart';

void main() {
  final now = DateTime(2026, 6, 1);

  group('newItemBoostScore', () {
    test('new, unworn, within first 7 days → 1.0 full boost', () {
      final item = makeItem(
        isNewItem: true,
        wearCount: 0,
        dateAdded: now.subtract(const Duration(days: 5)),
      );
      expect(newItemBoostScore(item, now: now), 1.0);
    });

    test('exactly day 7 → 1.0', () {
      final item = makeItem(
        isNewItem: true,
        wearCount: 0,
        dateAdded: now.subtract(const Duration(days: 7)),
      );
      expect(newItemBoostScore(item, now: now), 1.0);
    });

    test('day 10 → (14-10)/7 = 4/7 taper', () {
      final item = makeItem(
        isNewItem: true,
        wearCount: 0,
        dateAdded: now.subtract(const Duration(days: 10)),
      );
      expect(newItemBoostScore(item, now: now), closeTo(4 / 7, 1e-9));
    });

    test('day 14 → 0.0 (taper end)', () {
      final item = makeItem(
        isNewItem: true,
        wearCount: 0,
        dateAdded: now.subtract(const Duration(days: 14)),
      );
      expect(newItemBoostScore(item, now: now), 0.0);
    });

    test('day 15 → 0.0 (grace expired)', () {
      final item = makeItem(
        isNewItem: true,
        wearCount: 0,
        dateAdded: now.subtract(const Duration(days: 15)),
      );
      expect(newItemBoostScore(item, now: now), 0.0);
    });

    test('worn once → 0.0 (permanently deactivated)', () {
      final item = makeItem(
        isNewItem: true,
        wearCount: 1,
        dateAdded: now.subtract(const Duration(days: 2)),
      );
      expect(newItemBoostScore(item, now: now), 0.0);
    });

    test('already-owned item (is_new_item false) → 0.0', () {
      final item = makeItem(
        isNewItem: false,
        wearCount: 0,
        dateAdded: now.subtract(const Duration(days: 2)),
      );
      expect(newItemBoostScore(item, now: now), 0.0);
    });
  });
}
