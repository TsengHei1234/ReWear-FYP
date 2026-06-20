import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/data/models/item.dart';
import 'package:rewear/engine/outfit/generator_session.dart';

import 'support/item_factory.dart';

void main() {
  final now = DateTime(2026, 6, 1);

  Item top(String id, {String type = 'T_SHIRT'}) => makeItem(
        id: id,
        category: ItemCategory.top,
        type: type,
        occasionTags: const [Occasion.casual],
        condition: 4,
        isNewItem: false,
        wearCount: 3,
        lastWornDate: now.subtract(const Duration(days: 10)),
        dateAdded: now.subtract(const Duration(days: 100)),
      );

  Item bottom(String id, {String type = 'JEANS'}) => makeItem(
        id: id,
        category: ItemCategory.bottom,
        type: type,
        occasionTags: const [Occasion.casual],
        condition: 4,
        isNewItem: false,
        wearCount: 3,
        lastWornDate: now.subtract(const Duration(days: 10)),
        dateAdded: now.subtract(const Duration(days: 100)),
      );

  Item outerwear(String id, {String type = 'CASUAL_JACKET'}) => makeItem(
        id: id,
        category: ItemCategory.outerwear,
        type: type,
        occasionTags: const [Occasion.casual],
        condition: 4,
        isNewItem: false,
        wearCount: 3,
        lastWornDate: now.subtract(const Duration(days: 10)),
        dateAdded: now.subtract(const Duration(days: 100)),
      );

  GeneratorConfig cfg({
    Map<ItemCategory, String> selectedTypes = const {},
    Item? pinned,
    bool requireOuterwear = false,
    bool requireShoes = false,
  }) =>
      GeneratorConfig(
        occasion: Occasion.casual,
        requireOuterwear: requireOuterwear,
        requireShoes: requireShoes,
        pinnedItem: pinned,
        mode: RecommendationMode.pureRotation,
        selectedTypes: selectedTypes,
        now: now,
      );

  // ── No filter ──────────────────────────────────────────────────────────────

  group('no filter', () {
    test('empty selectedTypes — behaves same as before (no narrowing)', () {
      final wardrobe = [
        top('t1', type: 'T_SHIRT'),
        top('t2', type: 'POLO_SHIRT'),
        bottom('b1', type: 'JEANS'),
        bottom('b2', type: 'CHINOS'),
      ];
      final result = GeneratorSession().generate(wardrobe, cfg());
      expect(result.ok, isTrue);
      expect(result.outfits, isNotEmpty);
    });
  });

  // ── Top filter ─────────────────────────────────────────────────────────────

  group('top filter', () {
    test('T_SHIRT filter: all outfits use only T-shirts', () {
      final wardrobe = [
        top('t-shirt', type: 'T_SHIRT'),
        top('polo', type: 'POLO_SHIRT'),
        top('button-up', type: 'CASUAL_BUTTON_UP_SHIRT'),
        bottom('b1'),
        bottom('b2'),
      ];
      final result = GeneratorSession()
          .generate(wardrobe, cfg(selectedTypes: {ItemCategory.top: 'T_SHIRT'}));
      expect(result.ok, isTrue);
      for (final so in result.outfits) {
        expect(so.outfit.top.type, 'T_SHIRT');
      }
    });

    test('POLO_SHIRT filter: outfits only have polos, not T-shirts', () {
      final wardrobe = [
        top('t-shirt', type: 'T_SHIRT'),
        top('polo', type: 'POLO_SHIRT'),
        bottom('b1'),
        bottom('b2'),
      ];
      final result = GeneratorSession().generate(
        wardrobe,
        cfg(selectedTypes: {ItemCategory.top: 'POLO_SHIRT'}),
      );
      expect(result.ok, isTrue);
      for (final so in result.outfits) {
        expect(so.outfit.top.type, 'POLO_SHIRT');
      }
    });
  });

  // ── Bottom filter ──────────────────────────────────────────────────────────

  group('bottom filter', () {
    test('JEANS filter: all outfits use only jeans, not chinos', () {
      final wardrobe = [
        top('t1'),
        top('t2'),
        bottom('jeans', type: 'JEANS'),
        bottom('chinos', type: 'CHINOS'),
        bottom('shorts', type: 'CASUAL_SHORTS'),
      ];
      final result = GeneratorSession().generate(
        wardrobe,
        cfg(selectedTypes: {ItemCategory.bottom: 'JEANS'}),
      );
      expect(result.ok, isTrue);
      for (final so in result.outfits) {
        expect(so.outfit.bottom.type, 'JEANS');
      }
    });
  });

  // ── Both slots filtered ────────────────────────────────────────────────────

  group('both top and bottom filtered', () {
    test('T_SHIRT + JEANS: only that combination is assembled', () {
      final wardrobe = [
        top('t-shirt', type: 'T_SHIRT'),
        top('polo', type: 'POLO_SHIRT'),
        bottom('jeans', type: 'JEANS'),
        bottom('chinos', type: 'CHINOS'),
      ];
      final result = GeneratorSession().generate(
        wardrobe,
        cfg(selectedTypes: {
          ItemCategory.top: 'T_SHIRT',
          ItemCategory.bottom: 'JEANS',
        }),
      );
      expect(result.ok, isTrue);
      for (final so in result.outfits) {
        expect(so.outfit.top.type, 'T_SHIRT');
        expect(so.outfit.bottom.type, 'JEANS');
      }
    });
  });

  // ── Filter empties required slot ───────────────────────────────────────────

  group('filter empties required slot', () {
    test('top filter matches no items → filter-specific failure message', () {
      final wardrobe = [
        top('polo', type: 'POLO_SHIRT'),
        bottom('b1'),
        bottom('b2'),
      ];
      final result = GeneratorSession().generate(
        wardrobe,
        cfg(selectedTypes: {ItemCategory.top: 'T_SHIRT'}),
      );
      expect(result.ok, isFalse);
      expect(result.failureMessage, contains('type filter'));
    });

    test('bottom filter matches no items → filter-specific failure message', () {
      final wardrobe = [
        top('t1'),
        top('t2'),
        bottom('chinos', type: 'CHINOS'),
      ];
      final result = GeneratorSession().generate(
        wardrobe,
        cfg(selectedTypes: {ItemCategory.bottom: 'JEANS'}),
      );
      expect(result.ok, isFalse);
      expect(result.failureMessage, contains('type filter'));
    });
  });

  // ── Empty wardrobe → generic failure, not filter failure ──────────────────

  group('generic failure vs filter failure', () {
    test('empty wardrobe → generic failure (not filter-specific message)', () {
      final result = GeneratorSession().generate(
        const [],
        cfg(selectedTypes: {ItemCategory.top: 'T_SHIRT'}),
      );
      expect(result.ok, isFalse);
      expect(result.failureMessage, isNot(contains('type filter')));
    });

    test('no items in wardrobe and no filter → generic failure', () {
      final result = GeneratorSession().generate(const [], cfg());
      expect(result.ok, isFalse);
      expect(result.failureMessage, isNotNull);
    });
  });

  // ── Filter on inactive optional slot ──────────────────────────────────────

  group('filter on inactive optional slot', () {
    test(
        'outerwear filter set but requireOuterwear=false → outfits still generated,'
        ' outerwear absent', () {
      final wardrobe = [
        top('t1'),
        bottom('b1'),
        outerwear('ow', type: 'BOMBER_JACKET'),
      ];
      final result = GeneratorSession().generate(
        wardrobe,
        cfg(
          selectedTypes: {ItemCategory.outerwear: 'CASUAL_JACKET'},
          requireOuterwear: false,
        ),
      );
      expect(result.ok, isTrue);
      for (final so in result.outfits) {
        expect(so.outfit.outerwear, isNull);
      }
    });
  });

  // ── Pinned item ignores type filter for that slot ─────────────────────────

  group('pinned item', () {
    test('pin is a POLO_SHIRT, filter says T_SHIRT → pin wins, POLO used', () {
      final pinnedPolo = top('pinned', type: 'POLO_SHIRT');
      final wardrobe = [
        pinnedPolo,
        top('other', type: 'T_SHIRT'),
        bottom('b1'),
        bottom('b2'),
      ];
      final result = GeneratorSession().generate(
        wardrobe,
        cfg(
          selectedTypes: {ItemCategory.top: 'T_SHIRT'},
          pinned: pinnedPolo,
        ),
      );
      expect(result.ok, isTrue);
      for (final so in result.outfits) {
        expect(so.outfit.top.id, 'pinned');
        expect(so.outfit.top.type, 'POLO_SHIRT');
      }
    });

    test('pin on top, bottom has type filter that empties it → filter failure', () {
      final pinnedTop = top('pinned', type: 'T_SHIRT');
      final wardrobe = [
        pinnedTop,
        bottom('chinos', type: 'CHINOS'),
      ];
      final result = GeneratorSession().generate(
        wardrobe,
        cfg(
          selectedTypes: {ItemCategory.bottom: 'JEANS'},
          pinned: pinnedTop,
        ),
      );
      expect(result.ok, isFalse);
      expect(result.failureMessage, contains('type filter'));
    });
  });

  // ── Filter applied before take(8) ─────────────────────────────────────────

  group('filter before take(8)', () {
    test('narrowed pool still has items after take(8) cap is applied', () {
      // 10 tops of one type, 3 of another.
      // If take(8) happened before the filter, the 3-item type could be
      // pushed out of the top-8 by the 10-item type (FRS ordering).
      // With filter before take(8), the filtered type is guaranteed to be
      // present if it has any wardrobe-eligible items.
      final wardrobe = [
        for (int i = 1; i <= 10; i++) top('a$i', type: 'POLO_SHIRT'),
        for (int i = 1; i <= 3; i++) top('b$i', type: 'T_SHIRT'),
        bottom('bot1'),
        bottom('bot2'),
        bottom('bot3'),
      ];
      final result = GeneratorSession().generate(
        wardrobe,
        cfg(selectedTypes: {ItemCategory.top: 'T_SHIRT'}),
      );
      expect(result.ok, isTrue);
      for (final so in result.outfits) {
        expect(so.outfit.top.type, 'T_SHIRT');
      }
    });
  });
}
