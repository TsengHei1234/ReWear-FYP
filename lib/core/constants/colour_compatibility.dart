/// M1 — Colour Compatibility Score (pure Dart, no Flutter imports).
///
/// The Rule Engine ("P1c — Colour Compatibility Score") gives colour *groups*
/// and six heuristic score *bands* but NO explicit 12×12 pair table. This file
/// AUTHORS that table via a documented, principled algorithm over the 13 locked
/// swatch colours, and is unit-tested against the RE's one worked example
/// (White+Navy=1.00, Navy+Brown=0.80 → avg 0.90).
///
/// Bands (RE):
///   1.00 strong safe · 0.90 good · 0.80 acceptable/neutral
///   0.65 too similar but wearable · 0.50 weak/awkward · 0.30 known clash
///
/// Colours are passed as SwatchColour tokens ('black', 'navy', ...) — the same
/// strings stored in items.color_tags. color_tags[0] (primary) is used by P1c.
///
/// ── Authoring assumptions (flagged for review — DECISIONS.md M1) ─────────────
/// 1. Neutrals split into ACHROMATIC {black,white,grey,beige} and
///    COLOURED-NEUTRAL {navy,brown}. Two achromatics, or achromatic+coloured-
///    neutral, = 1.00. Two coloured-neutrals (navy+brown) = 0.80. This exactly
///    reproduces both RE worked-example cells.
/// 2. Achromatic neutral + any chromatic = 0.90 (neutrals flatter a colour).
/// 3. Coloured-neutral + chromatic = 0.80, except navy+blue = 0.65 (too similar).
/// 4. Chromatic pairs: same-temperature family (cool+cool) and adjacent
///    harmonious (blue+purple) = 0.80; analogous/too-similar = 0.65; known
///    complementary clashes (green+red, yellow+purple) = 0.30; all other loud
///    cross-temperature/accent pairs = 0.50.
/// 5. Same colour (monochrome) is tiered (M1 review): achromatic = 0.80,
///    coloured-neutral (navy/brown) = 0.70, bright chromatic = 0.65. Neutral
///    monochrome outfits stay acceptable; variety comes from rotation scoring.
///    NOTE: 0.70 is an authored intermediate value, not one of the six RE bands.
/// 6. RE groups list olive/cream — not in the 13 swatches, so omitted. Orange
///    was added (13th swatch) with explicit chromatic pair overrides below.
/// 7. Unknown/legacy tokens fall back to 0.80 (acceptable) so a stray tag never
///    tanks an outfit.
library;

const Set<String> _achromatic = {'black', 'white', 'grey', 'beige'};
const Set<String> _colouredNeutral = {'navy', 'brown'};
const Set<String> _neutral = {..._achromatic, ..._colouredNeutral};
const Set<String> _cool = {'blue', 'green'};

/// Unordered chromatic pairs scored above the 0.50 default.
String _key(String a, String b) {
  final sorted = [a, b]..sort();
  return '${sorted[0]}|${sorted[1]}';
}

const Map<String, double> _chromaticOverrides = {
  // same-temperature / adjacent harmonious → 0.80
  'blue|green': 0.80,
  'blue|purple': 0.80,
  // analogous / too similar → 0.65
  'green|yellow': 0.65,
  'pink|red': 0.65,
  'purple|red': 0.65,
  'pink|purple': 0.65,
  'orange|red': 0.65,
  'orange|yellow': 0.65,
  'orange|pink': 0.65,
  // known complementary clashes → 0.30
  'green|red': 0.30,
  'purple|yellow': 0.30,
  'blue|orange': 0.30,
  'orange|purple': 0.30,
};

/// Returns the P1c compatibility band for two primary colours, in [0.30, 1.00].
/// Symmetric: colourScore(a,b) == colourScore(b,a).
double colourScore(String a, String b) {
  // Unknown tokens — neutral fallback.
  if (!_isKnown(a) || !_isKnown(b)) return 0.80;

  // Same colour (monochrome). Tiered so neutral monochrome outfits stay
  // acceptable in a wardrobe app — variety comes from rotation scoring, not
  // from penalising neutral same-colour outfits (M1 review decision):
  //   achromatic (black/white/grey/beige) → 0.80
  //   coloured-neutral (navy/brown)        → 0.70
  //   bright chromatic                     → 0.65 (too similar but wearable)
  if (a == b) {
    if (_achromatic.contains(a)) return 0.80;
    if (_colouredNeutral.contains(a)) return 0.70;
    return 0.65;
  }

  final aNeutral = _neutral.contains(a);
  final bNeutral = _neutral.contains(b);

  // Both neutral.
  if (aNeutral && bNeutral) {
    final aAch = _achromatic.contains(a);
    final bAch = _achromatic.contains(b);
    if (aAch && bAch) return 1.00; // two achromatics
    if (aAch || bAch) return 1.00; // achromatic + coloured-neutral
    return 0.80; // navy + brown (both coloured-neutral)
  }

  // One neutral + one chromatic.
  if (aNeutral || bNeutral) {
    final neutral = aNeutral ? a : b;
    final chromatic = aNeutral ? b : a;
    if (_achromatic.contains(neutral)) return 0.90;
    // coloured-neutral + chromatic
    if (neutral == 'navy' && chromatic == 'blue') return 0.65; // too similar
    return 0.80;
  }

  // Both chromatic.
  final override = _chromaticOverrides[_key(a, b)];
  if (override != null) return override;
  if (_cool.contains(a) && _cool.contains(b)) return 0.80; // cool family
  return 0.50; // loud / cross-temperature default
}

bool _isKnown(String c) =>
    _neutral.contains(c) ||
    const {'blue', 'green', 'red', 'orange', 'yellow', 'pink', 'purple'}.contains(c);
