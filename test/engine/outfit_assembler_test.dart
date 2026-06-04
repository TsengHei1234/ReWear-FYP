import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/engine/outfit/outfit.dart';
import 'package:rewear/engine/outfit/outfit_assembler.dart';

import 'support/item_factory.dart';

void main() {
  group('P1a — canAssemble', () {
    final top = makeItem(id: 't', category: ItemCategory.top);
    final bottom = makeItem(id: 'b', category: ItemCategory.bottom);
    final outer = makeItem(id: 'o', category: ItemCategory.outerwear);
    final shoes = makeItem(id: 's', category: ItemCategory.footwear);

    test('tops + bottoms present, no toggles → ok', () {
      final r = canAssemble(tops: [top], bottoms: [bottom]);
      expect(r.ok, isTrue);
      expect(r.message, isNull);
    });
    test('no tops → fail with availability message', () {
      final r = canAssemble(tops: const [], bottoms: [bottom]);
      expect(r.ok, isFalse);
      expect(r.message, contains('check item availability'));
    });
    test('outerwear toggle on but none available → specific message', () {
      final r = canAssemble(
        tops: [top],
        bottoms: [bottom],
        requireOuterwear: true,
        outerwear: const [],
      );
      expect(r.ok, isFalse);
      expect(r.message, contains('No available outerwear'));
    });
    test('shoes toggle on but none available → specific message', () {
      final r = canAssemble(
        tops: [top],
        bottoms: [bottom],
        requireShoes: true,
        shoes: const [],
      );
      expect(r.ok, isFalse);
      expect(r.message, contains('No available shoes'));
    });
    test('all toggles satisfied → ok', () {
      final r = canAssemble(
        tops: [top],
        bottoms: [bottom],
        requireOuterwear: true,
        outerwear: [outer],
        requireShoes: true,
        shoes: [shoes],
      );
      expect(r.ok, isTrue);
    });
  });

  group('P1c — colourCompatibilityScore (RE worked example)', () {
    test('White top + Navy bottom + Brown shoes → 0.90', () {
      final outfit = Outfit(
        top: makeItem(id: 't', category: ItemCategory.top, colorTags: ['white']),
        bottom:
            makeItem(id: 'b', category: ItemCategory.bottom, colorTags: ['navy']),
        shoes: makeItem(
            id: 's', category: ItemCategory.footwear, colorTags: ['brown']),
      );
      // Top↔Bottom White+Navy=1.00 ; Bottom↔Shoes Navy+Brown=0.80 → avg 0.90
      expect(colourCompatibilityScore(outfit), closeTo(0.90, 1e-9));
    });

    test('uses primary colour (color_tags[0]) only', () {
      final outfit = Outfit(
        top: makeItem(
            id: 't', category: ItemCategory.top, colorTags: ['black', 'red']),
        bottom: makeItem(
            id: 'b', category: ItemCategory.bottom, colorTags: ['white', 'green']),
      );
      // black + white = 1.00
      expect(colourCompatibilityScore(outfit), closeTo(1.00, 1e-9));
    });
  });

  group('P1b — formality', () {
    test('diff <= 1 accepts unchanged (Matched)', () {
      final outfit = Outfit(
        top: makeItem(id: 't', category: ItemCategory.top, formalityLevel: 2),
        bottom:
            makeItem(id: 'b', category: ItemCategory.bottom, formalityLevel: 2),
        shoes: makeItem(
            id: 's', category: ItemCategory.footwear, formalityLevel: 2),
      );
      final r = resolveFormality(outfit, candidatesBySlot: const {});
      expect(r.matched, isTrue);
      expect(r.loose, isFalse);
      expect(r.outfit.bottom.id, 'b');
    });

    test('diff > 1 swaps most-mismatched item to reach diff<=1 (worked example)', () {
      // Dress shirt(4) + Jeans(2) + Oxford(4): diff=2 → swap Jeans for Bottom-B(3)
      final outfit = Outfit(
        top: makeItem(id: 'dress', category: ItemCategory.top, formalityLevel: 4),
        bottom:
            makeItem(id: 'jeans', category: ItemCategory.bottom, formalityLevel: 2),
        shoes: makeItem(
            id: 'oxford', category: ItemCategory.footwear, formalityLevel: 4),
      );
      final bottomB =
          makeItem(id: 'bottomB', category: ItemCategory.bottom, formalityLevel: 3);
      final r = resolveFormality(
        outfit,
        candidatesBySlot: {
          OutfitSlot.bottom: [bottomB],
        },
      );
      expect(r.matched, isTrue);
      expect(r.loose, isFalse);
      expect(r.outfit.bottom.id, 'bottomB');
      expect(formalityDiff(r.outfit), 1);
    });

    test('no candidate can fix it → loose fallback (best available)', () {
      final outfit = Outfit(
        top: makeItem(id: 'dress', category: ItemCategory.top, formalityLevel: 4),
        bottom:
            makeItem(id: 'gym', category: ItemCategory.bottom, formalityLevel: 1),
      );
      final r = resolveFormality(outfit, candidatesBySlot: const {});
      expect(r.matched, isFalse);
      expect(r.loose, isTrue);
    });

    test('pinned slot is never targeted for swapping', () {
      // pinned top(4); bottom(1) is the mismatch but only top candidates exist
      final outfit = Outfit(
        top: makeItem(id: 'pin', category: ItemCategory.top, formalityLevel: 4),
        bottom:
            makeItem(id: 'gym', category: ItemCategory.bottom, formalityLevel: 1),
      );
      final altTop =
          makeItem(id: 'altTop', category: ItemCategory.top, formalityLevel: 2);
      final r = resolveFormality(
        outfit,
        candidatesBySlot: {
          OutfitSlot.top: [altTop],
        },
        pinnedSlot: OutfitSlot.top,
      );
      // top is pinned → cannot swap top → no fix → loose, pin retained
      expect(r.loose, isTrue);
      expect(r.outfit.top.id, 'pin');
    });
  });

  group('OutfitScore', () {
    test('0.70·avgFRS + 0.30·colour', () {
      final outfit = Outfit(
        top: makeItem(id: 't', category: ItemCategory.top, colorTags: ['white']),
        bottom:
            makeItem(id: 'b', category: ItemCategory.bottom, colorTags: ['navy']),
      );
      // colour white+navy = 1.00 ; avgFRS = 0.5
      final score = outfitScore(outfit, frsById: {'t': 0.5, 'b': 0.5});
      expect(score, closeTo(0.70 * 0.5 + 0.30 * 1.0, 1e-9));
    });

    test('display caps at 100', () {
      expect(outfitScoreDisplay(0.62), 62);
      expect(outfitScoreDisplay(1.105), 100);
    });
  });
}
