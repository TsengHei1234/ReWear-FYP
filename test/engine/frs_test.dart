import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/engine/scoring/frs.dart';

import 'support/item_factory.dart';

void main() {
  group('finalRecommendationScore — weighting', () {
    test('Mode A combines all five weighted scores', () {
      // 0.35*0.5 + 0.25*1.0 + 0.20*1.0 + 0.20*0.70 + 0.15*1.0 = 0.915
      final frs = finalRecommendationScore(
        tds: 0.50,
        wfss: 1.0,
        sps: 1.0,
        ps: 0.70,
        nibs: 1.0,
        mode: RecommendationMode.balanced,
      );
      expect(frs, closeTo(0.915, 1e-9));
    });

    test('Mode B ignores PS', () {
      // 0.45*0.5 + 0.30*1.0 + 0.25*1.0 + 0.15*1.0 = 0.925
      final frs = finalRecommendationScore(
        tds: 0.50,
        wfss: 1.0,
        sps: 1.0,
        ps: 0.70, // must be ignored
        nibs: 1.0,
        mode: RecommendationMode.pureRotation,
      );
      expect(frs, closeTo(0.925, 1e-9));
    });

    test('max FRS = 1.15 when everything is 1.0 (NIBS additive bonus)', () {
      final frs = finalRecommendationScore(
        tds: 1.0,
        wfss: 1.0,
        sps: 1.0,
        ps: 1.0,
        nibs: 1.0,
        mode: RecommendationMode.balanced,
      );
      expect(frs, closeTo(1.15, 1e-9));
    });
  });

  group('scoreItem — wires all sub-scores', () {
    final now = DateTime(2026, 6, 1);

    test('brand new day-0 item (Mode B)', () {
      final item = makeItem(
        isNewItem: true,
        wearCount: 0,
        skipCount: 0,
        dateAdded: now,
      );
      final s = scoreItem(
        item,
        categoryActiveCount: 10,
        now: now,
        mode: RecommendationMode.pureRotation,
        preferredColours: const {},
        dislikedColours: const {},
      );
      // tds=0.50 (NIBS window), wfss=1.0, sps=1.0, nibs=1.0
      expect(s.tds, 0.50);
      expect(s.wfss, 1.0);
      expect(s.sps, 1.0);
      expect(s.nibs, 1.0);
      // Mode B FRS = 0.45*0.5 + 0.30*1 + 0.25*1 + 0.15*1 = 0.925
      expect(s.frs, closeTo(0.925, 1e-9));
    });
  });

  group('rankByFrs — tiebreaker', () {
    final now = DateTime(2026, 6, 1);

    test('equal FRS: never-worn item ranks before a recently worn one', () {
      final neverWorn = makeItem(
        id: 'never',
        isNewItem: false,
        wearCount: 3,
        lastWornDate: null,
        dateAdded: now.subtract(const Duration(days: 100)),
      );
      final wornLongAgo = makeItem(
        id: 'worn',
        isNewItem: false,
        wearCount: 3,
        lastWornDate: now.subtract(const Duration(days: 95)),
        dateAdded: now.subtract(const Duration(days: 100)),
      );
      // Force equal FRS by scoring then ranking; both have same window.
      final scores = [
        scoreItem(wornLongAgo,
            categoryActiveCount: 10,
            now: now,
            mode: RecommendationMode.pureRotation,
            preferredColours: const {},
            dislikedColours: const {}),
        scoreItem(neverWorn,
            categoryActiveCount: 10,
            now: now,
            mode: RecommendationMode.pureRotation,
            preferredColours: const {},
            dislikedColours: const {}),
      ];
      final ranked = rankByFrs(scores, now: now);
      // never-worn (NULL last_worn) should come first on the tiebreaker
      expect(ranked.first.item.id, 'never');
    });

    test('equal FRS and both never worn: older dateAdded wins', () {
      final older = makeItem(
        id: 'older',
        isNewItem: false,
        wearCount: 0,
        lastWornUnknown: true, // forces TDS=0.50 for both → equal FRS
        lastWornDate: null,
        dateAdded: now.subtract(const Duration(days: 200)),
      );
      final newer = makeItem(
        id: 'newer',
        isNewItem: false,
        wearCount: 0,
        lastWornUnknown: true,
        lastWornDate: null,
        dateAdded: now.subtract(const Duration(days: 50)),
      );
      final scores = [
        scoreItem(newer,
            categoryActiveCount: 10,
            now: now,
            mode: RecommendationMode.pureRotation,
            preferredColours: const {},
            dislikedColours: const {}),
        scoreItem(older,
            categoryActiveCount: 10,
            now: now,
            mode: RecommendationMode.pureRotation,
            preferredColours: const {},
            dislikedColours: const {}),
      ];
      final ranked = rankByFrs(scores, now: now);
      expect(ranked.first.item.id, 'older');
    });
  });
}
