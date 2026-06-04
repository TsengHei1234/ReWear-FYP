import '../../core/constants/enums.dart';
import '../../data/models/item.dart';
import '../scoring/frs.dart';
import 'outfit.dart';
import 'outfit_assembler.dart';

/// Outfit Detail Explainability (RE "Outfit Detail Explainability Rules").
/// Display-only, pure Dart — never affects filtering/scoring/ranking, never
/// stored. Computed fresh from current item data + computed scores.

/// The four item-level scores the explanation needs, per outfit item.
class OutfitItemScores {
  const OutfitItemScores({
    required this.tds,
    required this.sps,
    required this.wfss,
    required this.nibs,
  });
  final double tds;
  final double sps;
  final double wfss;
  final double nibs;
}

/// One Rule Breakdown row: rule name, short description, and a badge label.
class RuleRow {
  const RuleRow({required this.name, required this.badge, required this.description});
  final String name;
  final String badge;
  final String description;
}

/// The full computed explanation for a generated outfit.
class OutfitExplanation {
  const OutfitExplanation({
    required this.scoreMessage,
    required this.whyReasons,
    required this.ruleBreakdown,
    this.highlights = const [],
  });
  final String scoreMessage;
  final List<String> whyReasons;
  final List<RuleRow> ruleBreakdown;

  /// Short labels for the generator result card (occasion · primary [+N]).
  /// Notable rotation positives only — colour/formality stay in the breakdown.
  final List<String> highlights;
}

// ── Rule breakdown badge functions (per RE thresholds) ──────────────────────

RuleRow temporalDecayBadge(double avgTds) {
  if (avgTds >= 0.65) {
    return const RuleRow(
        name: 'Temporal Decay',
        badge: 'High Rotation',
        description: 'Outfit has strong rotation priority');
  }
  if (avgTds >= 0.35) {
    return const RuleRow(
        name: 'Temporal Decay',
        badge: 'Medium Rotation',
        description: 'Outfit has moderate rotation priority');
  }
  return const RuleRow(
      name: 'Temporal Decay',
      badge: 'Low Rotation',
      description: 'Most items were worn recently');
}

RuleRow skipPenaltyBadge(double avgSps) {
  if (avgSps >= 0.85) {
    return const RuleRow(
        name: 'Skip Penalty',
        badge: 'Clear',
        description: 'No frequent skip pattern detected');
  }
  if (avgSps >= 0.60) {
    return const RuleRow(
        name: 'Skip Penalty',
        badge: 'Minor Skips',
        description: 'Some items have been skipped before');
  }
  return const RuleRow(
      name: 'Skip Penalty',
      badge: 'Penalty',
      description: 'One or more items are often skipped');
}

RuleRow wearBalanceBadge(double avgWfss) {
  if (avgWfss >= 0.70) {
    return const RuleRow(
        name: 'Wear Balance',
        badge: 'Balanced',
        description: 'No overused items in this outfit');
  }
  if (avgWfss >= 0.40) {
    return const RuleRow(
        name: 'Wear Balance',
        badge: 'Moderate',
        description: 'Some items are worn more often than others');
  }
  return const RuleRow(
      name: 'Wear Balance',
      badge: 'Overused',
      description: 'One or more items are worn very frequently');
}

RuleRow formalityBadge(FormalityResult formality) {
  if (formality.matched) {
    return const RuleRow(
        name: 'Formality Match',
        badge: 'Matched',
        description: 'Items are within 1 formality level');
  }
  return const RuleRow(
      name: 'Formality Match',
      badge: 'Loose',
      description: 'Best available formality match');
}

RuleRow colourBadge(double colourScore) {
  if (colourScore >= 0.80) {
    return const RuleRow(
        name: 'Colour Compatibility',
        badge: 'Strong',
        description: 'Colour palette has strong matching pairs');
  }
  if (colourScore >= 0.60) {
    return const RuleRow(
        name: 'Colour Compatibility',
        badge: 'Compatible',
        description: 'No clashing colour pairs detected');
  }
  if (colourScore >= 0.40) {
    return const RuleRow(
        name: 'Colour Compatibility',
        badge: 'Weak',
        description: 'Some colour pairs may feel less compatible');
  }
  return const RuleRow(
      name: 'Colour Compatibility',
      badge: 'Fallback',
      description: 'Used only because few alternatives were available');
}

// ── Builder ─────────────────────────────────────────────────────────────────

/// Builds the full explanation. [scoresById] maps each outfit item id → its
/// TDS/SPS/WFSS/NIBS. [occasion] null means "All". [pinnedItem] non-null when
/// the outfit was built around a pinned item.
OutfitExplanation buildOutfitExplanation({
  required Outfit outfit,
  required Map<String, OutfitItemScores> scoresById,
  required FormalityResult formality,
  required double colourScore,
  required int displayScore,
  Occasion? occasion,
  Item? pinnedItem,
}) {
  final items = outfit.items;
  double avg(double Function(OutfitItemScores) sel) {
    final vals = items.map((i) => sel(scoresById[i.id]!));
    return vals.fold<double>(0, (a, b) => a + b) / items.length;
  }

  final avgTds = avg((s) => s.tds);
  final avgSps = avg((s) => s.sps);
  final avgWfss = avg((s) => s.wfss);
  final hasNewItem = items.any((i) => (scoresById[i.id]!.nibs) > 0);

  final ruleBreakdown = [
    temporalDecayBadge(avgTds),
    skipPenaltyBadge(avgSps),
    wearBalanceBadge(avgWfss),
    formalityBadge(formality),
    colourBadge(colourScore),
  ];

  // Badge states reused by why-reasons + score suffix.
  final tdHigh = avgTds >= 0.65;
  final skipClear = avgSps >= 0.85;
  final balanced = avgWfss >= 0.70;
  final formalityMatched = formality.matched;
  final colourCompatible = colourScore >= 0.60;

  // ── Why reasons (max 4, min 2, positive only, first 4 by priority) ──
  final reasons = <String>[];
  if (pinnedItem != null) reasons.add('Built around ${pinnedItem.name}');
  if (occasion != null) reasons.add('Matches ${_occasionLabel(occasion)} occasion');
  if (hasNewItem) reasons.add('Includes a new item before it gets forgotten');
  if (tdHigh) reasons.add('Strong rotation priority');
  if (skipClear) reasons.add('No frequent skip pattern detected');
  if (balanced) reasons.add('No overused items in this outfit');
  if (formalityMatched) reasons.add('Formality levels match');
  if (colourCompatible) reasons.add('Colour palette is compatible');

  final whyReasons = reasons.take(4).toList();
  if (whyReasons.length < 2) {
    whyReasons.add('Recommended based on wardrobe rotation score');
  }

  // ── Score sentence: band + strongest suffix ──
  final band = _scoreBand(displayScore);
  final suffix = tdHigh
      ? ' with strong rotation priority'
      : hasNewItem
          ? ' with a new item included'
          : skipClear
              ? ' with no frequent skip pattern'
              : balanced
                  ? ' with balanced wear'
                  : formalityMatched
                      ? ' with matched formality'
                      : colourCompatible
                          ? ' with compatible colours'
                          : '';
  final scoreMessage = '$band$suffix.';

  // ── Highlights: short card labels (notable positives only). Ordered to
  // match the RE "Why this outfit" priority (new item → rotation → skip →
  // balance) so the card's PRIMARY label is the engine's strongest reason. ──
  final highlights = <String>[
    if (hasNewItem) 'New Item',
    if (tdHigh) 'High Rotation',
    if (skipClear) 'Low Skip Rate',
    if (balanced) 'Balanced Wear',
  ];

  return OutfitExplanation(
    scoreMessage: scoreMessage,
    whyReasons: whyReasons,
    ruleBreakdown: ruleBreakdown,
    highlights: highlights,
  );
}

/// Convenience: builds the explanation directly from an [outfit] + the full
/// [wardrobe], re-running `scoreItem` per item to recover the per-item
/// TDS/SPS/WFSS/NIBS (a [ScoredOutfit] does not carry them). Used by the Outfit
/// Generator (Quick Why) and Outfit Detail. Pure Dart.
OutfitExplanation buildExplanationForOutfit({
  required Outfit outfit,
  required List<Item> wardrobe,
  required RecommendationMode mode,
  Set<String> preferredColours = const {},
  Set<String> dislikedColours = const {},
  required FormalityResult formality,
  required double colourScore,
  required int displayScore,
  Occasion? occasion,
  Item? pinnedItem,
  required DateTime now,
}) {
  final scoresById = <String, OutfitItemScores>{};
  for (final item in outfit.items) {
    final activeCount = wardrobe
        .where((i) =>
            i.category == item.category && i.status == ItemStatus.inWardrobe)
        .length;
    final s = scoreItem(
      item,
      categoryActiveCount: activeCount,
      now: now,
      mode: mode,
      preferredColours: preferredColours,
      dislikedColours: dislikedColours,
    );
    scoresById[item.id] =
        OutfitItemScores(tds: s.tds, sps: s.sps, wfss: s.wfss, nibs: s.nibs);
  }

  return buildOutfitExplanation(
    outfit: outfit,
    scoresById: scoresById,
    formality: formality,
    colourScore: colourScore,
    displayScore: displayScore,
    occasion: occasion,
    pinnedItem: pinnedItem,
  );
}

String _scoreBand(int display) {
  if (display >= 90) return 'Strong outfit';
  if (display >= 80) return 'Balanced outfit';
  if (display >= 70) return 'Good outfit';
  if (display >= 60) return 'Acceptable outfit';
  return 'Backup outfit';
}

String _occasionLabel(Occasion o) => switch (o) {
      Occasion.casual => 'Casual',
      Occasion.work => 'Work',
      Occasion.active => 'Active',
      Occasion.relax => 'Relax',
    };
