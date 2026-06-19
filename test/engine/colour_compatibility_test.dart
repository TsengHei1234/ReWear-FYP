import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/core/constants/colour_compatibility.dart';

void main() {
  group('colourScore — RE worked example (P1c)', () {
    test('White + Navy = 1.00 (strong safe neutral match)', () {
      expect(colourScore('white', 'navy'), 1.00);
    });
    test('Navy + Brown = 0.80 (acceptable)', () {
      expect(colourScore('navy', 'brown'), 0.80);
    });
    test('example average (1.00 + 0.80) / 2 = 0.90', () {
      final avg = (colourScore('white', 'navy') + colourScore('navy', 'brown')) / 2;
      expect(avg, closeTo(0.90, 1e-9));
    });
  });

  group('colourScore — symmetry and bounds', () {
    test('symmetric for every swatch pair', () {
      const all = [
        'black', 'white', 'grey', 'beige', 'navy', 'brown',
        'blue', 'green', 'red', 'orange', 'yellow', 'pink', 'purple',
      ];
      for (final a in all) {
        for (final b in all) {
          expect(colourScore(a, b), colourScore(b, a),
              reason: '$a/$b not symmetric');
        }
      }
    });
    test('every score is a valid band', () {
      // Six RE bands + authored 0.70 (coloured-neutral monochrome, M1 review).
      final bands = {1.00, 0.90, 0.80, 0.70, 0.65, 0.50, 0.30};
      const all = [
        'black', 'white', 'grey', 'beige', 'navy', 'brown',
        'blue', 'green', 'red', 'orange', 'yellow', 'pink', 'purple',
      ];
      for (final a in all) {
        for (final b in all) {
          expect(bands.contains(colourScore(a, b)), isTrue,
              reason: '$a/$b = ${colourScore(a, b)} not a valid band');
        }
      }
    });
  });

  group('colourScore — representative derived cells', () {
    test('two achromatic neutrals → 1.00', () {
      expect(colourScore('black', 'white'), 1.00);
      expect(colourScore('grey', 'beige'), 1.00);
    });
    test('achromatic neutral + chromatic → 0.90', () {
      expect(colourScore('white', 'blue'), 0.90);
      expect(colourScore('black', 'red'), 0.90);
    });
    test('coloured-neutral + chromatic → 0.80 (navy+blue too-similar 0.65)', () {
      expect(colourScore('brown', 'green'), 0.80);
      expect(colourScore('navy', 'blue'), 0.65);
    });
    test('cool + cool family → 0.80', () {
      expect(colourScore('blue', 'green'), 0.80);
    });
    test('known clashes → 0.30', () {
      expect(colourScore('green', 'red'), 0.30);
      expect(colourScore('yellow', 'purple'), 0.30);
    });
    test('analogous warm accents too similar → 0.65', () {
      expect(colourScore('red', 'pink'), 0.65);
    });
    test('cross-temperature loud accents → 0.50', () {
      expect(colourScore('blue', 'red'), 0.50);
      expect(colourScore('yellow', 'pink'), 0.50);
    });
    test('orange — achromatic neutral → 0.90', () {
      expect(colourScore('orange', 'white'), 0.90);
      expect(colourScore('orange', 'black'), 0.90);
      expect(colourScore('orange', 'grey'), 0.90);
      expect(colourScore('orange', 'beige'), 0.90);
    });
    test('orange — coloured-neutral → 0.80', () {
      expect(colourScore('orange', 'navy'), 0.80);
      expect(colourScore('orange', 'brown'), 0.80);
    });
    test('orange — analogous warm → 0.65', () {
      expect(colourScore('orange', 'red'), 0.65);
      expect(colourScore('orange', 'yellow'), 0.65);
      expect(colourScore('orange', 'pink'), 0.65);
    });
    test('orange — complementary clash → 0.30', () {
      expect(colourScore('orange', 'blue'), 0.30);
      expect(colourScore('orange', 'purple'), 0.30);
    });
    test('orange — cross-temperature → 0.50', () {
      expect(colourScore('orange', 'green'), 0.50);
    });
    test('orange monochrome → 0.65 (bright chromatic)', () {
      expect(colourScore('orange', 'orange'), 0.65);
    });
    test('same colour diagonal is tiered (neutral monochrome acceptable)', () {
      // achromatic monochrome → 0.80 (acceptable)
      expect(colourScore('black', 'black'), 0.80);
      expect(colourScore('white', 'white'), 0.80);
      expect(colourScore('grey', 'grey'), 0.80);
      expect(colourScore('beige', 'beige'), 0.80);
      // coloured-neutral monochrome → 0.70
      expect(colourScore('navy', 'navy'), 0.70);
      expect(colourScore('brown', 'brown'), 0.70);
      // bright chromatic monochrome → 0.65 (too similar but wearable)
      expect(colourScore('blue', 'blue'), 0.65);
      expect(colourScore('red', 'red'), 0.65);
    });
  });
}
