import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/engine/scoring/sps.dart';

import 'support/item_factory.dart';

void main() {
  group('skipPenaltyScore', () {
    test('no data (wear=0, skip=0) → 1.0', () {
      expect(skipPenaltyScore(makeItem(wearCount: 0, skipCount: 0)), 1.0);
    });

    test('worn 2, skipped 3 → 1.0 - 3/10 = 0.70 (with +5 smoothing)', () {
      expect(
        skipPenaltyScore(makeItem(wearCount: 2, skipCount: 3)),
        closeTo(0.70, 1e-9),
      );
    });

    test('never worn but skipped 5 → 1.0 - 5/10 = 0.50', () {
      expect(
        skipPenaltyScore(makeItem(wearCount: 0, skipCount: 5)),
        closeTo(0.50, 1e-9),
      );
    });

    test('worn often, never skipped → 1.0', () {
      expect(skipPenaltyScore(makeItem(wearCount: 20, skipCount: 0)), 1.0);
    });
  });
}
