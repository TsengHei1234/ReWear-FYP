# Contract — Outfit Explanation (display-only)

**Source:** RE "Outfit Detail Explainability Rules". Pure Dart, display-only —
does NOT affect filtering/scoring/ranking. Computed fresh, never stored.
**Location:** `lib/engine/outfit/outfit_explanation.dart` + test.

Inputs: outfit, per-item TDS/SPS/WFSS/NIBS, P1b FormalityResult,
ColorCompatibilityScore, OutfitScore display value, selected occasion (null=All),
pinned item (nullable). Outfit-level rows use averages over actual outfit items.

## Rule Breakdown rows (5) — avg over outfit items
- **Temporal Decay** (avgTDS): ≥0.65 High Rotation / ≥0.35 Medium / else Low.
- **Skip Penalty** (avgSPS): ≥0.85 Clear / ≥0.60 Minor Skips / else Penalty.
- **Wear Balance** (avgWFSS): ≥0.70 Balanced / ≥0.40 Moderate / else Overused.
- **Formality Match**: matched→Matched ("within 1 level") / loose→Loose ("best available").
- **Colour Compatibility** (score): ≥0.80 Strong / ≥0.60 Compatible / ≥0.40 Weak / else Fallback.

## Why this outfit? (max 4, min 2, positive only — first 4 by priority)
1 Built around [name] (pinned) · 2 Matches [occasion] (occasion≠All) ·
3 Includes a new item… (any NIBS>0) · 4 Strong rotation priority (TD=High) ·
5 No frequent skip pattern (Skip=Clear) · 6 No overused items (Balance=Balanced) ·
7 Formality levels match (Formality=Matched) · 8 Colour palette is compatible (Colour=Strong/Compatible).
- occasion==All → drop reason 2. Pinned → reason 1 is first.
- <2 reasons → add fallback "Recommended based on wardrobe rotation score".

## Score sentence = band + strongest positive suffix
Band (display): 90-100 Strong / 80-89 Balanced / 70-79 Good / 60-69 Acceptable / 0-59 Backup ("… outfit").
Suffix priority: 1 with strong rotation priority (TD High) · 2 with a new item included (NIBS>0) ·
3 with no frequent skip pattern (Skip Clear) · 4 with balanced wear (Balanced) ·
5 with matched formality (Matched) · 6 with compatible colours (≥0.60).
No suffix matches → band sentence alone. Ends with period. Never "Perfect outfit".
