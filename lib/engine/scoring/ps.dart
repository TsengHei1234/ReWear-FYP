import '../../data/models/item.dart';

/// S5 — Preference Score (RE "Layer 2 — Scoring Formulas", S5).
/// Small advantage to items matching user preferences.
/// Used in Mode A (Balanced Rotation) only; skipped in Mode B (Pure Rotation).
///
/// Uses color_tags[0] (primary colour). is_favorite is handled here — there is
/// no separate favourite multiplier. If a colour is in both preferred and
/// disliked lists, both adjustments apply.
double preferenceScore(
  Item item, {
  required Set<String> preferredColours,
  required Set<String> dislikedColours,
}) {
  var ps = 0.50; // neutral default

  if (item.isFavorite) ps += 0.20;

  final primary = item.colorTags.isEmpty ? null : item.colorTags.first;
  if (primary != null) {
    if (preferredColours.contains(primary)) ps += 0.15;
    if (dislikedColours.contains(primary)) ps -= 0.20;
  }

  return ps.clamp(0.00, 1.00);
}
