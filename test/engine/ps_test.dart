import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/engine/scoring/ps.dart';

import 'support/item_factory.dart';

void main() {
  group('preferenceScore (Mode A only)', () {
    test('neutral: not favourite, colour in neither list → 0.50', () {
      final item = makeItem(isFavorite: false, colorTags: ['navy']);
      expect(
        preferenceScore(item, preferredColours: {}, dislikedColours: {}),
        0.50,
      );
    });

    test('favourite → +0.20 = 0.70', () {
      final item = makeItem(isFavorite: true, colorTags: ['navy']);
      expect(
        preferenceScore(item, preferredColours: {}, dislikedColours: {}),
        closeTo(0.70, 1e-9),
      );
    });

    test('primary colour preferred → +0.15 = 0.65', () {
      final item = makeItem(isFavorite: false, colorTags: ['blue']);
      expect(
        preferenceScore(item, preferredColours: {'blue'}, dislikedColours: {}),
        closeTo(0.65, 1e-9),
      );
    });

    test('primary colour disliked → -0.20 = 0.30', () {
      final item = makeItem(isFavorite: false, colorTags: ['yellow']);
      expect(
        preferenceScore(item,
            preferredColours: {}, dislikedColours: {'yellow'}),
        closeTo(0.30, 1e-9),
      );
    });

    test('favourite + preferred → 0.50 + 0.20 + 0.15 = 0.85', () {
      final item = makeItem(isFavorite: true, colorTags: ['green']);
      expect(
        preferenceScore(item,
            preferredColours: {'green'}, dislikedColours: {}),
        closeTo(0.85, 1e-9),
      );
    });

    test('colour in both preferred and disliked → both apply (0.45)', () {
      final item = makeItem(isFavorite: false, colorTags: ['red']);
      expect(
        preferenceScore(item,
            preferredColours: {'red'}, dislikedColours: {'red'}),
        closeTo(0.45, 1e-9),
      );
    });

    test('only the primary colour (color_tags[0]) is considered', () {
      final item = makeItem(isFavorite: false, colorTags: ['navy', 'red']);
      // navy neutral, red disliked — but red is secondary so ignored
      expect(
        preferenceScore(item,
            preferredColours: {}, dislikedColours: {'red'}),
        0.50,
      );
    });
  });
}
