import 'package:flutter_test/flutter_test.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/engine/outfit/outfit.dart';
import 'package:rewear/engine/outfit/outfit_assembler.dart';
import 'package:rewear/engine/outfit/outfit_explanation.dart';

import 'support/item_factory.dart';

/// `buildExplanationForOutfit` re-runs scoreItem per item (the gotcha:
/// ScoredOutfit has no per-item sub-scores) and feeds buildOutfitExplanation.
void main() {
  final now = DateTime(2026, 6, 1);

  final top = makeItem(
    id: 't',
    category: ItemCategory.top,
    type: 'T_SHIRT',
    colorTags: const ['white'],
    occasionTags: const [Occasion.casual],
    isNewItem: false,
    wearCount: 2,
    lastWornDate: now.subtract(const Duration(days: 30)),
    dateAdded: now.subtract(const Duration(days: 120)),
  );
  final bottom = makeItem(
    id: 'b',
    category: ItemCategory.bottom,
    type: 'JEANS',
    colorTags: const ['navy'],
    occasionTags: const [Occasion.casual],
    isNewItem: false,
    wearCount: 2,
    lastWornDate: now.subtract(const Duration(days: 30)),
    dateAdded: now.subtract(const Duration(days: 120)),
  );
  final outfit = Outfit(top: top, bottom: bottom);
  final wardrobe = [top, bottom];
  final formality = FormalityResult(outfit: outfit, matched: true, loose: false);

  test('produces a full explanation (5 rule rows, >=2 why reasons)', () {
    final exp = buildExplanationForOutfit(
      outfit: outfit,
      wardrobe: wardrobe,
      mode: RecommendationMode.pureRotation,
      formality: formality,
      colourScore: 0.90,
      displayScore: 85,
      occasion: Occasion.casual,
      now: now,
    );

    expect(exp.ruleBreakdown.length, 5);
    expect(exp.whyReasons.length, greaterThanOrEqualTo(2));
    expect(exp.whyReasons, contains('Matches Casual occasion'));
    expect(exp.scoreMessage, isNotEmpty);
  });

  test('leads with the pinned reason when an item is pinned', () {
    final exp = buildExplanationForOutfit(
      outfit: outfit,
      wardrobe: wardrobe,
      mode: RecommendationMode.pureRotation,
      formality: formality,
      colourScore: 0.90,
      displayScore: 85,
      occasion: Occasion.casual,
      pinnedItem: top,
      now: now,
    );

    expect(exp.whyReasons.first, 'Built around ${top.name}');
  });
}
