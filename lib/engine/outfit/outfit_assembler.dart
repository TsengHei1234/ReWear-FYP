import '../../core/constants/colour_compatibility.dart';
import '../../data/models/item.dart';
import 'outfit.dart';

/// Layer 3 — Post-Processing (RE): P1a completeness, P1b formality, P1c colour,
/// and OutfitScore. Pure Dart.

// ── P1a — Category Completeness ─────────────────────────────────────────────

/// Result of the P1a pre-check.
class AssembleCheck {
  const AssembleCheck.ok()
      : ok = true,
        message = null;
  const AssembleCheck.fail(this.message) : ok = false;

  final bool ok;
  final String? message;
}

/// Pre-checks whether ANY valid outfit can be built from the candidate pools.
/// Required: ≥1 top AND ≥1 bottom. Toggled layers must have ≥1 candidate.
/// A pinned item's layer is satisfied by passing a non-empty pool for it.
/// Collects ALL missing layers before returning so the message names every gap.
AssembleCheck canAssemble({
  required List<Item> tops,
  required List<Item> bottoms,
  List<Item> outerwear = const [],
  List<Item> shoes = const [],
  bool requireOuterwear = false,
  bool requireShoes = false,
}) {
  final missing = <String>[];
  if (tops.isEmpty) missing.add('tops');
  if (bottoms.isEmpty) missing.add('bottoms');
  if (requireOuterwear && outerwear.isEmpty) missing.add('outerwear');
  if (requireShoes && shoes.isEmpty) missing.add('shoes');
  if (missing.isEmpty) return const AssembleCheck.ok();
  return AssembleCheck.fail(
    'Cannot build outfit — no available ${_joinLayers(missing)} for this occasion.',
  );
}

/// Formats a list of layer names into natural English.
/// 1 item: "tops"  2 items: "tops or bottoms"  3+: "tops, bottoms, or shoes"
String _joinLayers(List<String> layers) {
  if (layers.length == 1) return layers[0];
  if (layers.length == 2) return '${layers[0]} or ${layers[1]}';
  final last = layers.last;
  final rest = layers.sublist(0, layers.length - 1).join(', ');
  return '$rest, or $last';
}

// ── P1c — Colour Compatibility Score ────────────────────────────────────────

/// Average of the evaluated colour pairs (RE "P1c"). Uses color_tags[0].
/// Pairs: Top↔Bottom (always), Top↔Outerwear, Bottom↔Shoes, Outerwear↔Shoes.
double colourCompatibilityScore(Outfit outfit) {
  final scores = <double>[];

  String primary(Item i) => i.colorTags.isEmpty ? '' : i.colorTags.first;

  // Top ↔ Bottom — always.
  scores.add(colourScore(primary(outfit.top), primary(outfit.bottom)));

  if (outfit.outerwear != null) {
    scores.add(colourScore(primary(outfit.top), primary(outfit.outerwear!)));
  }
  if (outfit.shoes != null) {
    scores.add(colourScore(primary(outfit.bottom), primary(outfit.shoes!)));
  }
  if (outfit.outerwear != null && outfit.shoes != null) {
    scores
        .add(colourScore(primary(outfit.outerwear!), primary(outfit.shoes!)));
  }

  final sum = scores.fold<double>(0, (a, b) => a + b);
  return sum / scores.length;
}

// ── P1b — Formality Matching ────────────────────────────────────────────────

/// max(formality) − min(formality) across the outfit's items.
int formalityDiff(Outfit outfit) {
  final levels = outfit.items.map((i) => i.formalityLevel);
  final maxF = levels.reduce((a, b) => a > b ? a : b);
  final minF = levels.reduce((a, b) => a < b ? a : b);
  return maxF - minF;
}

/// Outcome of P1b formality resolution.
class FormalityResult {
  const FormalityResult({
    required this.outfit,
    required this.matched,
    required this.loose,
  });

  /// The (possibly swapped) outfit.
  final Outfit outfit;

  /// Final formality difference ≤ 1 cleanly.
  final bool matched;

  /// Accepted best-available after exhausting swaps (soft warning).
  final bool loose;
}

const int _maxFormalityAttempts = 20;

/// P1b — if diff > 1, try to swap the most-mismatched item (never the pinned
/// slot) for a same-slot candidate (FRS-ordered) that brings diff ≤ 1.
/// Up to 20 candidate attempts; otherwise accept the best-available (min diff).
FormalityResult resolveFormality(
  Outfit outfit, {
  required Map<OutfitSlot, List<Item>> candidatesBySlot,
  OutfitSlot? pinnedSlot,
}) {
  if (formalityDiff(outfit) <= 1) {
    return FormalityResult(outfit: outfit, matched: true, loose: false);
  }

  var bestOutfit = outfit;
  var bestDiff = formalityDiff(outfit);
  var attempts = 0;

  for (final slot in _mismatchOrder(outfit, pinnedSlot)) {
    final candidates = candidatesBySlot[slot] ?? const <Item>[];
    for (final cand in candidates) {
      // Skip no-ops and self-pairing (candidate already used in another slot).
      if (cand.id == outfit.itemAt(slot)!.id) continue;
      if (outfit.itemIds.contains(cand.id)) continue;

      attempts++;
      if (attempts > _maxFormalityAttempts) {
        return FormalityResult(outfit: bestOutfit, matched: false, loose: true);
      }

      final test = outfit.withSlot(slot, cand);
      final testDiff = formalityDiff(test);
      if (testDiff <= 1) {
        return FormalityResult(outfit: test, matched: true, loose: false);
      }
      if (testDiff < bestDiff) {
        bestDiff = testDiff;
        bestOutfit = test;
      }
    }
  }

  return FormalityResult(outfit: bestOutfit, matched: false, loose: true);
}

/// Slots ordered by mismatch: |formality − avg| descending, tiebreak HIGHER
/// formality first. The pinned slot is excluded (never targeted for swaps).
List<OutfitSlot> _mismatchOrder(Outfit outfit, OutfitSlot? pinnedSlot) {
  final filled = outfit.filledSlots.where((s) => s != pinnedSlot).toList();
  final avg = outfit.items.map((i) => i.formalityLevel).reduce((a, b) => a + b) /
      outfit.items.length;

  filled.sort((a, b) {
    final fa = outfit.itemAt(a)!.formalityLevel;
    final fb = outfit.itemAt(b)!.formalityLevel;
    final da = (fa - avg).abs();
    final db = (fb - avg).abs();
    final byDist = db.compareTo(da); // larger distance first
    if (byDist != 0) return byDist;
    return fb.compareTo(fa); // tiebreak: higher formality first
  });
  return filled;
}

// ── OutfitScore ─────────────────────────────────────────────────────────────

/// Average FRS of the outfit's items. [frsById] maps item id → its FRS.
double averageItemFrs(Outfit outfit, {required Map<String, double> frsById}) {
  final values = outfit.items.map((i) => frsById[i.id] ?? 0.0);
  final sum = values.fold<double>(0, (a, b) => a + b);
  return sum / outfit.items.length;
}

/// Internal (uncapped) OutfitScore used for ranking.
double outfitScore(Outfit outfit, {required Map<String, double> frsById}) {
  final avgFrs = averageItemFrs(outfit, frsById: frsById);
  final colour = colourCompatibilityScore(outfit);
  return (0.70 * avgFrs) + (0.30 * colour);
}

/// Display score: min(round(internal × 100), 100).
int outfitScoreDisplay(double internalScore) {
  final scaled = (internalScore * 100).round();
  return scaled < 100 ? scaled : 100;
}
