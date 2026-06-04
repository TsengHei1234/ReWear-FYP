/// Spacing and border-radius tokens.
///
/// Source of truth: Frontend Reference §3 "Spacing" (4dp base grid) and
/// §4 "Border Radius".
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16; // standard page/card padding
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const double pagePadding = 16; // horizontal page padding
  static const double cardPadding = 16; // standard card padding
  static const double cardPaddingLarge = 20; // larger cards (Health Score)
  static const double cardGap = 12; // gap between cards
  static const double bottomNavHeight = 64;
  static const double topBarHeight = 56;
  static const double stickyButtonArea = 80;
}

/// Border-radius tokens. Frontend §4.
class AppRadius {
  AppRadius._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 12; // inputs, small cards, icon tiles
  static const double lg = 14; // primary/outlined buttons
  static const double xl = 18; // standard cards
  static const double xxl = 24; // bottom sheet top corners
  static const double full = 999; // chips, pills, toggles
}
