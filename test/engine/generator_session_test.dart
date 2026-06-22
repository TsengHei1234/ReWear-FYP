import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/data/models/item.dart';
import 'package:rewear/engine/outfit/outfit.dart';
import 'package:rewear/engine/outfit/outfit_assembler.dart';
import 'package:rewear/engine/outfit/generator_session.dart';

import 'support/item_factory.dart';

void main() {
  final now = DateTime(2026, 6, 1);

  // Distinct last-worn dates so FRS ordering is deterministic.
  Item top(String id, {int formality = 2, List<String> colours = const ['white'], int daysAgo = 10}) =>
      makeItem(
        id: id,
        category: ItemCategory.top,
        type: 'T_SHIRT',
        formalityLevel: formality,
        colorTags: colours,
        occasionTags: const [Occasion.casual],
        condition: 4,
        isNewItem: false,
        wearCount: 3,
        lastWornDate: now.subtract(Duration(days: daysAgo)),
        dateAdded: now.subtract(const Duration(days: 100)),
      );
  Item bottom(String id, {int formality = 2, List<String> colours = const ['navy'], int daysAgo = 10}) =>
      makeItem(
        id: id,
        category: ItemCategory.bottom,
        type: 'JEANS',
        formalityLevel: formality,
        colorTags: colours,
        occasionTags: const [Occasion.casual],
        condition: 4,
        isNewItem: false,
        wearCount: 3,
        lastWornDate: now.subtract(Duration(days: daysAgo)),
        dateAdded: now.subtract(const Duration(days: 100)),
      );

  GeneratorConfig cfg({Item? pinned, bool outerwear = false, bool shoes = false}) =>
      GeneratorConfig(
        occasion: Occasion.casual,
        requireOuterwear: outerwear,
        requireShoes: shoes,
        pinnedItem: pinned,
        mode: RecommendationMode.pureRotation,
        now: now,
      );

  group('generate — basic', () {
    test('returns up to 3 outfits, each with a top and a bottom', () {
      final wardrobe = [
        top('t1', daysAgo: 30),
        top('t2', daysAgo: 20),
        top('t3', daysAgo: 10),
        bottom('b1', daysAgo: 30),
        bottom('b2', daysAgo: 20),
        bottom('b3', daysAgo: 10),
      ];
      final session = GeneratorSession();
      final result = session.generate(wardrobe, cfg());
      expect(result.ok, isTrue);
      expect(result.outfits.length, 3);
      for (final o in result.outfits) {
        expect(o.outfit.top.category, ItemCategory.top);
        expect(o.outfit.bottom.category, ItemCategory.bottom);
      }
    });

    test('T/B uniqueness ON (≥3 tops & bottoms): distinct tops & bottoms', () {
      final wardrobe = [
        top('t1', daysAgo: 30),
        top('t2', daysAgo: 20),
        top('t3', daysAgo: 10),
        bottom('b1', daysAgo: 30),
        bottom('b2', daysAgo: 20),
        bottom('b3', daysAgo: 10),
      ];
      final result = GeneratorSession().generate(wardrobe, cfg());
      final topIds = result.outfits.map((o) => o.outfit.top.id).toSet();
      final bottomIds = result.outfits.map((o) => o.outfit.bottom.id).toSet();
      expect(topIds.length, 3, reason: 'tops must be distinct');
      expect(bottomIds.length, 3, reason: 'bottoms must be distinct');
    });

    test('small wardrobe (2 tops, 2 bottoms): returns 1–3, no crash', () {
      final wardrobe = [
        top('t1', daysAgo: 20),
        top('t2', daysAgo: 10),
        bottom('b1', daysAgo: 20),
        bottom('b2', daysAgo: 10),
      ];
      final result = GeneratorSession().generate(wardrobe, cfg());
      expect(result.ok, isTrue);
      expect(result.outfits.length, inInclusiveRange(1, 3));
    });

    test('rejects colour clashes when three compatible outfits exist', () {
      final wardrobe = [
        top('clash-top', colours: const ['red'], daysAgo: 90),
        top('t2', colours: const ['white'], daysAgo: 2),
        top('t3', colours: const ['white'], daysAgo: 2),
        top('t4', colours: const ['white'], daysAgo: 2),
        bottom('clash-bottom', colours: const ['green'], daysAgo: 90),
        bottom('b2', colours: const ['navy'], daysAgo: 2),
        bottom('b3', colours: const ['navy'], daysAgo: 2),
        bottom('b4', colours: const ['navy'], daysAgo: 2),
      ];

      final result = GeneratorSession().generate(wardrobe, cfg());

      expect(result.ok, isTrue);
      expect(result.outfits, hasLength(3));
      expect(
        result.outfits.map((o) => o.colourScore),
        everyElement(greaterThanOrEqualTo(0.40)),
      );
    });

    test('drops a high-score clash with uniqueness OFF when 3+ compatible exist', () {
      // 2 tops → uniqueness OFF, so selection is pure score order. The red+green
      // clash (high FRS) would rank #2 by raw OutfitScore, but >=3 compatible
      // combos exist, so the colour rule must drop it.
      final wardrobe = [
        top('redTop', colours: const ['red'], daysAgo: 90),
        top('blueTop', colours: const ['blue'], daysAgo: 2),
        bottom('greenBottom', colours: const ['green'], daysAgo: 90),
        bottom('yellowBottom', colours: const ['yellow'], daysAgo: 2),
        bottom('pinkBottom', colours: const ['pink'], daysAgo: 2),
      ];

      final result = GeneratorSession().generate(wardrobe, cfg());

      expect(result.ok, isTrue);
      expect(
        result.outfits.map((o) => o.colourScore),
        everyElement(greaterThanOrEqualTo(0.40)),
      );
      // the red+green clash combination must not be present
      final hasClash = result.outfits.any((o) =>
          o.outfit.itemIds.contains('redTop') &&
          o.outfit.itemIds.contains('greenBottom'));
      expect(hasClash, isFalse);
    });

    test('allows best clash as fallback when fewer than 3 compatible exist', () {
      // Only red top + green bottom available → the single combo is a clash,
      // but with <3 compatible alternatives it is allowed as a fallback.
      final wardrobe = [
        top('redTop', colours: const ['red'], daysAgo: 30),
        bottom('greenBottom', colours: const ['green'], daysAgo: 30),
      ];

      final result = GeneratorSession().generate(wardrobe, cfg());

      expect(result.ok, isTrue);
      expect(result.outfits, hasLength(1));
      expect(result.outfits.first.colourScore, lessThan(0.40));
    });
  });

  group('P1D — tier-priority selection', () {
    test('T1≥3: loose (T3) outfit hidden even when its OutfitScore is higher', () {
      // tLo(formality=0, daysAgo=90) has very high FRS → its T3 outfit would
      // rank first by raw OutfitScore. P1D must suppress it when T1 ≥ 3.
      final wardrobe = [
        top('tLo', formality: 0, colours: const ['white'], daysAgo: 90),
        bottom('bHi', formality: 4, colours: const ['navy'], daysAgo: 10),
        top('t1', formality: 2, colours: const ['white'], daysAgo: 10),
        top('t2', formality: 2, colours: const ['white'], daysAgo: 10),
        top('t3', formality: 2, colours: const ['white'], daysAgo: 10),
        bottom('b1', formality: 2, colours: const ['navy'], daysAgo: 10),
        bottom('b2', formality: 2, colours: const ['navy'], daysAgo: 10),
      ];
      final result = GeneratorSession().generate(wardrobe, cfg());
      expect(result.ok, isTrue);
      expect(result.outfits, hasLength(3));
      expect(
        result.outfits.every((o) => o.formality.matched),
        isTrue,
        reason: 'T1≥3 → all displayed cards must be matched, even when a '
            'loose outfit has a higher OutfitScore',
      );
    });

    test('T2 (matched+weak colour) fills before T3 (loose+acceptable) when T1 is empty', () {
      // tClash(2,red)+bClash(2,green) = matched+red+green(0.30) → T2.
      // tLo×3(0,white)+bHi×3(4,navy) produce T3 loose outfits (white+green=0.90).
      // Old P1c would hide T2 because 3 "normal" (≥0.40) T3 outfits exist.
      // P1D must show T2 because matched formality outranks loose formality.
      final wardrobe = [
        top('tClash', formality: 2, colours: const ['red'], daysAgo: 10),
        top('tLo1', formality: 0, colours: const ['white'], daysAgo: 30),
        top('tLo2', formality: 0, colours: const ['white'], daysAgo: 25),
        top('tLo3', formality: 0, colours: const ['white'], daysAgo: 20),
        bottom('bClash', formality: 2, colours: const ['green'], daysAgo: 10),
        bottom('bHi1', formality: 4, colours: const ['navy'], daysAgo: 30),
        bottom('bHi2', formality: 4, colours: const ['navy'], daysAgo: 25),
        bottom('bHi3', formality: 4, colours: const ['navy'], daysAgo: 20),
      ];
      final result = GeneratorSession().generate(wardrobe, cfg());
      expect(result.ok, isTrue);
      expect(result.outfits, hasLength(3));
      expect(
        result.outfits.any((o) => o.formality.matched),
        isTrue,
        reason: 'P1D: matched+weak (T2) must appear before loose+acceptable (T3)',
      );
      expect(
        result.outfits.any((o) => o.formality.loose),
        isTrue,
        reason: 'T3 outfits fill remaining slots when T1+T2 < 3',
      );
    });

    test('generate() output is score-sorted descending', () {
      final wardrobe = [
        top('t1', daysAgo: 90),
        top('t2', daysAgo: 45),
        top('t3', daysAgo: 5),
        bottom('b1', daysAgo: 90),
        bottom('b2', daysAgo: 45),
        bottom('b3', daysAgo: 5),
      ];
      final result = GeneratorSession().generate(wardrobe, cfg());
      expect(result.ok, isTrue);
      expect(result.outfits, hasLength(3));
      final scores = result.outfits.map((o) => o.score).toList();
      for (var i = 0; i < scores.length - 1; i++) {
        expect(
          scores[i],
          greaterThanOrEqualTo(scores[i + 1]),
          reason: 'outfits[$i].score must be ≥ outfits[${i + 1}].score',
        );
      }
    });

    test('T2 fallback: matched+weak outfit shown when it is the only option', () {
      // Single red top (formality=2) + single green bottom (formality=2):
      // diff=0 → matched, red+green=0.30 → T2. Ensure P1D surfaces it.
      final wardrobe = [
        top('tRed', formality: 2, colours: const ['red'], daysAgo: 30),
        bottom('bGreen', formality: 2, colours: const ['green'], daysAgo: 30),
      ];
      final result = GeneratorSession().generate(wardrobe, cfg());
      expect(result.ok, isTrue);
      expect(result.outfits, hasLength(1));
      expect(result.outfits.first.formality.matched, isTrue);
      expect(result.outfits.first.colourScore, lessThan(0.40));
    });
  });

  group('generate — P1a failure', () {
    test('no bottoms → failure message', () {
      final wardrobe = [top('t1'), top('t2')];
      final result = GeneratorSession().generate(wardrobe, cfg());
      expect(result.ok, isFalse);
      expect(result.failureMessage, isNotNull);
    });

    test('shoes toggle on but no footwear → specific message', () {
      final wardrobe = [top('t1'), top('t2'), bottom('b1'), bottom('b2')];
      final result = GeneratorSession().generate(wardrobe, cfg(shoes: true));
      expect(result.ok, isFalse);
      expect(result.failureMessage, contains('shoes'));
    });
  });

  group('generate — exclusions', () {
    test('items in excludedItems never appear', () {
      final wardrobe = [
        top('t1', daysAgo: 30),
        top('t2', daysAgo: 20),
        top('t3', daysAgo: 10),
        bottom('b1', daysAgo: 30),
        bottom('b2', daysAgo: 20),
        bottom('b3', daysAgo: 10),
      ];
      final session = GeneratorSession()..excludedItems.add('t1');
      final result = session.generate(wardrobe, cfg());
      final allTopIds = result.outfits.map((o) => o.outfit.top.id);
      expect(allTopIds, isNot(contains('t1')));
    });
  });

  group('generate — pinned item', () {
    test('pinned top is locked into every outfit; other tops unused', () {
      final pinned = top('pin', daysAgo: 5);
      final wardrobe = [
        pinned,
        top('t1', daysAgo: 30),
        top('t2', daysAgo: 20),
        bottom('b1', daysAgo: 30),
        bottom('b2', daysAgo: 20),
        bottom('b3', daysAgo: 10),
      ];
      final result =
          GeneratorSession().generate(wardrobe, cfg(pinned: pinned));
      expect(result.ok, isTrue);
      for (final o in result.outfits) {
        expect(o.outfit.top.id, 'pin');
      }
    });

    test('condition-1 pinned item is auto-unpinned, generation proceeds', () {
      final wornPin = makeItem(
        id: 'pin',
        category: ItemCategory.top,
        condition: 1,
        occasionTags: const [Occasion.casual],
      );
      final wardrobe = [
        wornPin,
        top('t1', daysAgo: 30),
        top('t2', daysAgo: 20),
        bottom('b1', daysAgo: 30),
        bottom('b2', daysAgo: 20),
      ];
      final result =
          GeneratorSession().generate(wardrobe, cfg(pinned: wornPin));
      expect(result.ok, isTrue);
      // pin is condition 1 → filtered out by F3, never appears
      for (final o in result.outfits) {
        expect(o.outfit.top.id, isNot('pin'));
      }
    });

    test('pinned formality pre-filter returns specific message', () {
      final pinned = top('pin', formality: 5);
      final wardrobe = [
        pinned,
        bottom('b1', formality: 2),
        bottom('b2', formality: 2),
      ];

      final result =
          GeneratorSession().generate(wardrobe, cfg(pinned: pinned));

      expect(result.ok, isFalse);
      expect(result.failureMessage, contains('matching ${pinned.name}'));
    });
  });

  group('skip — cascade removal', () {
    test('skipping a top removes cards containing it and refills', () {
      final wardrobe = [
        top('t1', daysAgo: 30),
        top('t2', daysAgo: 20),
        top('t3', daysAgo: 10),
        bottom('b1', daysAgo: 30),
        bottom('b2', daysAgo: 20),
        bottom('b3', daysAgo: 10),
      ];
      final session = GeneratorSession();
      session.generate(wardrobe, cfg());
      final result = session.skip(wardrobe, cfg(), {'t1'});
      for (final o in result.outfits) {
        expect(o.outfit.itemIds, isNot(contains('t1')));
      }
      expect(session.excludedItems, contains('t1'));
    });

    test('sorts surviving and replacement cards by score after skip', () {
      final weakTop = top('weak-top', daysAgo: 1);
      final weakBottom = bottom('weak-bottom', daysAgo: 1);
      final skippedTop = top('skip', daysAgo: 1);
      final skippedBottom = bottom('skip-bottom', daysAgo: 1);
      final strongTop = top('strong-top', daysAgo: 90);
      final strongBottom = bottom('strong-bottom', daysAgo: 90);
      final weakOutfit = Outfit(top: weakTop, bottom: weakBottom);
      final skippedOutfit = Outfit(top: skippedTop, bottom: skippedBottom);
      final session = GeneratorSession()
        ..currentOutfits = [
          _scored(weakOutfit, 0.10),
          _scored(skippedOutfit, 0.90),
        ]
        ..excludedCombinations.addAll([
          _key(weakOutfit),
          _key(skippedOutfit),
        ]);

      final result = session.skip(
        [
          weakTop,
          weakBottom,
          skippedTop,
          skippedBottom,
          strongTop,
          strongBottom,
        ],
        cfg(),
        {'skip'},
      );
      final scores = result.outfits.map((o) => o.score).toList();
      final sorted = [...scores]..sort((a, b) => b.compareTo(a));

      expect(result.outfits, hasLength(3));
      expect(scores, orderedEquals(sorted));
    });
  });
}

ScoredOutfit _scored(Outfit outfit, double score) => ScoredOutfit(
      outfit: outfit,
      score: score,
      displayScore: (score * 100).round(),
      formality: FormalityResult(outfit: outfit, matched: true, loose: false),
      colourScore: 1.0,
    );

String _key(Outfit outfit) => (outfit.itemIds.toList()..sort()).join('|');
