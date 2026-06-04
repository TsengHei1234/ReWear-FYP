import 'package:flutter/material.dart';

/// All colour tokens for ReWear.
///
/// Source of truth: Frontend Reference §1 "Design System — Colours".
/// Do not hardcode hex values elsewhere — reference these constants.
class AppColors {
  AppColors._();

  // ── Light theme ────────────────────────────────────────────────
  static const background = Color(0xFFF7F4EF); // scaffold base
  static const surface = Color(0xFFFFFFFF); // cards, inputs, sheets
  static const surface2 = Color(0xFFF0EDE6); // dividers, tiles, track

  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6560);
  static const textTertiary = Color(0xFF9B9490);

  static const border = Color(0xFFE6E1D8); // normal borders
  static const borderFocus = Color(0xFFC8DEC8); // focused / has-value (green tint)

  static const primary = Color(0xFF4A7055); // all primary actions
  static const primaryMid = Color(0xFF7FAF8C); // secondary accents, progress fills
  static const primaryLight = Color(0xFFEBF2EC); // selected chip bg, icon tiles
  static const darkPrimaryText = Color(0xFF27500A); // text on primaryLight bg

  static const primaryPressed = Color(0xFF3D5E49); // primary button pressed

  // ── Dark theme ─────────────────────────────────────────────────
  static const darkBackground = Color(0xFF111511);
  static const darkSurface = Color(0xFF181E18);
  static const darkSurface2 = Color(0xFF202820);
  static const darkTextPrimary = Color(0xFFF0EFEC);
  static const darkTextSecondary = Color(0xFF9E9C97);
  static const darkTextTertiary = Color(0xFF6B6965);
  static const darkBorder = Color(0xFF2C342C);
  static const darkPrimary = Color(0xFF6BAF80);
  // Dark equivalents of primaryLight (chip-selected bg, icon tiles) and the
  // text shown on top of it. Derived to mirror the light pairing.
  static const darkPrimaryLight = Color(0xFF233027); // muted dark green tile
  static const darkOnPrimaryLight = Color(0xFFA5D6B0); // light green text/icon

  // ── Destructive / alert ────────────────────────────────────────
  static const danger = Color(0xFFB91C1C); // donate/delete border+text
  static const dangerBg = Color(0xFFFEF2F2); // log out card bg
  static const dangerBorder = Color(0xFFFECACA); // log out card border
  static const dangerIconTile = Color(0xFFFEE2E2); // log out icon tile

  // ── Semantic / badge colours (Frontend §1) ─────────────────────
  // Each badge has a background + text colour. See [AppColors.badge].
  static const badgeWornOutBg = Color(0xFFFEF2F2);
  static const badgeWornOutText = Color(0xFF991B1B);
  static const badgeDonationReviewBg = Color(0xFFFFF7ED);
  static const badgeDonationReviewText = Color(0xFFC2410C);
  static const badgeOverusedBg = Color(0xFFFEF2F2);
  static const badgeOverusedText = Color(0xFFB91C1C);
  static const badgeSkippedBg = Color(0xFFFEF2F2);
  static const badgeSkippedText = Color(0xFFB91C1C);
  static const badgeNeverWornBg = Color(0xFFFFFBEB);
  static const badgeNeverWornText = Color(0xFF92400E);
  static const badgeLongUnusedBg = Color(0xFFFFFBEB);
  static const badgeLongUnusedText = Color(0xFF92400E);
  static const badgeNewBg = Color(0xFFEFF6FF);
  static const badgeNewText = Color(0xFF1D4ED8);
  static const badgeMostWornBg = Color(0xFFF5F3FF);
  static const badgeMostWornText = Color(0xFF5B21B6);
  static const badgeNeutralBg = Color(0xFFF3F4F6);
  static const badgeNeutralText = Color(0xFF374151);

  // Amber used for "Medium" rotation / soft warning text.
  static const amberText = Color(0xFF92400E);

  // ── Outfit score colour bands (Generator card + Outfit Detail header) ──
  // Soft semantic tints (fixed, like badges — readable on light + dark cards).
  // 80–100 green (Strong) · 60–79 amber (Fair) · 1–59 red (Weak).
  static (Color bg, Color fg) scoreBandColours(int score) {
    if (score >= 80) return (primaryLight, darkPrimaryText); // green
    if (score >= 60) return (badgeNeverWornBg, badgeNeverWornText); // amber
    return (badgeWornOutBg, badgeWornOutText); // red
  }

  // ── Utilisation rate fill colour (Home snapshot + Insights later) ──
  // DIFFERENT metric from outfit score → its own bands (muted, theme-fitting):
  // 70–100 green (good) · 40–69 amber (moderate) · 0–39 red (low).
  static const utilisationAmber = Color(0xFFCA8A04); // muted gold
  static Color utilisationFill(int pct) {
    if (pct >= 70) return primary; // muted brand green
    if (pct >= 40) return utilisationAmber;
    return danger;
  }

  static const favouriteStar = Color(0xFFFACC15); // is_favorite star
  static const chevron = Color(0xFFC0BAB2); // ti-chevron-right

  // ── Clothing colour swatches (Style Preferences only, Frontend §1) ──
  // CRITICAL: these are clothing colours, NOT brand tokens. Do not reuse
  // brand Primary/Text-Tertiary here — see locked decisions #8/#9.
  static const swatchBlack = Color(0xFF1A1A1A);
  static const swatchWhite = Color(0xFFFFFFFF); // needs 1px border to be visible
  static const swatchGrey = Color(0xFF9CA3AF); // NOT textTertiary
  static const swatchBeige = Color(0xFFD4B896);
  static const swatchNavy = Color(0xFF1E3A5F);
  static const swatchBlue = Color(0xFF3B82F6);
  static const swatchRed = Color(0xFFDC2626);
  static const swatchGreen = Color(0xFF22C55E); // NOT brand primary
  static const swatchBrown = Color(0xFF8B5E3C);
  static const swatchYellow = Color(0xFFEAB308);
  static const swatchPink = Color(0xFFEC4899);
  static const swatchPurple = Color(0xFFA855F7);
}
