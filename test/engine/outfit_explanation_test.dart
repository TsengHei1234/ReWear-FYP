import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/engine/outfit/outfit.dart';
import 'package:rewear/engine/outfit/outfit_assembler.dart';
import 'package:rewear/engine/outfit/outfit_explanation.dart';

import 'support/item_factory.dart';

void main() {
  Outfit twoItem({
    List<String> topColours = const ['white'],
    List<String> bottomColours = const ['navy'],
  }) =>
      Outfit(
        top: makeItem(id: 't', category: ItemCategory.top, colorTags: topColours),
        bottom: makeItem(
            id: 'b', category: ItemCategory.bottom, colorTags: bottomColours),
      );

  FormalityResult fr({required bool matched}) => FormalityResult(
        outfit: twoItem(),
        matched: matched,
        loose: !matched,
      );

  Map<String, OutfitItemScores> scores({
    required double tds,
    required double sps,
    required double wfss,
    required double nibs,
  }) =>
      {
        't': OutfitItemScores(tds: tds, sps: sps, wfss: wfss, nibs: nibs),
        'b': OutfitItemScores(tds: tds, sps: sps, wfss: wfss, nibs: nibs),
      };

  group('rule breakdown badges', () {
    test('temporal decay bands', () {
      expect(temporalDecayBadge(0.65).badge, 'High Rotation');
      expect(temporalDecayBadge(0.35).badge, 'Medium Rotation');
      expect(temporalDecayBadge(0.34).badge, 'Low Rotation');
    });
    test('skip penalty bands', () {
      expect(skipPenaltyBadge(0.85).badge, 'Clear');
      expect(skipPenaltyBadge(0.60).badge, 'Minor Skips');
      expect(skipPenaltyBadge(0.59).badge, 'Penalty');
    });
    test('wear balance bands', () {
      expect(wearBalanceBadge(0.70).badge, 'Balanced');
      expect(wearBalanceBadge(0.40).badge, 'Moderate');
      expect(wearBalanceBadge(0.39).badge, 'Overused');
    });
    test('colour bands', () {
      expect(colourBadge(0.80).badge, 'Strong');
      expect(colourBadge(0.60).badge, 'Compatible');
      expect(colourBadge(0.40).badge, 'Weak');
      expect(colourBadge(0.39).badge, 'Fallback');
    });
    test('formality badge from result', () {
      expect(formalityBadge(fr(matched: true)).badge, 'Matched');
      expect(formalityBadge(fr(matched: false)).badge, 'Loose');
    });
  });

  group('score sentence', () {
    test('band + strongest suffix (strong rotation wins)', () {
      final e = buildOutfitExplanation(
        outfit: twoItem(),
        scoresById: scores(tds: 0.90, sps: 0.90, wfss: 0.90, nibs: 0.0),
        formality: fr(matched: true),
        colourScore: 1.00,
        displayScore: 95,
      );
      expect(e.scoreMessage, 'Strong outfit with strong rotation priority.');
    });

    test('no positive suffix → band alone', () {
      final e = buildOutfitExplanation(
        outfit: twoItem(topColours: ['red'], bottomColours: ['green']),
        scoresById: scores(tds: 0.20, sps: 0.50, wfss: 0.30, nibs: 0.0),
        formality: fr(matched: false),
        colourScore: 0.30,
        displayScore: 45,
      );
      expect(e.scoreMessage, 'Backup outfit.');
    });

    test('never says Perfect even at 100', () {
      final e = buildOutfitExplanation(
        outfit: twoItem(),
        scoresById: scores(tds: 0.90, sps: 0.90, wfss: 0.90, nibs: 0.0),
        formality: fr(matched: true),
        colourScore: 1.00,
        displayScore: 100,
      );
      expect(e.scoreMessage, startsWith('Strong outfit'));
    });
  });

  group('why reasons', () {
    test('occasion All drops the occasion reason', () {
      final e = buildOutfitExplanation(
        outfit: twoItem(),
        scoresById: scores(tds: 0.90, sps: 0.90, wfss: 0.90, nibs: 0.0),
        formality: fr(matched: true),
        colourScore: 1.00,
        displayScore: 95,
        occasion: null,
      );
      expect(e.whyReasons.any((r) => r.contains('occasion')), isFalse);
    });

    test('pinned item reason is first', () {
      final pinned = makeItem(id: 'p', name: 'Blue Blazer');
      final e = buildOutfitExplanation(
        outfit: twoItem(),
        scoresById: scores(tds: 0.90, sps: 0.90, wfss: 0.90, nibs: 0.0),
        formality: fr(matched: true),
        colourScore: 1.00,
        displayScore: 95,
        pinnedItem: pinned,
      );
      expect(e.whyReasons.first, 'Built around Blue Blazer');
    });

    test('at most 4 reasons', () {
      final e = buildOutfitExplanation(
        outfit: twoItem(),
        scoresById: scores(tds: 0.90, sps: 0.90, wfss: 0.90, nibs: 0.5),
        formality: fr(matched: true),
        colourScore: 1.00,
        displayScore: 95,
        occasion: Occasion.casual,
      );
      expect(e.whyReasons.length, lessThanOrEqualTo(4));
    });

    test('fallback reason added when fewer than 2 match', () {
      final e = buildOutfitExplanation(
        outfit: twoItem(topColours: ['red'], bottomColours: ['green']),
        scoresById: scores(tds: 0.20, sps: 0.50, wfss: 0.30, nibs: 0.0),
        formality: fr(matched: false),
        colourScore: 0.30,
        displayScore: 45,
        occasion: null,
      );
      expect(
        e.whyReasons,
        contains('Recommended based on wardrobe rotation score'),
      );
    });
  });

  group('rule breakdown contents', () {
    test('always has 5 rows in fixed order', () {
      final e = buildOutfitExplanation(
        outfit: twoItem(),
        scoresById: scores(tds: 0.50, sps: 0.90, wfss: 0.80, nibs: 0.0),
        formality: fr(matched: true),
        colourScore: 0.90,
        displayScore: 80,
      );
      expect(e.ruleBreakdown.map((r) => r.name), [
        'Temporal Decay',
        'Skip Penalty',
        'Wear Balance',
        'Formality Match',
        'Colour Compatibility',
      ]);
    });
  });

  group('highlights (short card labels)', () {
    test('ordered by RE Why-priority (rotation → skip → balance)', () {
      final e = buildOutfitExplanation(
        outfit: twoItem(),
        scoresById: scores(tds: 0.90, sps: 0.90, wfss: 0.90, nibs: 0.0),
        formality: fr(matched: true),
        colourScore: 1.00,
        displayScore: 95,
        occasion: Occasion.casual,
      );
      expect(e.highlights, ['High Rotation', 'Low Skip Rate', 'Balanced Wear']);
    });

    test('New Item ranks first when an item is new (RE priority)', () {
      final e = buildOutfitExplanation(
        outfit: twoItem(),
        scoresById: scores(tds: 0.90, sps: 0.50, wfss: 0.30, nibs: 0.5),
        formality: fr(matched: false),
        colourScore: 0.30,
        displayScore: 60,
      );
      expect(e.highlights.first, 'New Item');
      expect(e.highlights, contains('High Rotation'));
    });

    test('always returns all 3 FRS labels even when all are bad', () {
      final e = buildOutfitExplanation(
        outfit: twoItem(),
        scoresById: scores(tds: 0.20, sps: 0.50, wfss: 0.30, nibs: 0.0),
        formality: fr(matched: false),
        colourScore: 0.30,
        displayScore: 45,
      );
      expect(e.highlights, ['Low Rotation', 'Penalty', 'Overused']);
    });

    test('always returns all 3 FRS labels when all are medium', () {
      final e = buildOutfitExplanation(
        outfit: twoItem(),
        scoresById: scores(tds: 0.50, sps: 0.70, wfss: 0.55, nibs: 0.0),
        formality: fr(matched: true),
        colourScore: 0.90,
        displayScore: 75,
      );
      expect(e.highlights, ['Medium Rotation', 'Minor Skips', 'Moderate']);
    });
  });
}
