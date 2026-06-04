# Wardrobe App — Complete Frontend Reference

> **What this file is:** The single source of truth for building the Flutter frontend. Contains the full design system, every component specification, every page layout with design details, all interaction patterns, all locked decisions, and Flutter implementation notes. Another Claude or Codex reading this file should be able to build the frontend immediately.
>
> **Stack:** Flutter · Dart · Supabase
> **Font:** Plus Jakarta Sans (Google Fonts)
> **Theme:** Custom ThemeData (light + dark) — configured once in `app_theme.dart`

---

## Table of Contents

1. [Design System Tokens](#1-design-system-tokens)
2. [Typography Scale](#2-typography-scale)
3. [Spacing & Layout](#3-spacing--layout)
4. [Component Library](#4-component-library)
5. [Flutter Theme Configuration](#5-flutter-theme-configuration)
6. [Navigation Structure](#6-navigation-structure)
7. [Auth & Splash Screens](#7-auth--splash-screens)
8. [Onboarding Flow](#8-onboarding-flow)
9. [Home Page](#9-home-page)
10. [Wardrobe Page](#10-wardrobe-page)
11. [Outfit Page](#11-outfit-page)
12. [Donate Page](#12-donate-page)
13. [Insights Page](#13-insights-page)
14. [Profile & Settings](#14-profile--settings)
15. [Shared Bottom Sheets](#15-shared-bottom-sheets)
16. [Badge System](#16-badge-system)
17. [Section 4 Tab Options — All 3 Documented](#17-section-4-tab-options--all-3-documented)
18. [Colour Picker — Both Versions](#18-colour-picker--both-versions)
19. [Locked Design Decisions](#19-locked-design-decisions)

---

## 1. Design System Tokens

### 1.1 Light Theme Colours

```dart
// Background & Surface
kBackground   = Color(0xFFF7F4EF)  // warm off-white — scaffold background
kSurface      = Color(0xFFFFFFFF)  // white — cards, input fields
kSurface2     = Color(0xFFF0EDE6)  // slightly darker — dividers, tile backgrounds

// Text
kTextPrimary   = Color(0xFF1A1A1A)  // near-black — headings, body text
kTextSecondary = Color(0xFF6B6560)  // medium grey — sub-labels, descriptions
kTextTertiary  = Color(0xFF9B9490)  // light grey — placeholders, captions

// Border
kBorder        = Color(0xFFE6E1D8)  // soft warm border — cards, inputs
kBorderFocus   = Color(0xFFC8DEC8)  // green-tinted border — focused inputs

// Brand (Primary)
kPrimary       = Color(0xFF4A7055)  // sage green — primary actions, active states
kPrimaryMid    = Color(0xFF7FAF8C)  // mid green — secondary accents
kPrimaryLight  = Color(0xFFEBF2EC)  // very light green — chip backgrounds, icon tiles
kDarkPrimary   = Color(0xFF27500A)  // dark green — text on light green backgrounds
```

### 1.2 Dark Theme Colours

```dart
kDarkBackground  = Color(0xFF111511)  // very dark green-black — scaffold
kDarkSurface     = Color(0xFF181E18)  // dark surface — cards
kDarkSurface2    = Color(0xFF202820)  // slightly lighter — tiles
kDarkTextPrimary = Color(0xFFF0EFEC)  // near-white — headings
kDarkTextSecond  = Color(0xFF9E9C97)  // medium — sub-labels
kDarkTextTert    = Color(0xFF6B6965)  // light — placeholders
kDarkBorder      = Color(0xFF2C342C)  // dark border
kDarkPrimary     = Color(0xFF6BAF80)  // lighter green — primary actions in dark mode
```

### 1.3 Semantic / Badge Colours

```dart
// Worn out badge
kBadgeWornBg    = Color(0xFFFEF2F2)
kBadgeWornText  = Color(0xFF991B1B)

// Donation review badge
kBadgeDonBg     = Color(0xFFFFF7ED)
kBadgeDonText   = Color(0xFFC2410C)

// Overused / Skipped often badge
kBadgeRedBg     = Color(0xFFFEF2F2)
kBadgeRedText   = Color(0xFFB91C1C)

// Never worn / Long unused badge
kBadgeAmberBg   = Color(0xFFFFFBEB)
kBadgeAmberText = Color(0xFF92400E)

// New badge
kBadgeBlueBg    = Color(0xFFEFF6FF)
kBadgeBlueText  = Color(0xFF1D4ED8)

// Most worn badge
kBadgePurpleBg  = Color(0xFFF5F3FF)
kBadgePurpleText = Color(0xFF5B21B6)

// Status badges
kBadgeGrayBg   = Color(0xFFF3F4F6)
kBadgeGrayText = Color(0xFF374151)
```

### 1.4 Colour Swatch Hex Values (for Style Preferences screen)

These are the exact hex values used for the 12 colour swatches. They must NOT use app brand colours.

```dart
const Map<String, Color> kColourSwatches = {
  'black':  Color(0xFF1A1A1A),
  'white':  Color(0xFFFFFFFF),
  'grey':   Color(0xFF9CA3AF),  // neutral cool grey — NOT our text secondary (#9B9490)
  'beige':  Color(0xFFD4B896),
  'navy':   Color(0xFF1E3A5F),
  'blue':   Color(0xFF3B82F6),
  'red':    Color(0xFFDC2626),
  'green':  Color(0xFF22C55E),  // standard green — NOT our brand green (#4A7055)
  'brown':  Color(0xFF8B5E3C),
  'yellow': Color(0xFFEAB308),
  'pink':   Color(0xFFEC4899),
  'purple': Color(0xFFA855F7),
};
```

**Critical note:** Green swatch must be `#22C55E`, not `#4A7055`. Our brand colour `#4A7055` is the selection indicator. If the swatch matched the indicator, selected and unselected green swatches would look identical.

---

## 2. Typography Scale

**Font family:** Plus Jakarta Sans (load via `google_fonts` package)

```dart
// Display — large hero text on onboarding, splash
Display:  fontSize: 28, fontWeight: FontWeight.w700

// Title Large — page titles, section headings
TitleL:   fontSize: 22, fontWeight: FontWeight.w700

// Title Medium — card titles, sub-section headings
TitleM:   fontSize: 18, fontWeight: FontWeight.w600

// Title Small — list item names, bold labels
TitleS:   fontSize: 16, fontWeight: FontWeight.w600

// Body Large — main body text, form inputs
BodyL:    fontSize: 16, fontWeight: FontWeight.w400

// Body Medium — secondary body, descriptions
BodyM:    fontSize: 14, fontWeight: FontWeight.w400

// Body Small — sub-labels, item categories
BodyS:    fontSize: 13, fontWeight: FontWeight.w400  // (custom, not in Material scale)

// Label — chips, badges, counters, buttons
Label:    fontSize: 14, fontWeight: FontWeight.w500

// Label Small — badge text, counts, timestamps
LabelS:   fontSize: 12, fontWeight: FontWeight.w500  // (custom)

// Caption — section category labels, hints
Caption:  fontSize: 11, fontWeight: FontWeight.w500

// Micro — smallest labels, timestamps inside rows
Micro:    fontSize: 10, fontWeight: FontWeight.w600
```

**Section header labels** (e.g. "ACCOUNT", "APP"):
```dart
// Uppercase section labels
fontSize: 10 or 11, fontWeight: FontWeight.w700, letterSpacing: 0.08em, textTransform: uppercase, color: kTextTertiary
```

---

## 3. Spacing & Layout

### 3.1 Spacing Scale (4dp base grid)

```dart
kSpaceXS   = 4.0
kSpaceSM   = 8.0
kSpaceMD   = 12.0
kSpaceBase = 16.0
kSpaceLG   = 20.0
kSpaceXL   = 24.0
kSpace2XL  = 32.0
kSpace3XL  = 48.0
```

### 3.2 Border Radius Scale

```dart
kRadiusXS   = 6.0   // very small chips
kRadiusSM   = 10.0  // small chips, action buttons inside rows
kRadiusMD   = 12.0  // input fields, small cards, bottom sheet items
kRadiusLG   = 14.0  // primary buttons, medium cards
kRadiusXL   = 18.0  // main cards, bottom sheet
kRadius2XL  = 24.0  // bottom sheet top corners
kRadiusFull = 999.0 // fully rounded — chips, pills, toggles, score badges
```

### 3.3 Page Padding

- Screen horizontal padding: `16px` left and right
- Card internal padding: `16px`
- Card internal padding (large): `20px`
- Bottom nav height: `64px` (approx, including safe area)
- Top bar height: `56px`

### 3.4 Card Styling (standard)

```dart
// Standard white card
decoration: BoxDecoration(
  color: kSurface,
  borderRadius: BorderRadius.circular(kRadiusXL),  // 18px
  border: Border.all(color: kBorder, width: 0.5),
)
```

### 3.5 Dividers inside cards

```dart
// Between rows inside a card
Divider(height: 0.5, color: kSurface2)  // Color(0xFFF0EDE6)
```

---

## 4. Component Library

### 4.1 Buttons

**Primary Button (full width):**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: kPrimary,        // Color(0xFF4A7055)
    foregroundColor: Colors.white,
    minimumSize: Size(double.infinity, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
    elevation: 0,
  ),
)
```

**Outlined Button (full width):**
```dart
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: kPrimary,
    minimumSize: Size(double.infinity, 50),
    side: BorderSide(color: kPrimary, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
  ),
)
```

**Destructive Button (full width, red):**
- Same as outlined but: `foregroundColor: Color(0xFFB91C1C)`, `side: BorderSide(color: Color(0xFFB91C1C))`

**Small action button (inside cards, e.g. Keep/Donate):**
```dart
height: 36px, borderRadius: 8px, fontSize: 12px, fontWeight: w500
```

**FAB (Floating Action Button — Add Item):**
```dart
FloatingActionButton(
  backgroundColor: kPrimary,
  child: Icon(Icons.add, color: Colors.white, size: 26),
)
// Positioned: bottom-right, position: absolute inside Stack
```

---

### 4.2 Input Fields

**Standard text input:**
```dart
InputDecoration(
  filled: true,
  fillColor: kSurface,
  labelText: 'Field label',  // shown as floating label above field
  labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kTextSecondary),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(kRadiusMD),  // 12px
    borderSide: BorderSide(color: kBorder, width: 0.5),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(kRadiusMD),
    borderSide: BorderSide(color: kPrimary, width: 1.5),
  ),
  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
)
```

**Label above field pattern (used in auth screens):**
- `Text(label)` sits above the field as a separate widget (not floating inside field)
- Label: fontSize 11, fontWeight w600, color kTextSecondary
- Gap between label and field: 6px

**Password field:**
- Same as standard + trailing `IconButton(icon: Icon(ti-eye))` for show/hide toggle

---

### 4.3 Chips

**Filter chip (selected state):**
```dart
padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
decoration: BoxDecoration(
  color: kPrimary,
  borderRadius: BorderRadius.circular(kRadiusFull),
),
text: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)
```

**Filter chip (unselected state):**
```dart
decoration: BoxDecoration(
  color: kSurface,
  borderRadius: BorderRadius.circular(kRadiusFull),
  border: Border.all(color: kBorder, width: 0.5),
),
text: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: kTextSecondary)
```

**Occasion chip (read-only, on Item Detail):**
```dart
// Same shape as filter chip unselected but non-tappable, fontSize: 11
```

---

### 4.4 Toggle Switch (custom style)

Used for: Recommendation Mode, Notification Settings

```dart
// Custom appearance target:
// Width: 44px, Height: 26px, borderRadius: 999px
// On: background kPrimary (#4A7055), thumb right (22px white circle)
// Off: background kBorder (#E6E1D8), thumb left (22px white circle)

Switch(
  value: _isOn,
  onChanged: (val) => setState(() => _isOn = val),
  activeColor: Colors.white,
  activeTrackColor: kPrimary,
  inactiveThumbColor: Colors.white,
  inactiveTrackColor: kBorder,
)
```

---

### 4.5 Stepper (Laundry Cycle)

```dart
Row(
  children: [
    // Minus button
    GestureDetector(
      onTap: () => setState(() { if (_days > 1) _days--; }),
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: kSurface2, borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.remove, size: 14, color: kTextSecondary),
      ),
    ),
    // Value
    SizedBox(width: 16, child: Text('$_days', textAlign: TextAlign.center,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
    // Plus button
    GestureDetector(
      onTap: () => setState(() { if (_days < 14) _days++; }),
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(8)),
        child: Icon(Icons.add, size: 14, color: kPrimary),
      ),
    ),
  ],
)
```

---

### 4.6 Bottom Navigation Bar

**5 tabs:** Home · Wardrobe · Outfit · Donate · Insights

**Icons (Tabler Icons package):**
- Home: `ti-home`
- Wardrobe: `ti-shirt`
- Outfit: `ti-wand`
- Donate: `ti-heart`
- Insights: `ti-chart-bar`

**Active tab indicator:**
- Pill-shaped background (`kPrimaryLight` colour) behind active icon
- Icon colour changes to `kPrimary` when active
- Label below icon: fontSize 10, fontWeight w600 when active, w400 when inactive

**Implementation:**
```dart
BottomNavigationBar(
  type: BottomNavigationBarType.fixed,
  backgroundColor: kSurface,
  selectedItemColor: kPrimary,
  unselectedItemColor: kTextTertiary,
  selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600),
  unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w400),
  // Active pill: wrap selected icon in Container with kPrimaryLight background
)
```

---

### 4.7 Progress Bar (Wardrobe Utilisation)

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(999),
  child: LinearProgressIndicator(
    value: utilisationRate,     // 0.0 to 1.0
    backgroundColor: kSurface2, // Color(0xFFF0EDE6)
    valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
    minHeight: 8,
  ),
)
```

---

### 4.8 Health Score Ring (Circular Progress)

```dart
// Use CustomPainter or Stack with CircularProgressIndicator
// Ring: 130px × 130px
// Track stroke: 12px width, Color(0xFFF0EDE6)
// Progress stroke: 12px width, kPrimary, strokeCap: StrokeCap.round
// Rotation: -90 degrees (so progress starts from top)
// Score text inside: fontSize 32, fontWeight w700
// "/100" sub-label: fontSize 11, color kTextTertiary

// Using SizedBox + Transform.rotate + CircularProgressIndicator:
SizedBox(
  width: 130, height: 130,
  child: Stack(
    alignment: Alignment.center,
    children: [
      Transform.rotate(
        angle: -1.5708, // -90 degrees in radians
        child: CircularProgressIndicator(
          value: healthScore / 100,
          strokeWidth: 12,
          backgroundColor: Color(0xFFF0EDE6),
          valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
          strokeCap: StrokeCap.round,
        ),
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$healthScore', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
          Text('/ 100', style: TextStyle(fontSize: 11, color: kTextTertiary)),
        ],
      ),
    ],
  ),
)
```

---

### 4.9 Segmented Control (Outfit page tab selector)

Used for Daily Rotation / Outfit Generator tab selection.

```dart
SegmentedButton<int>(
  segments: [
    ButtonSegment(value: 0, label: Text('Daily Rotation')),
    ButtonSegment(value: 1, label: Text('Outfit Generator')),
  ],
  selected: {_selectedTab},
  onSelectionChanged: (selection) => setState(() => _selectedTab = selection.first),
  style: ButtonStyle(
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) return kSurface;
      return Color(0xFFEDEBE4);  // unselected segment background
    }),
    foregroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) return kTextPrimary;
      return kTextTertiary;
    }),
    textStyle: MaterialStatePropertyAll(
      GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
  ),
)
```

---

### 4.10 Wardrobe Item Card

```dart
// 2-column GridView
// Card height: ~220px (photo 196px tall + info area below)
Column(
  children: [
    // Photo area (196px tall)
    Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXL)),
          child: CachedNetworkImage(height: 196, fit: BoxFit.cover),
        ),
        // Last worn pill — top right
        Positioned(top: 8, right: 8,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
            child: Text('2d ago', style: TextStyle(fontSize: 10, color: Colors.white)),
          ),
        ),
        // Favourite star — top left (only if is_favorite == true)
        if (item.isFavorite)
          Positioned(top: 8, left: 8,
            child: Icon(Icons.star, color: Color(0xFFFACC15), size: 18)),  // yellow star
        // Status overlay (if not IN_WARDROBE)
        if (item.status != 'IN_WARDROBE')
          Positioned.fill(child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusXL)),
            ),
          )),
      ],
    ),
    // Info area
    Container(
      padding: EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(item.name, style: TitleS, overflow: TextOverflow.ellipsis)),
            // Badge chip (highest priority only)
            _buildBadge(item),
          ]),
          Text('${item.category} · ${item.type}', style: BodyS.copyWith(color: kTextTertiary)),
        ],
      ),
    ),
  ],
)
```

---

### 4.11 Settings Menu Row

Used throughout Profile & Settings.

```dart
// Standard settings row with icon tile + label + chevron
Container(
  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  decoration: BoxDecoration(
    border: Border(bottom: BorderSide(color: kSurface2, width: 0.5))),
  child: Row(
    children: [
      // Icon tile
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(9)),
        child: Icon(iconData, size: 16, color: kPrimary),
      ),
      SizedBox(width: 12),
      // Label (+ optional sub-label)
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: BodyS.copyWith(fontWeight: FontWeight.w600)),
          if (subLabel != null)
            Text(subLabel, style: Caption.copyWith(color: kTextTertiary)),
        ],
      )),
      // Trailing: chevron, toggle, or stepper
      trailing,
    ],
  ),
)
```

---

## 5. Flutter Theme Configuration

**File:** `lib/core/theme/app_theme.dart`

This file is written once during Phase 1. After setup, all screens automatically inherit the styling. Individual screen code uses standard Flutter widgets (ElevatedButton, TextFormField, etc.) — the theme handles all visual customisation.

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand colours ──────────────────────────────────────────
  static const kPrimary      = Color(0xFF4A7055);
  static const kPrimaryLight = Color(0xFFEBF2EC);
  static const kBackground   = Color(0xFFF7F4EF);
  static const kSurface      = Color(0xFFFFFFFF);
  static const kTextPrimary  = Color(0xFF1A1A1A);
  static const kTextSecond   = Color(0xFF6B6560);
  static const kTextTert     = Color(0xFF9B9490);
  static const kBorder       = Color(0xFFE6E1D8);

  // ── Dark colours ───────────────────────────────────────────
  static const kDarkBg      = Color(0xFF111511);
  static const kDarkSurface = Color(0xFF181E18);
  static const kDarkPrimary = Color(0xFF6BAF80);
  static const kDarkText    = Color(0xFFF0EFEC);

  // ── Light Theme ─────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kBackground,
    colorScheme: const ColorScheme.light(
      primary: kPrimary,
      surface: kSurface,
      onPrimary: Colors.white,
      onSurface: kTextPrimary,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: kTextPrimary,
      displayColor: kTextPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11, fontWeight: FontWeight.w600, color: kTextSecond),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimary,
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: kPrimary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardTheme(
      color: kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: kBorder, width: 0.5),
      ),
    ),
  );

  // ── Dark Theme ──────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kDarkBg,
    colorScheme: const ColorScheme.dark(
      primary: kDarkPrimary,
      surface: kDarkSurface,
      onPrimary: Colors.white,
      onSurface: kDarkText,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: kDarkText,
      displayColor: kDarkText,
    ),
    // Mirror light theme structure with dark tokens
  );
}
```

**In `main.dart`:**
```dart
MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ThemeMode.system,  // follows device. User can override in App Theme settings.
  home: SplashScreen(),
)
```

---

## 6. Navigation Structure

**Router:** `go_router` package

**Route structure:**
```
/splash             → SplashScreen
/login              → LoginScreen
/register           → RegisterScreen
/forgot-password    → ForgotPasswordScreen
/onboarding         → OnboardingFlow (4 pages)
/home               → MainShell (bottom nav)
  /home             → HomeScreen
  /wardrobe         → WardrobeScreen
    /wardrobe/add   → AddItemScreen
    /wardrobe/:id   → ItemDetailScreen
    /wardrobe/:id/edit → EditItemScreen
    /wardrobe/:id/history → FullWearHistoryScreen
  /outfit           → OutfitScreen
    /outfit/detail  → OutfitDetailScreen
    /outfit/history → OutfitHistoryScreen
  /donate           → DonateScreen
    /donate/kept    → KeptItemsScreen
    /donate/history → DonationHistoryScreen
  /insights         → InsightsScreen
    /insights/never-worn   → ViewAllNeverWornScreen
    /insights/long-unused  → ViewAllLongUnusedScreen
    /insights/skipped      → ViewAllSkippedScreen
    /insights/overused     → ViewAllOverusedScreen
    /insights/sleeping     → ViewAllSleepingScreen
/settings           → ProfileSettingsScreen (pushed over shell)
  /settings/profile → MyProfileScreen
  /settings/style   → StylePreferencesScreen
  /settings/theme   → AppThemeScreen
  /settings/notifs  → NotificationSettingsScreen
  /settings/privacy → DataPrivacyScreen
  /settings/about   → HelpAboutScreen
```

**Auth Guard:** `go_router` redirect checks Supabase session. Unauthenticated users redirected to `/login`. Authenticated users redirected away from auth screens.

---

## 7. Auth & Splash Screens

### 7.1 Splash Screen

**Background:** `kPrimary` (#4A7055) — full screen green
**Layout:** Centred column

```
[App icon tile]    — 80×80px, borderRadius 22px, background rgba(white, 0.15),
                     border: rgba(white, 0.25) 1.5px, shirt icon 38px white
[SizedBox 16]
["Wardrobe"]       — 28px, w700, white
[SizedBox: 180px to bottom]
[CircularProgressIndicator]  — white, strokeWidth 2.5, size 24px, at bottom
```

**Two-layer implementation:**
1. Native splash (`flutter_native_splash`): green background + centred icon only. Shows before Flutter engine starts. Configure in `pubspec.yaml`.
2. Flutter splash (this screen): runs during `supabase.auth.onAuthStateChange`. Navigates to `/home` or `/login` when session resolved.

---

### 7.2 Login Screen

**Background:** `kBackground`
**Layout:** Centred column, horizontal padding 24px, top padding 32px

```
[App icon]         — 60×60px, borderRadius 18px, kPrimary bg, shirt icon 28px white
[SizedBox 16]
["Welcome back"]   — 24px, w700, kTextPrimary
["Sign in to your account"]  — 13px, kTextTertiary
[SizedBox 28]
[Label "Email address"]  — 11px, w600, kTextSecondary
[SizedBox 6]
[Email TextFormField]
[SizedBox 12]
[Label "Password"]
[SizedBox 6]
[Password TextFormField + eye icon]
[SizedBox 8]
["Forgot Password?"]    — 12px, w600, kPrimary, right-aligned
[SizedBox 24]
[Sign In ElevatedButton]
[SizedBox 12]
["Don't have an account? Sign Up"]  — 13px, kTextTertiary + kPrimary link
```

---

### 7.3 Sign Up Screen

**Background:** `kBackground`
**Layout:** Centred column, horizontal padding 24px, top padding 28px

```
[App icon]         — same as Login
[SizedBox 16]
["Create account"] — 24px, w700
["Start managing your wardrobe"]  — 13px, kTextTertiary
[SizedBox 24]
[Label + TextFormField: Display name]
[SizedBox 12]
[Label + TextFormField: Email]
[SizedBox 12]
[Label + TextFormField: Password (eye toggle)]
[SizedBox 12]
[Label + TextFormField: Confirm password (eye toggle)]
[SizedBox 24]
[Create Account ElevatedButton]
[SizedBox 12]
["Already have an account? Sign In"]
```

---

### 7.4 Forgot Password Screen

**Background:** `kBackground`
**Has top bar:** Back arrow left, "Forgot Password" title centred

```
[SizedBox 32]
[Lock icon tile]   — 60×60px, borderRadius 18px, kPrimaryLight bg, lock icon 28px kPrimary
[SizedBox 16]
["Reset your password"]  — 20px, w700
[Explanation text]       — 13px, kTextTertiary, lineHeight 1.5
[SizedBox 28]
[Label + TextFormField: Email]
[SizedBox 24]
[Send Reset Link ElevatedButton]
[SizedBox 12]
["Remembered it? Back to Sign In"]
```

**Success state:** Form hidden, replaced with centered confirmation message: "Check your email for a reset link." + "Back to Sign In" button.

---

## 8. Onboarding Flow

### 8.1 Page 1 — Welcome

**Background:** `kBackground`
**No top bar, no Skip button**

```
[SizedBox 40]
[App icon]          — 88×88px, borderRadius 24px, kPrimary bg, shirt icon 42px white
[SizedBox 28]
["Meet your smarter wardrobe"]   — 26px, w700, centred
[SizedBox 12]
[App description]   — 14px, kTextSecondary, lineHeight 1.6, centred, horizontal padding 28px
[SizedBox 48]
[Progress dots]     — dot 1 active (22px wide, kPrimary), dots 2-4 (6px, kBorder)
[SizedBox 32]
[Get Started ElevatedButton]   — horizontal margin 28px
```

**Progress dots pattern:**
- Active dot: `width: 22px, height: 6px, borderRadius: 999, color: kPrimary`
- Inactive dot: `width: 6px, height: 6px, borderRadius: 999, color: kBorder`
- Gap between dots: 6px

---

### 8.2 Page 2 — Style Preferences

**Background:** `kBackground`
**Has "Skip" (top right, 12px w600 kTextTertiary)**

```
[SizedBox 12]
["Your colour style"]        — 22px, w700
["We'll use this to personalise..."]  — 13px, kTextTertiary, lineHeight 1.5
[SizedBox 20]
[Section header row: "COLOURS I LOVE" (11px, w700, uppercase, kPrimary) + "2/3" counter (right, kPrimary)]
[SizedBox 10]
[Colour swatch grid]         — see Section 18 below for both versions
[SizedBox 20]
[Section header row: "COLOURS I DISLIKE" (11px, w700, uppercase, #B91C1C) + "1/3" counter]
[SizedBox 10]
[Colour swatch grid]         — same 12 swatches, mutual exclusivity applied
[SizedBox 24]
[Progress dots — dot 2 active]
[SizedBox 20]
[Next ElevatedButton]
```

---

### 8.3 Page 3 — Recommendation Mode

**Background:** `kBackground`
**Has "Skip" (top right)**

```
[SizedBox 12]
["How should we recommend?"]   — 22px, w700
[Short explanation]            — 13px, kTextTertiary, lineHeight 1.5
[SizedBox 24]
[Card: Balanced Rotation]      — selected state (green 2px border)
  Row: green filled radio + "Balanced Rotation" label + "Recommended" green badge
  Description: 12px, kTextSecondary, indent 30px, lineHeight 1.5
[SizedBox 10]
[Card: Pure Rotation]          — unselected (0.5px kBorder)
  Row: empty radio + "Pure Rotation" label
  Description: 12px, kTextSecondary, indent 30px, lineHeight 1.5
[SizedBox 28]
[Progress dots — dot 3 active]
[SizedBox 20]
[Next ElevatedButton]
```

**Mode cards:**
- Selected: `border: Border.all(color: kPrimary, width: 2)`, `borderRadius: 16px`
- Unselected: `border: Border.all(color: kBorder, width: 0.5)`, `borderRadius: 16px`
- "Recommended" badge: `background: kPrimaryLight, color: kDarkPrimary, fontSize: 10, fontWeight: w600, padding: 2px 8px, borderRadius: 999`

---

### 8.4 Page 4 — Notifications

**Background:** `kBackground`
**Has "Not Now" (top right — NOT "Skip")**

```
[SizedBox 12]
[Bell icon tile]      — 60×60px, borderRadius 18px, kPrimaryLight bg, bell icon 28px kPrimary
[SizedBox 16]
["Stay on top of your wardrobe"]   — 22px, w700
[Explanation text]                 — 13px, kTextTertiary, lineHeight 1.5
[SizedBox 20]
[Feature card]                     — white card, 16px padding, 16px radius, 3 feature rows
  Each row: 28×28px icon tile (kPrimaryLight bg) + name (12px w600) + description (11px kTextTertiary)
  Feature 1: clock icon — "Daily outfit reminders" — "Keep your wear history up to date"
  Feature 2: shirt icon — "Long-unworn alerts" — "Items that haven't been worn recently"
  Feature 3: chart icon — "Weekly summary" — "Your wardrobe stats every week"
[SizedBox 20]
[Progress dots — dot 4 active]
[SizedBox 20]
[Allow Notifications ElevatedButton]
```

---

## 9. Home Page

### Layout

**Top bar:**
- Left: greeting text (e.g. "Good morning, Tseng Hei") — 22px w700 as page title area. Greeting adapts by time (Good morning / afternoon / evening)
- Right: profile avatar (36×36px circle, kPrimary bg, white initials 12px w700) — tappable → Profile & Settings

**Scrollable content (vertical, padding 16px):**
```
[Occasion chips]       — horizontal scroll, single select, gap 8px
[SizedBox 16]
[Today's Suggestions]  — section label + PageView carousel
[SizedBox 16]
[Wardrobe Snapshot]    — white card
```

### Occasion Chips
Labels: All · Casual · Work · Active · Relax
Default selected: All

### Today's Suggestions Carousel

```dart
PageView.builder(
  controller: PageController(viewportFraction: 0.88),  // shows bleed of next card
  itemCount: 3,
)
```

**Each suggestion card:**
- Photo: full width, `height: 210px`, `borderRadius: 16px`, `BoxFit.cover`
- Score pill: bottom-left over photo, black semi-transparent bg, white text, fontSize 11, borderRadius 999
- Reason badge: bottom-right over photo, category badge style
- Below photo: item name (14px w700) + category·type (12px kTextTertiary)
- Button row: "Wear Today" (small primary) + "View Item" (small outlined)
- Card padding: 12px, borderRadius: 18px, white bg, kBorder border

### Wardrobe Snapshot Card
White card, 16px padding, 18px radius

```
["Wardrobe Snapshot"]   — 12px, w700, section label
[SizedBox 12]
["Utilisation Rate"]    — 12px, kTextSecondary
[Progress bar]          — 8px height, kPrimary fill, kSurface2 track
[SizedBox 12]
[Row of 2 tiles]
  [Active Rotation: N items]   — kPrimaryLight bg, rounded
  [Dormant Items: N items]     — kSurface2 bg, rounded
[SizedBox 12]
["N items for donation review →"]  — 12px w600 kPrimary, tappable → Donate tab
```

---

## 10. Wardrobe Page

### Layout

**Top bar:**
- Title: "Wardrobe" (22px w700)
- Subtitle: "48 items" (12px kTextTertiary) — below title or beside it
- Right: profile avatar

**Scrollable content:**
```
[Search bar]           — full width, 12px radius, kSurface bg, kBorder border
[SizedBox 12]
[Category chips row]   — scroll + Filter button right
[Count label]          — e.g. "All Items · 48" or "Tops · 18"
[SizedBox 12]
[2-column item grid]
```

**FAB:** Green + icon, bottom-right, `position: absolute` inside `Stack`

### Filter Bottom Sheet
- Drag handle at top
- "Filter" title
- Occasion multi-select chips
- Status multi-select chips
- Sort by single-select (RadioListTile)
- Favourites toggle (Switch)
- "Apply" button (ElevatedButton, full width)

### 10.1 Add Item Screen

**Top bar:** Back arrow + "Add Item" title + "Save" text button (top right, kPrimary)

**Form sections (vertically scrollable):**

**Photo:**
```
Square container, dashed border (kBorder), borderRadius 14px
Placeholder: ti-camera icon centred
Tapping: opens image picker (camera or gallery)
Uploaded: shows image, overlay "Change Photo" button appears
```

**Basic Info (white card):**
- Item Name: TextFormField
- Category: single-select dropdown → updates Type options
- Type: single-select dropdown (options from category)
- Colour: single-select dropdown (12 colours)
- Condition: single-select (Excellent · Good · Fair · Worn · Damaged)
- Condition Review: segmented toggle (Auto / Manual)

**Occasion Tags (white card):**
- Multi-select chips: Casual · Work · Active · Relax
- Selected chips: kPrimary fill, white text
- Unselected: white bg, kBorder border, kTextSecondary text

**Item History (white card):**
Two radio options (full-width radio tiles):
- "Brand new — never worn before" → `is_new_item = true`
- "I already own and have worn this" → `is_new_item = false`

If second option selected, 3 additional fields expand:
- Approximate last worn: date picker
- Estimated wear count: number field
- How long owned: dropdown (Less than 1 month / 1–3 months / 3–6 months / 6–12 months / Over 1 year)

**Bottom (sticky):**
- "Save to Wardrobe" ElevatedButton, full width

---

### 10.2 Item Detail Screen

**Full-bleed photo:** `width: double.infinity`, aspect ratio 1:1

**Floating icon row over photo:**
```dart
Positioned(top: safeArea + 8, left: 16, right: 16,
  child: Row(
    children: [
      CircleIconButton(icon: ti-arrow-left, bg: white),  // back
      Spacer(),
      CircleIconButton(icon: ti-star, bg: white),         // favourite (filled yellow if true)
      SizedBox(8),
      CircleIconButton(icon: ti-edit, bg: white),         // edit
      SizedBox(8),
      CircleIconButton(icon: ti-trash, bg: white),        // delete (red icon)
    ],
  ),
)
```

`CircleIconButton`: 36×36px white circle, light shadow, icon 18px

**Below photo (scrollable, 16px padding):**
```
[Item name]           — 22px, w700
[Category · Type · Colour]  — 13px, kTextTertiary
[SizedBox 10]
[Occasion chips]      — read-only, non-tappable
[SizedBox 10]
[All applicable badges]   — all matching badges shown (not just top priority)
[SizedBox 16]
[Stats row: 3 tiles]
  Wears: N | Last worn: X days | Skipped: N
  Each tile: kSurface2 bg, 12px radius, 12px padding
[SizedBox 12]
[Status & Condition row: 2 chips side by side]
[SizedBox 16]
[Rule-Based Usage Summary card]
  4 rows: Rotation Priority · Wear Balance · Skip Feedback · Donation Review
  Each row: label (13px w600) + value (13px kPrimary or amber/red) + icon
[SizedBox 12]
[Consider Donating button]   — ghost red outlined, ONLY shown if D-rule flagged
[SizedBox 16]
[Recent Wear History card]
  2 event rows + "View All →" link
[SizedBox 80]  — space for sticky buttons
```

**Sticky buttons at bottom (above bottom nav):**
```
[Log Wear ElevatedButton]     — left half
[Build Outfit OutlinedButton] — right half
Side by side with 8px gap
```

---

### 10.3 Edit Item Screen

Same as Add Item with:
- All fields pre-filled
- Photo shows current image with "Change Photo" overlay
- No Item History section
- Notice text: "Item history is locked after adding."
- "Save Changes" sticky button

---

### 10.4 Full Wear History Screen

**Top bar:** Back arrow + "Wear History · N"
**White card list:**
Each row: `date left · icon right (green tick = WORN, grey skip = SKIPPED)`
`padding: 12px 14px, borderBottom: 0.5px kSurface2`

---

## 11. Outfit Page

**Tab control:** Segmented pill (see Component 4.9)
**Two tabs:** Daily Rotation · Outfit Generator

### 11.1 Daily Rotation Tab

**Layout (vertical scroll):**
```
[Occasion chips]      — single select, All default
[SizedBox 10]
[Layers chips]        — single select, All default
[SizedBox 16]
["Top 5 Rotation Picks"]  — 12px, w700, section label
[SizedBox 10]
[5 recommendation cards]
```

**Recommendation card (horizontal layout):**
```dart
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16),
    border: Border.all(color: kBorder, width: 0.5)),
  child: Column(children: [
    Row(children: [
      // Left: photo + score
      Column(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(width: 88, height: 88, fit: BoxFit.cover)),
        SizedBox(4),
        // Score pill: FRS × 100 rounded, kPrimary bg
        Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(999)),
          child: Text('${(frs * 100).round()}', style: TextStyle(fontSize: 11, color: Colors.white))),
      ]),
      SizedBox(12),
      // Right: info
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: BodyS.copyWith(fontWeight: FontWeight.w600)),
        Text('$category · $type', style: Caption.copyWith(color: kTextTertiary)),
        SizedBox(4),
        _buildRotationPriorityBadge(tds),  // High/Medium/New
        SizedBox(4),
        Row(children: [Icon(ti-clock, 12), Text('Last worn: ${daysSinceWorn}d ago', fontSize: 11)]),
        Row(children: [Icon(ti-rotate, 12), Text('Worn $wearCount times', fontSize: 11)]),
      ])),
    ]),
    SizedBox(10),
    // Buttons row
    Row(children: [
      Expanded(child: OutlinedButton(child: Text('Wear'))),
      SizedBox(8),
      Expanded(child: OutlinedButton(child: Text('Skip'))),
    ]),
    SizedBox(6),
    SizedBox(width: double.infinity,
      child: ElevatedButton(child: Text('Build Outfit'))),
  ]),
)
```

**Rotation Priority badge colours:**
- TDS ≥ 0.8: background `kBadgeRedBg`, text `kBadgeRedText`, label "High Rotation Priority"
- TDS 0.5–0.8: background `kBadgeAmberBg`, text `kBadgeAmberText`, label "Medium Rotation Priority"
- wear_count==0 AND is_new_item: background `kBadgeBlueBg`, text `kBadgeBlueText`, label "New Item"

---

### 11.2 Outfit Generator Tab

**Layout:**
```
["OCCASION"]        — 10px, w700, uppercase, kTextTertiary
[Occasion chips]    — single select, no "All", Casual default
[SizedBox 10]
["LAYERS"]          — same label style
[Layers chips row]
  Top (locked, green) · Bottom (locked, green) · Outerwear (toggle) · Shoes (toggle)
[SizedBox 10]
[Pinned item strip] — conditional, green bg, thumbnail + "PINNED" + name + × button
[SizedBox 10]
[Generate Outfit button]   — OR [Regenerate] after first generation
[Results below after generation]
```

**Layers locked chips:**
```dart
// Top and Bottom always appear as selected/green but are NOT tappable
// Show lock icon (ti-lock, 10px) beside the label
// Tap: no response (GestureDetector with empty onTap or `enabled: false` if FilterChip)
```

**Pinned item strip:**
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(color: kPrimaryLight, borderRadius: BorderRadius.circular(12)),
  child: Row(children: [
    ClipRRect(borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(width: 36, height: 36, fit: BoxFit.cover)),
    SizedBox(8),
    Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(4)),
      child: Text('PINNED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
    SizedBox(6),
    Expanded(child: Text(pinnedItem.name, style: BodyS.copyWith(fontWeight: FontWeight.w600))),
    IconButton(icon: Icon(Icons.close, size: 16, color: kTextSecondary),
      onPressed: () => setState(() => _pinnedItem = null)),
  ]),
)
```

**Result cards:**
```dart
GestureDetector(
  onTap: () => context.push('/outfit/detail', extra: outfit),
  child: Container(
    padding: EdgeInsets.all(14),
    decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: kBorder, width: 0.5)),
    child: Column(children: [
      Row(children: [
        // Score pill
        Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(999)),
          child: Text('${(outfitScore * 100).round()}', style: TextStyle(color: Colors.white, fontSize: 11))),
        SizedBox(6),
        // Occasion chip
        Text(occasion, style: BodyS.copyWith(color: kTextSecondary)),
        Spacer(),
        // ? circle
        Container(width: 22, height: 22,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: kBorder)),
          child: Icon(Icons.question_mark, size: 12, color: kTextTertiary)),
      ]),
      SizedBox(10),
      // Item thumbnails (sizes based on count)
      Row(children: _buildOutfitThumbnails(outfit.items)),
      SizedBox(8),
      Text(reasonTag, style: Caption.copyWith(color: kTextSecondary)),
    ]),
  ),
)
```

Thumbnail sizes: `itemCount == 2 → 80px`, `itemCount == 3 → 66px`, `itemCount == 4 → 58px`

---

### 11.3 Outfit Detail Screen

**Top bar:** Back arrow + "Outfit Detail" title

```
[Header row]          — OutfitScore pill + Occasion chip + "N items" text
[SizedBox 16]
["Items in this Outfit"]   — 12px, w700, section label
[White card: item list]
  Each row: 48×48px thumbnail + name + category + badge chip + chevron
[SizedBox 16]
["Why this outfit?"]  — section label
[4 checkmark reason rows]
  Each: ti-check icon (kPrimary) + reason text (13px)
[SizedBox 16]
["Rule Breakdown"]    — section label
[White card: 5 rule rows]
  Temporal Decay    | Due for rotation / Recently worn
  Skip Penalty      | Clear / Warning
  Wear Balance      | Balanced / Check
  Formality Match   | Matched
  Colour Compat     | Compatible / Soft Warning (amber if warning)
[SizedBox 80]
```

**Sticky bottom buttons:**
```
[Log Wear ElevatedButton]        — full width
[SizedBox 8]
[Skip Outfit OutlinedButton]     — full width, destructive red style
```

---

## 12. Donate Page

### Layout

**Top bar:** "Donate" title + red count badge + profile avatar

```
[Header card]               — white card
  "Donation Candidates" + count badge
  Helper text (13px kTextTertiary)
[SizedBox 12]
[Shortcut tiles]             — 2 columns
  Kept Items | Donation History
[SizedBox 12]
[Filter chips]               — All · Never Worn · Long Unused · Skipped Often
[SizedBox 12]
[Donation candidate cards]   — list, sorted by DPS
```

**Shortcut tiles:**
```dart
Row(children: [
  Expanded(child: GestureDetector(
    onTap: () => context.push('/donate/kept'),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder, width: 0.5)),
      child: Row(children: [
        Text('Kept Items', style: BodyS.copyWith(fontWeight: FontWeight.w600)),
        Spacer(),
        Icon(Icons.arrow_forward, size: 16, color: kTextTertiary),
      ]),
    ),
  )),
  SizedBox(8),
  Expanded(child: /* Donation History tile */)
])
```

**Donation candidate card:**
```dart
Container(
  margin: EdgeInsets.only(bottom: 10),
  decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16),
    border: Border.all(color: kBorder, width: 0.5)),
  child: Column(children: [
    // Card body (tappable → Item Detail)
    Padding(
      padding: EdgeInsets.all(12),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(width: 72, height: 72, fit: BoxFit.cover)),
        SizedBox(12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: BodyS.copyWith(fontWeight: FontWeight.w700)),
          Text('$category · $type', style: Caption.copyWith(color: kTextTertiary)),
          SizedBox(4),
          Row(children: [
            Icon(reasonIcon, size: 13, color: kTextSecondary),
            SizedBox(4),
            Text(reasonText, style: Caption.copyWith(color: kTextSecondary)),
          ]),
          Text('Condition: $conditionLabel', style: Caption.copyWith(color: kTextTertiary)),
        ])),
      ]),
    ),
    // Button row
    Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(children: [
        Expanded(child: OutlinedButton(onPressed: _showKeepSheet, child: Text('Keep'))),
        SizedBox(8),
        Expanded(child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Color(0xFFB91C1C),
            side: BorderSide(color: Color(0xFFB91C1C))),
          onPressed: _showDonateSheet,
          child: Text('Donate'))),
      ]),
    ),
  ]),
)
```

---

### 12.1 Kept Items Screen

**Top bar:** Back + "Kept Items"
**White card list (no chevrons):**
Each row: `thumbnail + name + "Returns in X days" OR "Kept indefinitely" + "Undo Keep" button`
"Undo Keep": small outlined button, right side, clears `kept_until`

---

### 12.2 Donation History Screen

**Top bar:** Back + "Donation History"
**Category chips:** All · Tops · Bottoms · Outerwear · Shoes
**White card list (chevrons → read-only detail future):**
Each row: `thumbnail + name + "Donated on [date]" + chevron`

---

## 13. Insights Page

### Section 1 — Wardrobe Health Score (white card)

```
[Section label: "Wardrobe Health Score"]
[SizedBox 16]
[Centered column]
  [Health Score Ring]   — 130×130px (see Component 4.8)
  [SizedBox 10]
  [Verdict text]        — 13px, w600, kTextPrimary, centred
  [Sub-label]           — 11px, kTextTertiary, centred
[SizedBox 16]
[Row: 2 sub-score tiles]
  Utilisation %: kSurface2 bg, 12px radius, centred, "54%" 22px w700 kPrimary + "Utilisation" 11px
  Rotation %: same structure
```

---

### Section 2 — Quick Stats (white card)

```dart
GridView.count(
  crossAxisCount: 2,
  shrinkWrap: true,
  mainAxisSpacing: 8,
  crossAxisSpacing: 8,
  childAspectRatio: 1.6,
  children: [
    _StatTile('Total Items', totalItems, kSurface2, kTextPrimary, tappable: false),
    _StatTile('Worn This Month', wornThisMonth, Color(0xFFEFF6FF), Color(0xFF1D4ED8), tappable: false),
    _StatTile('Never Worn', neverWorn, kBadgeAmberBg, kBadgeAmberText, tappable: false),
    _StatTile('Donate Candidates', donateCount, kBadgeRedBg, kBadgeRedText,
      tappable: true, onTap: () => _switchToDonateTab()),
  ],
)
```

Each stat tile: `number (22px w700) + label (11px)`

---

### Section 3 — Wardrobe Utilisation (white card)

```
[Row: "Used this month" + "54% (20 of 37 items)"]
[SizedBox 6]
[Progress bar]
[Divider, SizedBox 10]
[Row: "9 items not worn in 90+ days" + "View All →" (kPrimary)]
[SizedBox 10]
[Hint: "Utilisation makes up 50% of your Health Score" — 11px italic kTextTertiary]
```

---

### Section 4 — Items That Need Attention (white card)

**Primary implementation: Option A (Scrollable TabBar + gradient fade)**
See full documentation in Section 17 below.

```
[Section label: "Items That Need Attention"]
[SizedBox 12]
[Tab row with gradient fade]
[SizedBox 12]
[TabBarView — 3 item rows per tab + View All link]
```

**Each item row:**
```dart
GestureDetector(
  onTap: () => context.push('/wardrobe/${item.id}'),
  child: Container(
    padding: EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(border: Border(
      bottom: BorderSide(color: Color(0xFFF0EDE6), width: 0.5))),
    child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(width: 46, height: 46, fit: BoxFit.cover)),
      SizedBox(10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: BodyS.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        Text(subLabel, style: Caption.copyWith(color: kTextTertiary)),
      ])),
      SizedBox(8),
      // Tab-specific badge
      _buildTabBadge(item, activeTab),
      SizedBox(4),
      Icon(Icons.chevron_right, size: 18, color: Color(0xFFC0BAB2)),
    ]),
  ),
)
```

---

## 14. Profile & Settings

### Main Page

**Top bar:** Back arrow + "Profile & Settings" title

**User card (white, 18px radius, centred):**
```
Avatar circle: 72×72px, kPrimary bg, initials 24px w700 white
Name: 16px w700
Email: 12px kTextTertiary
```

**Section groups (each group: white card, 16px radius):**
- Between groups: section label (10px w700 uppercase kTextTertiary)
- Between rows inside card: 0.5px kSurface2 border-bottom

**Account section:**
- My Profile → chevron
- Style Preferences → chevron

**App section:**
- Recommendation Mode → icon tile + label "Balanced Rotation" sub-label + inline Switch toggle
- Laundry Cycle → icon tile + label + inline stepper (− N +)
- App Theme → icon tile + "System default" sub-label + chevron

**Notifications section:**
- Notification Settings → chevron

**More section:**
- Data & Privacy → chevron
- Help / About → "Version 1.0.0" sub-label + chevron

**Log Out (separate red card):**
```dart
Container(
  decoration: BoxDecoration(
    color: Color(0xFFFEF2F2),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Color(0xFFFECACA), width: 0.5),
  ),
  child: ListTile(
    leading: Container(width: 34, height: 34,
      decoration: BoxDecoration(color: Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(9)),
      child: Icon(Icons.logout, size: 16, color: Color(0xFFB91C1C))),
    title: Text('Log Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C))),
    onTap: _handleLogout,
  ),
)
```

---

### 14.1 App Theme Screen

**Top bar:** Back + "App Theme"
**White card, RadioListTile for each option:**

```dart
// Three options with RadioListTile
Column(children: [
  _ThemeOption(value: ThemeMode.light, label: 'Light',
    description: 'Always use light mode', icon: Icons.light_mode),
  _ThemeOption(value: ThemeMode.dark, label: 'Dark',
    description: 'Always use dark mode', icon: Icons.dark_mode),
  _ThemeOption(value: ThemeMode.system, label: 'System Default',
    description: 'Follow device setting', icon: Icons.phone_android),
])

// Active radio: kPrimary filled circle with white dot
// Inactive radio: kBorder outlined circle
```

Saves to `SharedPreferences` (local storage, not Supabase).

---

### 14.2 Notification Settings Screen

**Top bar:** Back + "Notification Settings"
**One white card with 6 toggle rows:**

```dart
// Each row:
Padding(
  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  child: Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: BodyS.copyWith(fontWeight: FontWeight.w600)),
      SizedBox(2),
      Text(description, style: Caption.copyWith(color: kTextTertiary)),
    ])),
    Switch(value: _notifToggles[n], onChanged: (v) => _updateToggle(n, v),
      activeTrackColor: kPrimary, inactiveTrackColor: kBorder),
  ]),
)
```

---

## 15. Shared Bottom Sheets

### Universal Pattern

```dart
void showAppBottomSheet(BuildContext context, {
  Widget? itemPreview,
  required String title,
  required String description,
  required String confirmLabel,
  required Color confirmColor,
  required VoidCallback onConfirm,
}) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Container(width: 36, height: 4, margin: EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(999))),
        // Optional item preview
        if (itemPreview != null) ...[itemPreview, SizedBox(12)],
        // Title
        Text(title, style: TitleM, textAlign: TextAlign.center),
        SizedBox(8),
        // Description
        Text(description, style: BodyM.copyWith(color: kTextSecondary), textAlign: TextAlign.center),
        SizedBox(24),
        // Buttons
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'))),
          SizedBox(12),
          Expanded(child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () { Navigator.pop(ctx); onConfirm(); },
            child: Text(confirmLabel))),
        ]),
      ]),
    ),
  );
}
```

### Keep Duration Bottom Sheet (special)

```dart
showModalBottomSheet(
  builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
    // Drag handle + title
    Text('Keep for how long?', style: TitleM),
    SizedBox(16),
    // Radio tiles
    ...[
      _KeepOption('1 month', 'Remove from review for 1 month', Duration(days: 30)),
      _KeepOption('3 months', 'Remove from review for 3 months', Duration(days: 90)),
      _KeepOption('6 months', 'Remove from review for 6 months', Duration(days: 180)),
      _KeepOption('No reminder', 'Remove from review indefinitely', null),
    ],
    SizedBox(16),
    Row(children: [
      Expanded(child: OutlinedButton(child: Text('Cancel'))),
      SizedBox(12),
      Expanded(child: ElevatedButton(child: Text('Confirm'))),
    ]),
  ]),
)
```

---

## 16. Badge System

**Rule:** Each item shows maximum 1 badge on the wardrobe grid card. Evaluated in priority order — first match wins. Item Detail screen shows ALL applicable badges.

```dart
String? computeBadge(Item item) {
  if (item.condition == 1)                                          return 'Worn out';
  if (_isAnyDRuleFlagged(item))                                     return 'Donation review';
  if (item.wearRate >= 0.2)                                         return 'Overused';
  if (item.skipRatio > 0.50)                                        return 'Skipped often';
  if (item.wearCount == 0 && item.isNewItem)                        return 'Never worn';
  if (item.daysSinceWorn > 60 && item.wearCount > 0)               return 'Long unused';
  if (item.isNewItem && item.daysSinceAdded <= 14)                  return 'New';
  if (_isTopTenPercentByWearCount(item))                            return 'Most worn';
  return null;  // no badge
}
```

**Badge colours:**
```dart
const Map<String, Color> kBadgeBgColours = {
  'Worn out':        Color(0xFFFEF2F2),
  'Donation review': Color(0xFFFFF7ED),
  'Overused':        Color(0xFFFEF2F2),
  'Skipped often':   Color(0xFFFEF2F2),
  'Never worn':      Color(0xFFFFFBEB),
  'Long unused':     Color(0xFFFFFBEB),
  'New':             Color(0xFFEFF6FF),
  'Most worn':       Color(0xFFF5F3FF),
};

const Map<String, Color> kBadgeTextColours = {
  'Worn out':        Color(0xFF991B1B),
  'Donation review': Color(0xFFC2410C),
  'Overused':        Color(0xFFB91C1C),
  'Skipped often':   Color(0xFFB91C1C),
  'Never worn':      Color(0xFF92400E),
  'Long unused':     Color(0xFF92400E),
  'New':             Color(0xFF1D4ED8),
  'Most worn':       Color(0xFF5B21B6),
};
```

**Badge widget:**
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: kBadgeBgColours[badgeLabel],
    borderRadius: BorderRadius.circular(999),
  ),
  child: Text(badgeLabel, style: TextStyle(
    fontSize: 10, fontWeight: FontWeight.w600,
    color: kBadgeTextColours[badgeLabel],
  )),
)
```

**CRITICAL — badge vertical alignment:**
All badge chips must use `align-items: center` (in Flutter: `mainAxisAlignment: MainAxisAlignment.center` inside the badge Row, or ensure Container is centred within its parent Row using `crossAxisAlignment: CrossAxisAlignment.center`). Without this, badges of different text lengths appear misaligned in the item card grid.

---

## 17. Section 4 Tab Options — All 3 Documented

Three options were designed for Section 4 of the Insights page. **Option A (Scrollable TabBar + gradient) is the locked primary choice.** Options B and C are documented as alternatives.

---

### Option A — Scrollable TabBar + Right-Edge Gradient Fade (PRIMARY — LOCKED)

**Why chosen:** Least code, swipe gesture between tabs (built-in TabBarView), Flutter handles all state via DefaultTabController. Gradient fade communicates scrollability.

**Implementation:**

```dart
DefaultTabController(
  length: 4,
  child: Column(children: [
    // Tab row with gradient overlay
    Stack(
      children: [
        TabBar(
          isScrollable: true,                     // ← key: tabs size to content
          tabAlignment: TabAlignment.start,        // ← key: left-aligned, not stretched
          indicatorColor: kPrimary,
          labelColor: kPrimary,
          unselectedLabelColor: kTextTertiary,
          indicatorWeight: 2.5,
          dividerColor: Color(0xFFF0EDE6),
          labelPadding: EdgeInsets.symmetric(horizontal: 10),
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500),
          tabs: [
            _CountTab(label: 'Never Worn', count: neverWornCount),
            _CountTab(label: 'Long Unused', count: longUnusedCount),
            _CountTab(label: 'Skipped Often', count: skippedCount),
            _CountTab(label: 'Overused', count: overusedCount),
          ],
        ),
        // Right-edge gradient overlay — communicates scrollability
        Positioned(
          top: 0, right: 0, bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.white.withOpacity(0), Colors.white],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    SizedBox(height: 12),
    SizedBox(
      height: 220,  // fits 3 item rows + View All
      child: TabBarView(
        children: [
          _AttentionTabContent(items: neverWornItems, tab: Tab.neverWorn),
          _AttentionTabContent(items: longUnusedItems, tab: Tab.longUnused),
          _AttentionTabContent(items: skippedItems, tab: Tab.skipped),
          _AttentionTabContent(items: overusedItems, tab: Tab.overused),
        ],
      ),
    ),
  ]),
)

// Tab widget showing label + count stacked
class _CountTab extends StatelessWidget {
  final String label;
  final int count;
  
  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 44,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label),
        Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
```

**Complexity:** LOW — StatelessWidget, zero manual state management.
**Lines for selection mechanism:** ~20 lines (TabBar + Stack + gradient overlay)
**Swipe between tabs:** YES (TabBarView built-in)

---

### Option B — 2×2 Grid Selection (ALTERNATIVE)

**Appearance:** Four equal-sized rectangular tiles arranged in a 2×2 grid. Selected tile shows green border + kPrimaryLight background. Each tile shows label + "N items" count centred.

**When to use:** If you want the 4 tabs to be visually equal weight and all visible without scrolling.

**Trade-offs:** No built-in swipe gesture. ~40 extra lines vs Option A. Uses `StatefulWidget` with manual `_selectedIndex` state. Uses `IndexedStack` to preserve scroll position of each tab.

```dart
class SectionFourGrid extends StatefulWidget { ... }

class _SectionFourGridState extends State<SectionFourGrid> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: 3.2),
        itemCount: 4,
        itemBuilder: (ctx, index) {
          final isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = index),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isSelected ? kPrimaryLight : kBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? kPrimary : kBorder,
                  width: isSelected ? 1.5 : 0.5),
              ),
              alignment: Alignment.center,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_labels[index], style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: isSelected ? kPrimary : kTextTertiary)),
                Text('${_counts[index]} items', style: TextStyle(
                  fontSize: 11, color: isSelected ? kPrimary : kTextTertiary)),
              ]),
            ),
          );
        },
      ),
      SizedBox(height: 14),
      IndexedStack(
        index: _selectedIndex,
        children: _itemLists.map((items) => _AttentionTabContent(items: items)).toList(),
      ),
    ]);
  }
}
```

**Complexity:** MEDIUM — StatefulWidget, manual state, IndexedStack.
**Lines for selection mechanism:** ~55 lines
**Swipe between tabs:** NO

---

### Option C — Horizontal Scrollable Chips (ALTERNATIVE)

**Appearance:** A horizontal row of pill-shaped chips. Selected chip: kPrimary fill, white text. Unselected: white fill, kBorder border. Count included in chip label: "Never Worn · 5". Row scrolls horizontally if chips overflow.

**When to use:** Most consistent with the rest of the app's chip design language (same chips used on Wardrobe, Donate, Outfit pages).

**Trade-offs:** No swipe gesture. Same manual state as Option B. Chip label shows count inline instead of below. ~35 extra lines vs Option A.

```dart
class SectionFourChips extends StatefulWidget { ... }

class _SectionFourChipsState extends State<SectionFourChips> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_labels.length, (index) {
            final isSelected = _selectedIndex == index;
            return Padding(
              padding: EdgeInsets.only(right: index < _labels.length - 1 ? 7 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary : kSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: isSelected ? kPrimary : kBorder, width: 0.5),
                  ),
                  child: Text(
                    '${_labels[index]} · ${_counts[index]}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : kTextTertiary,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      SizedBox(height: 14),
      IndexedStack(
        index: _selectedIndex,
        children: _itemLists.map((items) => _AttentionTabContent(items: items)).toList(),
      ),
    ]);
  }
}
```

**Complexity:** MEDIUM — StatefulWidget, manual state, IndexedStack.
**Lines for selection mechanism:** ~45 lines
**Swipe between tabs:** NO

---

## 18. Colour Picker — Both Versions

### Version 1 — Swatch Grid (PRIMARY RECOMMENDATION)

**Why preferred:** Everything visible immediately. User sees all 12 colours at once. Direct tap feedback. 2–3 taps to complete. More visually engaging for a one-time onboarding screen.

**Layout:** Grid of 38×38px colour tiles in a `Wrap` widget with 8px gaps.

**States per tile:**
- Unselected: colour fill + `Border.all(color: Colors.transparent)` (no border)
- Selected (preferred): colour fill + `Border.all(color: kPrimary, width: 2.5)` + green check badge
- Selected (disliked): colour fill + `Border.all(color: Color(0xFFB91C1C), width: 2.5)` + red X badge
- Disabled (in other list): colour fill + `opacity: 0.25` + `cursor: SystemMouseCursors.forbidden`
- Max reached (section full): unselected tiles fade to `opacity: 0.35`, become non-tappable

**Check/X badge implementation:**
```dart
Stack(
  clipBehavior: Clip.none,
  children: [
    // Colour tile
    Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: swatchColor,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
          ? Border.all(color: sectionColor, width: 2.5)
          : null,
      ),
    ),
    // Badge (shown only when selected)
    if (isSelected)
      Positioned(
        top: -5, right: -5,
        child: Container(
          width: 16, height: 16,
          decoration: BoxDecoration(color: sectionColor, shape: BoxShape.circle),
          child: Icon(
            isPreferred ? Icons.check : Icons.close,
            size: 10, color: Colors.white),
        ),
      ),
  ],
)
```

**State management:**
```dart
class _ColourPickerState extends State<ColourPickerWidget> {
  final Set<String> preferred = {};  // colour keys e.g. 'black', 'white'
  final Set<String> disliked  = {};
  static const maxSelections  = 3;

  void _togglePreferred(String colour) {
    if (disliked.contains(colour)) return;          // mutual exclusivity
    setState(() {
      if (preferred.contains(colour)) {
        preferred.remove(colour);
      } else if (preferred.length < maxSelections) {
        preferred.add(colour);
      }
      // If max reached and colour not already selected: no-op (tile is non-tappable via opacity)
    });
  }

  void _toggleDisliked(String colour) {
    if (preferred.contains(colour)) return;         // mutual exclusivity
    setState(() {
      if (disliked.contains(colour)) {
        disliked.remove(colour);
      } else if (disliked.length < maxSelections) {
        disliked.add(colour);
      }
    });
  }
}
```

**Counter display:** `"${preferred.length} / 3"` shown top-right of each section header. Color: kPrimary for Colours I Love, `Color(0xFFB91C1C)` for Colours I Dislike.

**No "Max reached" hint text.** When max is reached, tiles simply go to 35% opacity. This is a visual signal only — no text label needed.

---

### Version 2 — Dropdown Checkbox Bottom Sheet (SIMPLER ALTERNATIVE)

**Why documented:** ~20% less code. No custom Stack/Positioned widget. Uses standard Flutter `CheckboxListTile` and `showModalBottomSheet`.

**Main page appearance:** Two tappable dropdown fields (one per section). Selected field shows small colour swatches inline + colour names. Empty field shows "Select colours..." placeholder. Chevron-down icon on right.

**Implementation:**
```dart
// Main page: tappable field
GestureDetector(
  onTap: () => _showColourSheet(context, isPreferred: true),
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: preferred.isEmpty ? kBorder : kBorderFocus, width: 0.5),
    ),
    child: Row(children: [
      // Show selected swatches inline
      ...preferred.map((colour) => Container(
        width: 20, height: 20, margin: EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: kColourSwatches[colour],
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: kBorder, width: 0.5),
        ),
      )),
      if (preferred.isNotEmpty)
        Text(preferred.join(', ').capitalize(),
          style: BodyS.copyWith(fontWeight: FontWeight.w500))
      else
        Text('Select colours...', style: BodyS.copyWith(color: kTextTertiary)),
      Spacer(),
      Icon(Icons.keyboard_arrow_down, color: kTextTertiary, size: 18),
    ]),
  ),
)

// Bottom sheet
void _showColourSheet(BuildContext context, {required bool isPreferred}) {
  final targetSet = isPreferred ? preferred : disliked;
  final otherSet  = isPreferred ? disliked : preferred;
  final maxCount  = 3;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        builder: (ctx, controller) => Column(children: [
          // Drag handle + title
          Container(width: 36, height: 4, margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(999))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text(isPreferred ? 'Colours I Love' : 'Colours I Dislike',
                style: TitleS),
              Spacer(),
              Text('${targetSet.length} / $maxCount',
                style: LabelS.copyWith(color: isPreferred ? kPrimary : Color(0xFFB91C1C))),
            ]),
          ),
          Text('Select up to $maxCount. Already chosen colours are greyed out.',
            style: Caption.copyWith(color: kTextTertiary)),
          SizedBox(8),
          // Colour list
          Expanded(
            child: ListView(controller: controller, children: [
              ...kColourSwatches.entries.map((entry) {
                final colour = entry.key;
                final inOtherSet = otherSet.contains(colour);
                final isSelected = targetSet.contains(colour);
                final maxReached = targetSet.length >= maxCount && !isSelected;

                return CheckboxListTile(
                  enabled: !inOtherSet && !maxReached,
                  value: isSelected,
                  onChanged: (val) {
                    setSheetState(() {
                      if (val == true) targetSet.add(colour);
                      else targetSet.remove(colour);
                    });
                    setState(() {}); // update parent
                  },
                  secondary: Container(width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: entry.value,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: kBorder, width: 0.5),
                    ),
                  ),
                  title: Text(colour.capitalize(),
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: inOtherSet ? kTextTertiary : kTextPrimary)),
                  subtitle: inOtherSet
                    ? Text('· already ${isPreferred ? "disliked" : "loved"}',
                        style: Caption.copyWith(color: kTextTertiary))
                    : null,
                  checkColor: Colors.white,
                  activeColor: isPreferred ? kPrimary : Color(0xFFB91C1C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                );
              }),
            ]),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Done'),
            ),
          ),
        ]),
      ),
    ),
  );
}
```

**Trade-off summary:**
| | Version 1 (Swatch Grid) | Version 2 (Dropdown) |
|---|---|---|
| Code complexity | Medium | Lower |
| Custom widget needed | Yes (Stack + Positioned) | No |
| User interactions to complete | 2–3 taps | 4+ taps (tap field → select → Done → repeat) |
| All colours visible immediately | YES | NO (hidden behind tap) |
| Recommended for | Final product | Under time pressure |

---

## 19. Locked Design Decisions

All decisions below were made during the full UI/UX design session and are locked. Do not change without discussion.

| Decision | What was decided | Reason |
|---|---|---|
| Font | Plus Jakarta Sans | Warm, modern, clear at small sizes. Google Fonts, free. |
| Background | #F7F4EF (warm off-white) | Not pure white. Softer, lifestyle feel. |
| Brand green | #4A7055 (sage green) | Calm, sustainable, not aggressive. |
| Bottom nav | 5 tabs: Home · Wardrobe · Outfit · Donate · Insights | Locked. Profile is NOT a bottom tab. |
| Profile access | Top-right avatar icon only | Consistent across all 5 main pages. |
| Section 4 tabs | Option A (scrollable TabBar + gradient) | Lowest code, built-in swipe, gradient communicates scrollability. |
| Gradient fade width | 52px | Enough to fade "Overused" tab text without covering "Skipped Often". |
| Green swatch hex | #22C55E (not #4A7055) | Brand green cannot be used as swatch — would look selected when not. |
| Grey swatch hex | #9CA3AF (not #9B9490) | #9B9490 is our text colour. Neutral cool grey is more accurate. |
| Colour picker primary | Version 1 (swatch grid) | More engaging, faster, everything visible. Version 2 documented as fallback. |
| Max colour selections | 3 per section | Prevents PS formula from becoming noise. Forces genuine prioritisation. |
| Style preferences | Colours only | S5 formula only uses colour. Type/category preferences redundant with S2. |
| "Max reached" hint | Removed | Opacity fade is sufficient visual signal. Text is clutter. |
| Item Status Manager | Removed from Settings | Status managed from Item Detail. Dedicated screen is redundant scope. |
| Laundry Cycle control | Inline stepper in Settings | No sub-page needed for a single number (range 1–14 days). |
| App Theme | Sub-page with 3 radio buttons | Segmented control too cramped in settings list row on small phones. |
| Recommendation Mode | Inline toggle in Settings | Binary choice (Balanced / Pure). Toggle is clearest control. |
| Delete item | Confirmation dialog + 5s undo snackbar | No "trash" state. Delete is permanent but undoable briefly. |
| Donation tier badges | Removed from candidate cards | DPS handles sorting. Showing "Strong Candidate" on card is redundant. |
| Item Donation Detail screen | Does not exist | Item Detail screen shows all needed info via Rule-Based Usage Summary. |
| Confirmation sheets | One universal pattern | All 6 uses share the same widget with different text/colour params. |
| Section 4 default tab | Never Worn | Most actionable for new users — new items they should try first. |
| Sleeping items threshold (Section 3) | 90 days | Stronger signal than 60 days used for Long Unused tab. |
| FAB position | Bottom-right, no label | Consistent with Material Design. Label would crowd the grid. |
| Favourite star colour | Yellow (#FACC15) | Universal "favourite" convention. Only shown when is_favorite == true. |
| Onboarding page 4 CTA | "Not Now" (not "Skip") | Permissions request. "Not Now" is softer — user doesn't feel like skipping a feature. |
| Splash loading indicator | Spinning ring (CircularProgressIndicator) | Dots look like onboarding page indicators — confusing before onboarding starts. |
| F1 Season Filter | Dropped from MVP | Malaysia seasons (dry/rainy) don't strongly dictate clothing. Adds complexity for minimal benefit. |
| Occasions | Casual · Work · Active · Relax | "Formal" dropped — too niche. "Sport" renamed Active. 4 occasions sufficient. |

---

*End of Frontend Reference — v1.0*
*All decisions reflect the final locked state after the full UI/UX design session.*
*Build sequence recommendation: Phase 1 (theme + auth) → Phase 2 (item model + wardrobe) → Phase 3 (rule engine) → Phase 4 (outfit + donate) → Phase 5 (insights + profile) → Phase 6 (onboarding + polish)*
