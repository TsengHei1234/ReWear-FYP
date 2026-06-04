# Wardrobe App — Frontend Reference (Plain English Edition)

> **What this file is:** A complete frontend specification written entirely in plain English with exact measurements, colours, and states. Every element on every screen is described the way a designer would hand off to a developer. No pseudocode except where noted. Another Claude or Codex reading this file should be able to build every screen exactly as designed.
>
> **The three exceptions where actual Flutter code appears:**
> - Section 16: `app_theme.dart` — copy-paste ready theme file
> - Section 17: Section 4 tab options — code comparison is the whole point
> - Section 18: Colour picker state logic — mutual exclusivity is genuinely complex
>
> **Stack:** Flutter · Dart · Supabase · Plus Jakarta Sans font

---

## Table of Contents

1. [Design System — Colours](#1-design-system--colours)
2. [Design System — Typography](#2-design-system--typography)
3. [Design System — Spacing](#3-design-system--spacing)
4. [Design System — Border Radius](#4-design-system--border-radius)
5. [Design System — Shadows](#5-design-system--shadows)
6. [Component Library](#6-component-library)
7. [Navigation Structure](#7-navigation-structure)
8. [Splash Screen](#8-splash-screen)
9. [Login Screen](#9-login-screen)
10. [Sign Up Screen](#10-sign-up-screen)
11. [Forgot Password Screen](#11-forgot-password-screen)
12. [Onboarding Page 1 — Welcome](#12-onboarding-page-1--welcome)
13. [Onboarding Page 2 — Style Preferences](#13-onboarding-page-2--style-preferences)
14. [Onboarding Page 3 — Recommendation Mode](#14-onboarding-page-3--recommendation-mode)
15. [Onboarding Page 4 — Notifications](#15-onboarding-page-4--notifications)
16. [Home Page](#16-home-page)
17. [Wardrobe Page](#17-wardrobe-page)
18. [Add Item Screen](#18-add-item-screen)
19. [Item Detail Screen](#19-item-detail-screen)
20. [Edit Item Screen](#20-edit-item-screen)
21. [Full Wear History Screen](#21-full-wear-history-screen)
22. [Outfit Page — Daily Rotation Tab](#22-outfit-page--daily-rotation-tab)
23. [Outfit Page — Outfit Generator Tab](#23-outfit-page--outfit-generator-tab)
24. [Outfit Detail Screen](#24-outfit-detail-screen)
25. [Outfit History Screen](#25-outfit-history-screen)
26. [Donate Page](#26-donate-page)
27. [Kept Items Screen](#27-kept-items-screen)
28. [Donation History Screen](#28-donation-history-screen)
29. [Insights Page](#29-insights-page)
30. [Insights View All Sub-pages](#30-insights-view-all-sub-pages)
31. [Profile & Settings Page](#31-profile--settings-page)
32. [My Profile Screen](#32-my-profile-screen)
33. [Style Preferences Screen](#33-style-preferences-screen)
34. [App Theme Screen](#34-app-theme-screen)
35. [Notification Settings Screen](#35-notification-settings-screen)
36. [Data & Privacy Screen](#36-data--privacy-screen)
37. [Help / About Screen](#37-help--about-screen)
38. [Shared Bottom Sheets](#38-shared-bottom-sheets)
39. [Badge System](#39-badge-system)
40. [Flutter Theme File — app_theme.dart](#40-flutter-theme-file--app_themedart)
41. [Section 4 Tab Options — Code Comparison](#41-section-4-tab-options--code-comparison)
42. [Colour Picker — Both Versions](#42-colour-picker--both-versions)
43. [Locked Design Decisions](#43-locked-design-decisions)

---

## 1. Design System — Colours

### Light Theme

| Token name | Hex value | Used for |
|---|---|---|
| Background | #F7F4EF | Scaffold background — every screen's base colour |
| Surface | #FFFFFF | Cards, input fields, bottom sheets |
| Surface-2 | #F0EDE6 | Dividers inside cards, tile backgrounds, progress bar track |
| Text-Primary | #1A1A1A | All headings, item names, primary body text |
| Text-Secondary | #6B6560 | Descriptions, sub-labels, form labels above inputs |
| Text-Tertiary | #9B9490 | Placeholders, captions, timestamps, helper text |
| Border | #E6E1D8 | Card borders, input field borders (normal state) |
| Border-Focus | #C8DEC8 | Input field border when focused or has a value (green tint) |
| Primary | #4A7055 | All primary actions — buttons, active states, selected chips, toggles on |
| Primary-Mid | #7FAF8C | Secondary accents, progress fills |
| Primary-Light | #EBF2EC | Chip selected background, icon tile backgrounds, light green fills |
| Dark-Primary-Text | #27500A | Text colour on top of Primary-Light backgrounds |

### Dark Theme

| Token name | Hex value | Used for |
|---|---|---|
| Background | #111511 | Very dark green-black scaffold |
| Surface | #181E18 | Dark cards |
| Surface-2 | #202820 | Dark dividers, tiles |
| Text-Primary | #F0EFEC | Near-white headings |
| Text-Secondary | #9E9C97 | Medium-weight dark sub-labels |
| Text-Tertiary | #6B6965 | Dark placeholders |
| Border | #2C342C | Dark card/input borders |
| Primary | #6BAF80 | Lighter green — primary actions in dark mode |

### Semantic / Badge Colours

| Badge type | Background | Text colour |
|---|---|---|
| Worn out | #FEF2F2 | #991B1B |
| Donation review | #FFF7ED | #C2410C |
| Overused | #FEF2F2 | #B91C1C |
| Skipped often | #FEF2F2 | #B91C1C |
| Never worn | #FFFBEB | #92400E |
| Long unused | #FFFBEB | #92400E |
| New | #EFF6FF | #1D4ED8 |
| Most worn | #F5F3FF | #5B21B6 |
| Status (neutral) | #F3F4F6 | #374151 |

### Destructive / Alert Colours

| Use | Background | Border | Text |
|---|---|---|---|
| Donate button | transparent | #B91C1C | #B91C1C |
| Delete action | transparent | #B91C1C | #B91C1C |
| Log Out card | #FEF2F2 | #FECACA | #B91C1C |
| Log Out icon tile | #FEE2E2 | — | #B91C1C |

### Colour Swatch Values (for Style Preferences screen only)

These values represent clothing colours and must NOT overlap with app brand colours.

| Colour name | Hex | Critical notes |
|---|---|---|
| Black | #1A1A1A | Same as Text-Primary — acceptable since it reads as "black clothing" |
| White | #FFFFFF | Needs 1px #E6E1D8 border so it's visible against white background |
| Grey | #9CA3AF | Must be this value — NOT #9B9490 which is our Text-Tertiary token |
| Beige | #D4B896 | — |
| Navy | #1E3A5F | — |
| Blue | #3B82F6 | — |
| Red | #DC2626 | — |
| Green | #22C55E | Must be this value — NOT #4A7055 which is our brand Primary |
| Brown | #8B5E3C | — |
| Yellow | #EAB308 | — |
| Pink | #EC4899 | — |
| Purple | #A855F7 | — |

---

## 2. Design System — Typography

**Font family:** Plus Jakarta Sans — loaded via `google_fonts` Flutter package.
**All weights used:** 400 (regular), 500 (medium), 600 (semibold), 700 (bold).

| Style name | Size | Weight | Colour default | Used for |
|---|---|---|---|---|
| Display | 28px | 700 | Text-Primary | Onboarding headlines, splash title |
| Title-L | 22px | 700 | Text-Primary | Page titles (Home, Wardrobe, etc.) |
| Title-M | 18px | 600 | Text-Primary | Card section headers, sheet titles |
| Title-S | 16px | 600 | Text-Primary | Item names in detail pages, modal titles |
| Body-L | 16px | 400 | Text-Primary | Primary body text |
| Body-M | 14px | 400 | Text-Primary | Standard body text, input values |
| Body-S | 13px | 400 | Text-Primary | Secondary body text, item names in lists |
| Body-S Bold | 13px | 600 | Text-Primary | Item names in cards, row labels |
| Label | 14px | 500 | Text-Primary | Chip text, button text |
| Label-S | 12px | 500 | Text-Secondary | Sub-labels, pill badges |
| Caption | 11px | 500 | Text-Tertiary | Timestamps, category lines, section subtitles |
| Caption-Bold | 11px | 700 | varies | Section category labels (uppercase) |
| Micro | 10px | 600 | Text-Tertiary | Smallest labels, count pills |

**Section category labels** (e.g. "ACCOUNT", "NOTIFICATIONS"):
- Size: 10px or 11px, weight 700, letter-spacing 0.08em, all uppercase, colour Text-Tertiary

---

## 3. Design System — Spacing

All spacing follows a 4dp base grid.

| Token | Value | Common uses |
|---|---|---|
| XS | 4px | Icon-to-text gap, tight internal padding |
| SM | 8px | Gap between chips, gap between small elements |
| MD | 12px | Internal card padding (compact), gap between form rows |
| Base | 16px | Standard horizontal page padding, standard card padding |
| LG | 20px | Gap between major sections |
| XL | 24px | Larger section gaps, bottom sheet padding |
| 2XL | 32px | Page top padding on auth/onboarding screens |
| 3XL | 48px | Large vertical breathing room |

**Page horizontal padding:** 16px left and right on all main content areas.
**Card internal padding:** 16px standard. 20px for larger cards (Health Score card).
**Gap between cards:** 12px.
**Bottom navigation height:** approximately 64px including safe area padding.
**Top bar height:** approximately 56px.
**Sticky bottom button area height:** approximately 80px (enough for one or two buttons + padding).

---

## 4. Design System — Border Radius

| Token | Value | Used for |
|---|---|---|
| XS | 6px | Very small elements |
| SM | 10px | Small chips, compact action buttons |
| MD | 12px | Input fields, small cards, modal list items, icon tiles (large) |
| LG | 14px | Primary and outlined buttons |
| XL | 18px | Standard cards throughout the app |
| 2XL | 24px | Bottom sheet top corners |
| Full | 999px | Chips, pills, score badges, toggle switches, counters |

---

## 5. Design System — Shadows

The app uses minimal shadows — elevation is communicated primarily through borders, not drop shadows.

- **Standard card:** No shadow. Border only: 0.5px #E6E1D8.
- **Bottom sheet:** Light shadow behind it when overlaid on screen.
- **Floating elements** (score pills over photos, last-worn pills): black semi-transparent background fills the pill instead of a shadow.
- **FAB (Floating Action Button):** Default Flutter FAB shadow is acceptable.
- **Top bar:** No shadow — background colour transition is sufficient.

---

## 6. Component Library

### 6.1 Primary Button

- Height: 50px
- Width: full width of its container
- Background: #4A7055 (Primary)
- Border: none
- Border radius: 14px
- Text: white, 15px, bold (700)
- Text letter spacing: none (no uppercase, no tracking)
- Pressed state: slightly darker green (#3D5E49)
- Disabled state: opacity 0.5

---

### 6.2 Outlined Button

- Height: 50px
- Width: full width of its container
- Background: transparent
- Border: 1.5px solid #4A7055
- Border radius: 14px
- Text: #4A7055, 15px, semibold (600)
- Pressed state: very light green tint background (#EBF2EC)
- Disabled state: opacity 0.5

---

### 6.3 Destructive Outlined Button

Same as outlined button except:
- Border: 1.5px solid #B91C1C
- Text: #B91C1C

---

### 6.4 Small Action Button (inside cards, e.g. Keep / Donate)

- Height: 36px
- Width: fills available space in a row (two side by side with 8px gap)
- Background: transparent
- Border: 0.5px solid #E6E1D8 (Keep) or 1px solid #FECACA (Donate)
- Border radius: 8px
- Text: 12px, weight 500
- Text colour: #1A1A1A (Keep) or #B91C1C (Donate)

---

### 6.5 Filter Chip

**Selected state:**
- Background: #4A7055
- Border: none
- Border radius: 999px (full pill)
- Padding: 6px top/bottom, 12px left/right
- Text: white, 12px, semibold (600)

**Unselected state:**
- Background: white (#FFFFFF)
- Border: 0.5px solid #E6E1D8
- Border radius: 999px
- Padding: 6px top/bottom, 12px left/right
- Text: #6B6560, 12px, medium (500)

**Gap between chips in a row:** 7px or 8px.
**Row:** horizontally scrollable, single-select unless stated otherwise.

---

### 6.6 Occasion Chip (read-only, Item Detail)

Same shape as unselected filter chip. Non-tappable. Used to display occasion tags on items.

---

### 6.7 Toggle Switch

- Overall size: 44px wide, 26px tall
- Border radius: 999px (full oval)
- ON state: background #4A7055, thumb (white circle) positioned on the right side
- OFF state: background #E6E1D8, thumb (white circle) positioned on the left side
- Thumb size: 22px diameter, white
- Thumb has a tiny shadow to lift it off the track
- Transition: animated (150ms slide)

---

### 6.8 Stepper (Laundry Cycle control)

A three-part inline control: minus button, value, plus button.

- Minus button: 28×28px, border radius 8px, background #F0EDE6, minus icon 14px, colour #6B6560
- Value: 16px wide, text 14px bold, centred
- Plus button: 28×28px, border radius 8px, background #EBF2EC, plus icon 14px, colour #4A7055
- Gap between the three elements: 10px each
- Min value: 1. Max value: 14.

---

### 6.9 Standard Input Field

**Label above field (separate widget, not floating inside field):**
- Text: 11px, semibold (600), colour #6B6560
- Gap below label before field: 6px

**Field itself:**
- Height: approximately 46px (12px top/bottom padding + 22px line height)
- Background: white (#FFFFFF)
- Border: 0.5px solid #E6E1D8 (normal/empty state)
- Border focused state: 1.5px solid #4A7055
- Border has-value state: 0.5px solid #C8DEC8 (green tint)
- Border radius: 12px
- Horizontal padding inside: 14px
- Text inside: 14px, regular (400), #1A1A1A
- Placeholder text: 14px, regular, #9B9490

**Password field:** Same as standard field. Trailing eye icon (16px, #9B9490) on the right side inside the field. Tapping toggles password visibility.

---

### 6.10 Dropdown Field (single-select)

Same visual as standard input field. Trailing chevron-down icon (16px, #9B9490) on right side. Tapping opens a modal bottom sheet with a list of options. Selected option displays inside the field.

---

### 6.11 Settings Menu Row

A row inside a white card. Used throughout Profile & Settings.

- Height: approximately 56px (13px top/bottom padding)
- Horizontal padding inside card: 14px
- Content: icon tile on left, text in middle, trailing element on right
- Divider between rows: 0.5px #F0EDE6 (Surface-2) line, full width

**Icon tile:**
- Size: 34×34px
- Border radius: 9px
- Background: #EBF2EC (Primary-Light) for account/app rows
- Background: #F7F4EF (Background) for More section rows
- Icon size: 16px
- Icon colour: #4A7055 for account/app rows, #6B6560 for More section rows

**Label area:**
- Primary label: 13px, semibold (600), #1A1A1A
- Sub-label (optional, current value): 11px, regular, #9B9490 — sits directly below primary label

**Trailing options:**
- Chevron: ti-chevron-right icon, 15px, #C0BAB2
- Toggle switch: standard toggle (see 6.7)
- Stepper: standard stepper (see 6.8)

---

### 6.12 Radio Button (App Theme / Recommendation Mode)

**Selected state:**
- Outer circle: 20px diameter, background #4A7055
- Inner white dot: 8px diameter, white, centred
- No border

**Unselected state:**
- Outer circle: 20px diameter, background white
- Border: 1.5px solid #E6E1D8
- No inner dot

---

### 6.13 Progress Bar

- Height: 8px
- Border radius: 999px (fully rounded)
- Track background: #F0EDE6 (Surface-2)
- Fill colour: #4A7055 (Primary)
- Fill also has border radius 999px so the end of the fill is rounded

---

### 6.14 Bottom Navigation Bar

- Background: white (#FFFFFF)
- Top border: 0.5px #E6E1D8
- 5 equal tabs: Home · Wardrobe · Outfit · Donate · Insights
- Each tab has an icon above and a text label below

**Icons (Tabler Icons set):**
- Home: `ti-home`
- Wardrobe: `ti-shirt`
- Outfit: `ti-wand`
- Donate: `ti-heart`
- Insights: `ti-chart-bar`

**Active tab:**
- Icon wrapped in a pill-shaped container: horizontal padding 14px, vertical padding 3px, background #EBF2EC, border radius 999px
- Icon colour: #4A7055
- Label: 10px, semibold (600), #4A7055

**Inactive tab:**
- No pill container
- Icon colour: #9B9490
- Label: 10px, regular (400), #9B9490

---

### 6.15 Top App Bar (standard)

Used on all main tab pages:
- Background: #F7F4EF (same as scaffold — no visible bar)
- Title: left-aligned, 22px bold, #1A1A1A
- Optional subtitle directly below title: 12px regular, #9B9490
- Right side: profile avatar circle (36×36px, #4A7055 background, white initials 12px bold)

Used on sub-pages (pushed routes):
- Back arrow icon (ti-arrow-left, 20px, #1A1A1A) on left
- Title: centred, 17px bold, #1A1A1A
- Profile avatar on right (same as above) — only on some sub-pages

---

### 6.16 Standard White Card

- Background: white (#FFFFFF)
- Border: 0.5px solid #E6E1D8
- Border radius: 18px
- Padding: 16px all sides (20px for larger cards)

---

### 6.17 Segmented Control (Outfit page tab selector)

Used to switch between Daily Rotation and Outfit Generator.

**Container:**
- Background: #EDEBE4 (slightly darker than Background)
- Border radius: 999px
- Padding: 4px all sides

**Active segment:**
- Background: white (#FFFFFF)
- Border radius: 999px
- Text: 13px, semibold (600), #1A1A1A

**Inactive segment:**
- Background: transparent
- Text: 13px, medium (500), #9B9490

---

### 6.18 Score Pill

Used on suggestion cards, outfit cards, and Daily Rotation cards.

- Background: #4A7055
- Border radius: 999px
- Padding: 3px top/bottom, 8px left/right
- Text: white, 11px, semibold (600)
- Content: numeric score (e.g. "72" or "89")

---

### 6.19 Health Score Ring

- Overall widget size: 130×130px
- Track (background circle): stroke 12px wide, colour #F0EDE6
- Progress arc: stroke 12px wide, colour #4A7055, rounded end caps
- Start point: top of circle (rotated -90 degrees)
- Score number inside: 32px bold, #1A1A1A, centred
- "/100" label below score: 11px regular, #9B9490
- The fill percentage equals the Health Score value (0–100)

---

### 6.20 Divider inside card

- Height: 0.5px
- Colour: #F0EDE6 (Surface-2)
- Full width of the card's content area

---

### 6.21 Floating Action Button (FAB)

- Size: standard Flutter FAB (56×56px)
- Shape: circle
- Background: #4A7055
- Icon: plus (+), white, 26px
- Position: bottom-right corner of the screen, standard Flutter FAB positioning
- Used only on: Wardrobe main page

---

### 6.22 Circular Avatar (profile icon)

- Size: 36×36px (top bar) or 72×72px (Profile page user card)
- Shape: circle
- Background: #4A7055
- Text: user initials, white, 12px bold (top bar) or 24px bold (profile card)

---

## 7. Navigation Structure

**Entry flow:**
The app opens to a Splash screen. The splash checks whether the user is logged in (Supabase auth session). If logged in: navigate to Home tab. If not logged in: navigate to Login screen. After Sign Up: navigate to Onboarding page 1. After completing onboarding: navigate to Home tab.

**Main app:** Five-tab bottom navigation bar. Tapping a tab switches to that page. Bottom nav is always visible on the five main tab pages. Sub-pages (pushed routes) hide the bottom nav and show a top bar with a back arrow.

**Profile & Settings:** Accessed by tapping the profile avatar in the top-right corner of any main page. It is not a bottom nav tab. It slides in as a new pushed route.

**Back navigation:** Any screen with a back arrow in the top bar returns to the previous screen when tapped. The back arrow is always on the left side of the top bar.

---

## 8. Splash Screen

**Background:** Full screen #4A7055 (Primary green). Nothing else behind it.

**Content:** Centred vertically in the screen.

**App icon tile:**
- Size: 80×80px
- Border radius: 22px
- Background: white at 15% opacity (rgba 255,255,255,0.15)
- Border: 1.5px solid white at 25% opacity
- Icon inside: shirt/wardrobe icon (ti-shirt), 38px, white (#FFFFFF)

**Gap below icon:** 16px.

**App name:**
- Text: "Wardrobe"
- Size: 28px, bold (700), white

**Loading indicator:**
- Position: near the bottom of the screen, centred horizontally. Approximately 44px from the bottom.
- Style: a thin circular spinner (CircularProgressIndicator)
- Size: 24×24px
- Colour: white
- Stroke width: 2.5px

**Status bar:** white text at 60% opacity (to be legible on green).

**Note:** No tagline text. Only icon + name + spinner.

---

## 9. Login Screen

**Background:** #F7F4EF (Background).
**Status bar:** dark text (standard for light background).
**Layout:** single column, centred, horizontal padding 24px left and right.

**App icon tile:**
- Centred horizontally
- Size: 60×60px
- Border radius: 18px
- Background: #4A7055
- Icon: shirt/wardrobe icon (ti-shirt), 28px, white
- Top margin from safe area: 32px

**Gap below icon:** 16px.

**Headline:**
- Text: "Welcome back"
- Size: 24px, bold (700), #1A1A1A, centred

**Gap:** 4px.

**Sub-headline:**
- Text: "Sign in to your account"
- Size: 13px, regular, #9B9490, centred

**Gap:** 28px.

**Email address field:**
- Label above: "Email address", 11px, semibold, #6B6560
- Gap below label: 6px
- Standard input field (see 6.9)

**Gap between email and password:** 12px.

**Password field:**
- Label above: "Password", 11px, semibold, #6B6560
- Gap below label: 6px
- Standard input field with eye icon (see 6.9)

**Gap:** 8px.

**Forgot Password link:**
- Text: "Forgot Password?"
- Alignment: right-aligned
- Size: 12px, semibold (600), #4A7055
- Tapping navigates to Forgot Password screen

**Gap:** 24px.

**Sign In button:** Primary button (see 6.1). Label: "Sign In".

**Gap:** 12px.

**Sign Up link row:**
- Text: "Don't have an account? " (13px, regular, #9B9490) followed by "Sign Up" (13px, semibold, #4A7055)
- Centred horizontally
- Tapping "Sign Up" navigates to Sign Up screen

---

## 10. Sign Up Screen

**Background:** #F7F4EF.
**Layout:** single column, centred, horizontal padding 24px, top padding 28px.

**App icon tile:** Same as Login screen (60×60px, #4A7055 bg, shirt icon, 18px radius).

**Gap:** 16px.

**Headline:** "Create account", 24px bold, #1A1A1A, centred.

**Gap:** 4px.

**Sub-headline:** "Start managing your wardrobe", 13px regular, #9B9490, centred.

**Gap:** 24px.

**Form fields (each with label above, 12px gap between fields):**

1. **Display name** — label: "Display name", placeholder: "Enter your name"
2. **Email address** — label: "Email address", placeholder: "Enter your email"
3. **Password** — label: "Password", placeholder: "Create a password", with eye toggle
4. **Confirm password** — label: "Confirm password", placeholder: "Repeat your password", with eye toggle

**Gap after last field:** 24px.

**Create Account button:** Primary button (see 6.1). Label: "Create Account".

**Gap:** 12px.

**Sign In link row:**
- Text: "Already have an account? " (13px regular, #9B9490) followed by "Sign In" (13px semibold, #4A7055)
- Centred horizontally

---

## 11. Forgot Password Screen

**Background:** #F7F4EF.

**Top bar:** Back arrow (ti-arrow-left, 20px, #1A1A1A) on left. Title "Forgot Password" centred, 17px bold, #1A1A1A.

**Lock icon tile:**
- Top margin below top bar: 32px
- Size: 60×60px
- Border radius: 18px
- Background: #EBF2EC (Primary-Light)
- Icon: lock icon (ti-lock), 28px, #4A7055

**Gap:** 16px.

**Headline:** "Reset your password", 20px bold, #1A1A1A.

**Gap:** 6px.

**Explanation text:**
- "Enter the email you signed up with and we'll send you a reset link."
- 13px regular, #9B9490, line height 1.5

**Gap:** 28px.

**Email address field:**
- Label: "Email address", 11px semibold, #6B6560
- Gap: 6px
- Standard input field

**Gap:** 24px.

**Send Reset Link button:** Primary button. Label: "Send Reset Link".

**Gap:** 12px.

**Back to Sign In link:**
- Text: "Remembered it? " (13px regular, #9B9490) followed by "Back to Sign In" (13px semibold, #4A7055)
- Centred

**Success state** (replaces form after button tap):
- Form fields and button hidden
- Show a centred message: "Check your email for a reset link."
- 14px regular, #6B6560, centred
- Below it: "Back to Sign In" as a primary button

---

## 12. Onboarding Page 1 — Welcome

**Background:** #F7F4EF.
**No top bar. No Skip button.**
**Layout:** Centred column, horizontal padding 28px.

**App icon tile:**
- Top margin: 40px from safe area
- Size: 88×88px
- Border radius: 24px
- Background: #4A7055
- Icon: shirt/wardrobe icon, 42px, white
- Centred horizontally

**Gap:** 28px.

**Headline:**
- Text: "Meet your smarter wardrobe"
- Size: 26px, bold (700), #1A1A1A
- Centred, line height 1.2

**Gap:** 12px.

**Description:**
- One to two sentences describing the app
- Suggested: "Wardrobe tracks what you wear and surfaces the clothes you've been forgetting — so you use everything you own."
- Size: 14px, regular, #6B6560, centred, line height 1.6

**Gap:** 48px.

**Progress dots:**
- Centred row of 4 dots
- Active dot (page 1): width 22px, height 6px, border radius 999px, colour #4A7055
- Inactive dots (pages 2–4): width 6px, height 6px, border radius 999px, colour #E6E1D8
- Gap between dots: 6px

**Gap:** 32px.

**Get Started button:** Primary button. Label: "Get Started". Width fills horizontal padding (full width minus 28px each side).

---

## 13. Onboarding Page 2 — Style Preferences

**Background:** #F7F4EF.
**Top right "Skip" button:** text only, 12px semibold, #9B9490.
**Horizontal padding:** 24px.

**Headline:**
- Top margin: 12px below status bar area
- Text: "Your colour style"
- Size: 22px, bold, #1A1A1A

**Gap:** 6px.

**Description:**
- "We'll use this to personalise your recommendations. You can change this anytime."
- 13px regular, #9B9490, line height 1.5

**Gap:** 20px.

---

### "Colours I Love" section

**Section header row** (two items on same line):
- Left: "COLOURS I LOVE" — 11px, bold (700), uppercase, letter-spacing 0.08em, colour #4A7055
- Right: counter e.g. "2 / 3" — 11px, semibold (600), #4A7055

**Gap below header:** 10px.

**Colour swatch grid:**
- Layout: Wrap widget, 8px gap between swatches both horizontally and vertically
- Each swatch tile: 38×38px, border radius 10px
- 12 swatches total (all 12 colours listed in Section 1)

**Swatch states:**

Unselected and available:
- Colour fill only
- No border (except white swatch which has 1px #E6E1D8 border so it's visible)
- Full opacity

Selected (green checkmark):
- Colour fill
- Border: 2.5px solid #4A7055
- Green checkmark badge in top-right corner: 16×16px circle, background #4A7055, white check icon 9px, positioned -5px from top and -5px from right (overlaps corner slightly)

Disabled (because this colour is already in "Colours I Dislike"):
- Colour fill
- Opacity: 25%
- Not tappable

Max reached (3 already selected — applies to all unselected swatches in this section):
- Colour fill
- Opacity: 35%
- Not tappable

**Gap after swatch grid:** 20px.

---

### "Colours I Dislike" section

**Section header row:**
- Left: "COLOURS I DISLIKE" — 11px, bold, uppercase, letter-spacing 0.08em, colour #B91C1C
- Right: counter e.g. "1 / 3" — 11px semibold, #B91C1C

**Gap:** 10px.

**Swatch grid:** Same 12 swatches, same layout.

**Swatch states:**

Unselected and available: same as Colours I Love (full opacity, no border).

Selected (red X):
- Colour fill
- Border: 2.5px solid #B91C1C
- Red X badge in top-right corner: 16×16px circle, background #B91C1C, white × icon 9px

Disabled (colour already in "Colours I Love"):
- Opacity: 25%, not tappable

Max reached: opacity 35%, not tappable.

**No "Max reached" hint text is shown anywhere on this page.**

**Gap after dislike grid:** 24px.

---

**Progress dots:** page 2 active (second dot is wide/green, others are small/grey).

**Gap:** 20px.

**Next button:** Primary button. Label: "Next".

**Two implementation options are documented in Section 42. Version 1 (swatch grid described above) is the primary recommendation. Version 2 (dropdown checkbox) is the simpler fallback.**

---

## 14. Onboarding Page 3 — Recommendation Mode

**Background:** #F7F4EF.
**Top right "Skip" button:** text only, 12px semibold, #9B9490.
**Horizontal padding:** 24px.

**Headline:**
- Text: "How should we recommend?"
- Size: 22px, bold, #1A1A1A

**Gap:** 6px.

**Description:**
- "Choose how your daily rotation works. You can change this anytime in settings."
- 13px regular, #9B9490, line height 1.5

**Gap:** 24px.

---

### Option Card: Balanced Rotation (pre-selected)

- Background: white
- Border: 2px solid #4A7055
- Border radius: 16px
- Padding: 16px

**Inside the card:**

Top row (horizontal):
- Selected radio button (20px, #4A7055 filled with white dot) on left
- "Balanced Rotation" label: 14px bold, #1A1A1A
- "Recommended" badge on far right: background #EBF2EC, text #27500A, 10px semibold, padding 2px 8px, border radius 999px

Gap: 6px.

Description text:
- "Factors in your colour preferences when recommending items. Best if you have strong style preferences."
- 12px regular, #6B6560, line height 1.5
- Left indent of 30px (to align with the text after the radio button)

---

### Option Card: Pure Rotation (unselected)

- Background: white
- Border: 0.5px solid #E6E1D8
- Border radius: 16px
- Padding: 16px

**Inside the card:**

Top row:
- Unselected radio button (20px, white fill, #E6E1D8 border) on left
- "Pure Rotation" label: 14px bold, #1A1A1A

Gap: 6px.

Description:
- "Recommends purely based on wear history. Every item gets a fair chance regardless of colour or preference."
- 12px regular, #6B6560, line height 1.5
- Left indent: 30px

**Gap between the two cards:** 10px.

**Gap after cards:** 28px.

**Progress dots:** page 3 active (third dot wide/green).

**Gap:** 20px.

**Next button:** Primary button. Label: "Next".

---

## 15. Onboarding Page 4 — Notifications

**Background:** #F7F4EF.
**Top right "Not Now" button** (NOT "Skip" — softer wording for a permissions request): 12px semibold, #9B9490.
**Horizontal padding:** 24px.

**Bell icon tile:**
- Top margin: 12px
- Size: 60×60px
- Border radius: 18px
- Background: #EBF2EC (Primary-Light)
- Icon: bell icon (ti-bell), 28px, #4A7055

**Gap:** 16px.

**Headline:**
- Text: "Stay on top of your wardrobe"
- Size: 22px, bold, #1A1A1A

**Gap:** 6px.

**Description:**
- "Allow notifications so we can remind you to log outfits and review neglected items."
- 13px regular, #9B9490, line height 1.5

**Gap:** 20px.

---

### Feature list card

- Background: white
- Border: 0.5px solid #E6E1D8
- Border radius: 16px
- Padding: 14px all sides
- Three feature rows inside, gap 10px between rows

**Each feature row (horizontal layout):**
- Icon tile on left: 28×28px, border radius 8px, background #EBF2EC
- Icon inside tile: 13px, #4A7055
- Gap: 10px
- Text column on right:
  - Feature name: 12px semibold (600), #1A1A1A
  - Feature description: 11px regular, #9B9490, below the name

**Row 1:** clock icon — "Daily outfit reminders" — "Keep your wear history up to date"
**Row 2:** shirt icon — "Long-unworn alerts" — "Items that haven't been worn recently"
**Row 3:** chart icon — "Weekly summary" — "Your wardrobe stats every week"

---

**Gap after card:** 20px.

**Progress dots:** page 4 active (fourth dot wide/green).

**Gap:** 20px.

**Allow Notifications button:** Primary button. Label: "Allow Notifications".

---

## 16. Home Page

**Background:** #F7F4EF.

**Top bar:**
- Left: greeting text, e.g. "Good morning, Tseng Hei" — 22px bold, #1A1A1A. Greeting changes by time of day (Good morning / Good afternoon / Good evening).
- Right: profile avatar circle (36×36px, #4A7055 bg, white initials 12px bold). Tapping navigates to Profile & Settings.

**Scrollable content below top bar (16px horizontal padding, gap 16px between sections):**

---

### Section 1 — Occasion Chips

A label "What are you dressing for?" in 12px semibold, #6B6560, sits above the chips row.

**Chips row:**
- Horizontal scrollable
- Single-select
- Chips: All · Casual · Work · Active · Relax
- Default selected: All
- Chip design: standard filter chip (see 6.5)
- Gap between chips: 8px

Selecting a chip filters the suggestions below.

---

### Section 2 — Today's Suggestions Carousel

**Section label:** "Today's Suggestions", 12px bold, #1A1A1A.

**Carousel:**
- Implemented as a PageView with viewport fraction ~0.88 (shows a sliver of the next card on the right, communicating there are more)
- 3 suggestion cards total
- Gap between cards: 10px

**Each suggestion card:**

Photo area:
- Width: full card width
- Height: 210px
- Border radius: 16px (top only, or all corners if image is entire card)
- Object fit: cover (fills the area, cropped if needed)
- Background colour: warm neutral (#EDE4D4) shown while image loads

Score pill (overlaid on photo, bottom-left corner):
- Position: 10px from left, 10px from bottom of photo
- Background: black at 60% opacity
- Border radius: 999px
- Padding: 3px top/bottom, 8px left/right
- Text: white, 11px semibold

Reason badge (overlaid on photo, bottom-right corner):
- Position: 10px from right, 10px from bottom
- Uses badge colour system (see Section 39)
- Border radius: 999px

Below photo area (white card background continuing down):
- Item name: 14px bold, #1A1A1A
- Category · Type: 12px regular, #9B9490
- Gap: 10px
- Button row: two equal-width buttons side by side, 8px gap
  - "Wear Today": primary button style at small scale (height 36px, border radius 10px)
  - "View Item": outlined button style at small scale (height 36px, border radius 10px)

**Full card:**
- Background: white
- Border: 0.5px solid #E6E1D8
- Border radius: 18px
- Padding: 12px (bottom and sides, photo extends to edges top)

---

### Section 3 — Wardrobe Snapshot Card

**Card:**
- Background: white
- Border: 0.5px solid #E6E1D8
- Border radius: 18px
- Padding: 16px

**Section label inside card:** "Wardrobe Snapshot", 12px bold, #1A1A1A.

**Gap:** 12px.

**Utilisation label row:**
- Left: "Utilisation Rate", 12px regular, #6B6560
- Right: percentage value e.g. "66%", 13px bold, #1A1A1A

**Gap:** 6px.

**Progress bar:** see 6.13. Fills to utilisation percentage.

**Gap:** 12px.

**Two stat tiles side by side (equal width, 8px gap):**
- Active Rotation tile: background #EBF2EC (Primary-Light), border radius 12px, padding 12px. Shows "31 items" (large, 16px bold, #4A7055) above "Active Rotation" (11px regular, #6B6560).
- Dormant Items tile: background #F0EDE6 (Surface-2), border radius 12px, padding 12px. Shows "9 items" (16px bold, #1A1A1A) above "Dormant Items" (11px regular, #6B6560).

**Gap:** 12px.

**Donation review link:**
- Text: "4 items for donation review →"
- Size: 12px, semibold (600), #4A7055
- Full width, no background
- Tapping navigates to the Donate tab

---

## 17. Wardrobe Page

**Background:** #F7F4EF.

**Top bar:**
- Title: "Wardrobe", 22px bold, #1A1A1A
- Subtitle directly below (or beside) title: "48 items", 12px regular, #9B9490. Count updates when category filter is active.
- Right: profile avatar

**Content (16px horizontal padding):**

---

### Search bar

- Full width
- Height: 44px
- Background: white
- Border: 0.5px solid #E6E1D8
- Border radius: 12px
- Left padding: 14px, right padding: 14px
- Search icon (ti-search, 16px, #9B9490) on left inside field
- Placeholder text: "Search items...", 14px regular, #9B9490
- Clear (×) button appears on right when field has text

---

### Category chips row

- Horizontal scrollable
- Single-select
- Chips: All · Tops · Bottoms · Outerwear · Shoes · Others
- Default selected: All
- Standard filter chip style (see 6.5)
- Count label row below chips: e.g. "All Items · 48" or "Tops · 18", 12px semibold, #6B6560
- Filter icon button (ti-adjustments, 18px, #6B6560) sits on the far right of the count label row. Tapping opens Filter Bottom Sheet.

---

### Item grid

- 2 columns
- Gap between items: 10px horizontal, 12px vertical
- Each item is an item card (see below)
- FAB (see 6.21) overlaid on bottom-right

**Item card layout (2-column, fills half the screen width minus padding and gap):**

Photo area:
- Width: full card width
- Height: 196px
- Background: varies per item (warm placeholder colour while loading)
- Border radius: 14px top corners only (or full card border radius at top)
- Object fit: cover

Overlaid on photo (top-left): favourite star icon
- Only visible when `is_favorite == true`
- Icon: ti-star, 18px, filled yellow (#FACC15)
- Position: 8px from top, 8px from left

Overlaid on photo (top-right): last worn pill
- Background: black 60% opacity
- Border radius: 999px
- Padding: 2px top/bottom, 7px left/right
- Text: white, 10px semibold
- Content: "2d ago" or "Never" or "7mo ago"
- Position: 8px from top, 8px from right

Status overlay (when item is NOT in IN_WARDROBE status):
- Full-size semi-transparent grey overlay (black 45% opacity) covering the photo
- This visually greys out the item photo

Info area below photo:
- Background: white
- Padding: 10px left/right, 8px top, 10px bottom
- Border radius: 14px bottom corners

Row 1 inside info area:
- Item name: 13px semibold, #1A1A1A, truncated with ellipsis if too long
- Badge chip on the right (highest priority badge only): badge style (see Section 39)

Row 2 inside info area:
- "Category · Type": 11px regular, #9B9490

Full card:
- Border: 0.5px solid #E6E1D8
- Border radius: 14px (all corners rounded consistently)
- Shadow: none

---

## 18. Add Item Screen

**Background:** #F7F4EF.

**Top bar:** Back arrow left. "Add Item" centred. "Save" text button right — 14px semibold, #4A7055.

**Scrollable form content (16px horizontal padding, sections separated by 12px gaps):**

---

### Photo upload section

- A square container centred horizontally
- Width: full width (fills available space)
- Aspect ratio: 1:1
- Background: white
- Border: 2px dashed #E6E1D8
- Border radius: 14px
- When empty: camera icon (ti-camera, 32px, #9B9490) and "Tap to add photo" text (13px regular, #9B9490) centred inside
- When photo added: image fills the square completely (object fit cover)
- When photo added: a small "Change Photo" overlay button appears at the bottom of the square (semi-transparent black bg, white text 12px semibold)

---

### Basic Info card

- Standard white card
- Section label inside: "Basic Info", 12px bold, #1A1A1A

Fields inside (each with label above, 6px gap, then input field, 12px between fields):
1. Item name — text input, placeholder "e.g. Blue Slim Jeans"
2. Category — dropdown (Tops · Bottoms · Outerwear · Shoes · Others)
3. Type — dropdown (options update based on selected Category)
4. Colour — dropdown (12 colour options)
5. Condition — dropdown (Excellent · Good · Fair · Worn · Damaged)
6. Condition Review — segmented toggle (Auto / Manual), full width, two equal options

---

### Occasion Tags card

- Standard white card
- Section label: "Occasion Tags", 12px bold
- Description: "Select all occasions this item is suitable for.", 12px regular, #9B9490
- Multi-select chip grid: Casual · Work · Active · Relax
- Selected chips: #4A7055 background, white text
- Unselected chips: white background, #E6E1D8 border, #6B6560 text

---

### Item History card

- Standard white card
- Section label: "Item History", 12px bold

**Two full-width radio tiles:**

Each tile:
- Background: white
- Border: 0.5px solid #E6E1D8
- Border radius: 12px
- Padding: 14px
- Left: radio button (see 6.12)
- Right: label (13px semibold) + description below (11px regular, #9B9490)

Tile 1: "Brand new — never worn before"
- Description: "This item has never been worn by me"

Tile 2: "I already own and have worn this"
- Description: "This item has wear history before I started using this app"

**If Tile 2 is selected**, three additional fields appear below the tiles (with 10px gap, smooth expansion animation):
- Approximate last worn: date picker dropdown
- Estimated wear count: number input
- How long owned: dropdown (Less than 1 month · 1–3 months · 3–6 months · 6–12 months · Over 1 year)

---

### Sticky Save button at bottom

- Sits above the keyboard or at the screen bottom
- Full width, 16px horizontal margin
- Primary button. Label: "Save to Wardrobe"

---

## 19. Item Detail Screen

**Background:** #F7F4EF.

**Full-bleed photo at top:**
- Width: full screen width
- Height: matches width (1:1 square, so if screen is 390px wide, photo is 390px tall)
- Object fit: cover
- No border radius (extends to screen edges)

**Floating icon row over photo (positioned absolute):**
- Position: top of photo, with safe area padding considered
- Left: back arrow in white circle (36×36px, white background, subtle shadow, ti-arrow-left 18px, #1A1A1A)
- Right side row (right to left): trash icon in white circle · edit icon in white circle · star icon in white circle
- All circles: 36×36px, white background, light shadow, icon 18px
- Star icon: yellow (#FACC15) when `is_favorite == true`, #C0BAB2 (grey) when false. Tapping toggles.
- Trash icon: #B91C1C (red)
- Edit icon: #1A1A1A (dark)

**Scrollable content below photo (16px horizontal padding):**

---

**Item name:** 22px bold, #1A1A1A. Top margin 16px.

**Category · Type · Colour:** "Tops · T-Shirt · White", 13px regular, #9B9490.

**Gap:** 10px.

**Occasion chips row:** read-only chips showing all occasion tags. Non-tappable. Standard chip shape, unselected style.

**Gap:** 10px.

**All applicable badges:** all badges that match the item are shown here (not just the top priority). Each badge is a pill chip using the badge colour system (Section 39). Displayed in a Wrap row with 6px gaps.

**Gap:** 16px.

---

### Stats row

Three equal tiles in a horizontal row, 8px gap between them.

Each tile:
- Background: #F0EDE6 (Surface-2)
- Border radius: 12px
- Padding: 12px
- Content: large number above (16px bold, #1A1A1A) + label below (11px regular, #9B9490)

Tile 1: wear count number + "Wears"
Tile 2: days since worn (e.g. "21 days") + "Last Worn" — or "Never" if never worn
Tile 3: skip count number + "Skipped"

---

### Status & Condition row

Two chips side by side, 8px gap.

Status chip:
- Background: #F0EDE6
- Border radius: 999px
- Padding: 6px 12px
- Icon (12px) + text (12px semibold, #1A1A1A)
- Shows current status: "In Wardrobe" / "In Laundry" / "Lent Out" / "Stored"
- Tappable: opens status update options

Condition chip:
- Same shape
- Shows condition: "Excellent" / "Good" / "Fair" / "Worn" / "Damaged"
- Tappable if condition_review_mode == MANUAL. Read-only if AUTO.

---

### Rule-Based Usage Summary card

Standard white card. Section label: "Rule-Based Usage Summary", 12px bold.

Four rows inside (divider between each):
Each row:
- Label on left: 13px semibold, #1A1A1A (e.g. "Rotation Priority")
- Value on right: 13px semibold, coloured based on value

Row 1 — Rotation Priority: value "High" (red #B91C1C) / "Medium" (amber #92400E) / "Low" (green #4A7055)
Row 2 — Wear Balance: value "Good" (#4A7055) / "Overused" (#B91C1C)
Row 3 — Skip Feedback: value "Low" (#4A7055) / "High" (#B91C1C)
Row 4 — Donation Review: value "Not needed" (#4A7055) / "Under review" (#C2410C)

Each row has a short descriptive line below the value in 11px regular #9B9490 (e.g. "Not worn for 21 days" under Rotation Priority).

---

### Consider Donating button

- Only shown when item is flagged by at least one D-rule
- Destructive outlined button style (see 6.3), height 40px
- Label: "Consider Donating"
- Tapping navigates to the item's entry on the Donate page

---

### Recent Wear History card

Standard white card. Section label: "Recent Wear History", 12px bold.

Two most recent wear events shown:
- Each row: date on left (12px regular, #6B6560) + occasion tag on right (small chip)
- Divider between rows: 0.5px #F0EDE6

Below the two rows:
- "View All →" link: 12px semibold, #4A7055, right-aligned
- Tapping navigates to Full Wear History screen

---

### Sticky buttons at screen bottom

Sits above bottom nav, 16px horizontal margin, 12px bottom margin.

Two buttons side by side, 8px gap:
- Left: "Log Wear" — primary button style, fills left half
- Right: "Build Outfit" — outlined button style, fills right half

Both buttons are height 48px with border radius 14px.

---

## 20. Edit Item Screen

**Same layout as Add Item screen with these differences:**

- Top bar title: "Edit Item" (not "Add Item")
- Sticky button label: "Save Changes"
- Photo shows current item photo. "Change Photo" overlay is visible by default (not just on hover).
- All form fields are pre-filled with current values.
- Item History section is NOT present.
- Instead, below Basic Info card, a read-only notice: "Item history is locked after adding." — 12px regular, #9B9490, italic, centred.

---

## 21. Full Wear History Screen

**Background:** #F7F4EF.

**Top bar:** Back arrow + "Wear History · N" (N = total event count), centred.

**Content (16px horizontal padding):**

White card with all events listed chronologically (newest first):

**Each event row:**
- Height: approximately 48px
- Left side: date — "12 May 2026", 13px semibold, #1A1A1A
- Middle (optional): occasion — small chip, if occasion was logged
- Right side: event type icon
  - WORN: ti-check icon, 18px, inside a 28×28px circle with #EBF2EC background and #4A7055 icon
  - SKIPPED: ti-player-skip-forward icon or skip icon, 18px, inside 28×28px circle with #F3F4F6 background and #9B9490 icon

Divider between rows: 0.5px #F0EDE6.

No search, no filter, no chevrons. Display only.

---

## 22. Outfit Page — Daily Rotation Tab

**Background:** #F7F4EF.

**Top bar:** "Outfit" title, 22px bold. Profile avatar right.

**Segmented control** below top bar: see 6.17. Left segment "Daily Rotation" is active.

**Content (16px horizontal padding, gap 10px between chip rows, 16px before cards):**

---

### Occasion chips

- Horizontal scrollable, single-select
- Labels: All · Casual · Work · Active · Relax
- Default: All
- Standard filter chip style

---

### Layers chips

- Horizontal scrollable, single-select
- Labels: All · Top · Bottom · Outerwear · Shoes
- Default: All
- Standard filter chip style

---

### Section label

"Top 5 Rotation Picks" — 12px bold, #1A1A1A.

---

### Recommendation cards (5 cards, vertical list, 10px gap between cards)

**Each card:**
- Background: white
- Border: 0.5px solid #E6E1D8
- Border radius: 16px
- Padding: 12px

**Inside the card — two-row layout:**

**Row 1 (horizontal):**

Left column:
- Item photo: 88×88px, border radius 10px, object fit cover
- Score pill directly below photo (4px gap): see 6.18

Right column (12px gap from photo):
- Item name: 13px semibold, #1A1A1A, truncated if needed
- Category · Type: 11px regular, #9B9490
- Gap: 4px
- Rotation Priority badge: pill chip with border radius 999px, padding 3px 8px
  - TDS ≥ 0.8: background #FEF2F2, text #B91C1C, label "High Rotation Priority"
  - TDS 0.5–0.8: background #FFFBEB, text #92400E, label "Medium Rotation Priority"
  - wear_count==0 AND is_new_item: background #EFF6FF, text #1D4ED8, label "New Item"
- Gap: 4px
- Last worn line: clock icon (ti-clock, 12px, #9B9490) + "Last worn: Xd ago" or "Never worn", 11px regular, #9B9490
- Wear count line: rotate icon (ti-rotate, 12px, #9B9490) + "Worn X times", 11px regular, #9B9490

**Row 2 (button row, full width, 10px below Row 1):**

Two equal outlined buttons side by side (8px gap):
- "Wear" — outlined button, height 36px, border radius 10px, label 12px semibold, border #E6E1D8, text #1A1A1A
- "Skip" — same style

Below the two buttons (6px gap):
- "Build Outfit" — full-width primary button, height 36px, border radius 10px, label 12px bold

---

**Skip interaction:** Skip confirmation bottom sheet appears. After confirming, the card is removed from the session list without animation. No WEAR_HISTORY entry written for a Skip in Daily Rotation.

---

## 23. Outfit Page — Outfit Generator Tab

**Segmented control:** Right segment "Outfit Generator" is active.

**Content (16px horizontal padding):**

---

### OCCASION label + chips

Label: "OCCASION" — 10px bold, uppercase, letter-spacing 0.08em, #9B9490. Above the chips row.

Chips: Casual · Work · Active · Relax (no "All" option here). Single-select. Default: Casual.

---

### LAYERS label + chips

Label: "LAYERS" — same style as OCCASION label. Directly below occasion chips.

Chips: Top · Bottom · Outerwear · Shoes.

**Top and Bottom chips (locked):**
- These always appear in selected state (green background, white text)
- A small lock icon (ti-lock, 9px) sits beside the label text inside the chip
- These chips are NOT tappable — tapping does nothing
- They communicate "these layers are always included"

**Outerwear and Shoes chips (optional toggles):**
- Default: unselected
- Tapping toggles them on or off
- When selected: green background, white text (same as normal selected chip)

---

### Pinned item strip (conditional — only shown if user came from Build Outfit)

- Full-width container
- Background: #EBF2EC (Primary-Light)
- Border radius: 12px
- Padding: 8px 12px
- Height: approximately 52px

**Inside (horizontal row):**
- Item thumbnail: 36×36px, border radius 8px, object fit cover
- Gap: 8px
- "PINNED" badge: background #4A7055, text white, 9px bold, uppercase, padding 2px 6px, border radius 4px
- Gap: 6px
- Item name: 13px semibold, #1A1A1A, expanded to fill remaining space
- Close button (×): ti-x icon, 16px, #9B9490 — tapping clears the pinned item and hides this strip

---

### Generate / Regenerate button

**Before first generation:**
- Full-width primary button
- Label: "Generate Outfit"

**After first generation:**
- Full-width outlined button
- Label: "Regenerate"
- A "Generated Outfits" divider label appears below the button (centred text between two horizontal lines)
- 3 result cards appear below the divider

---

### Result cards (3 cards after generation, vertical list, 10px gap)

**Each card:**
- Background: white
- Border: 0.5px solid #E6E1D8
- Border radius: 16px
- Padding: 14px
- Whole card is tappable → navigates to Outfit Detail screen

**Inside the card:**

Top row (horizontal):
- Score pill on left (see 6.18)
- Gap: 6px
- Occasion chip: small outlined pill, 11px regular, #6B6560
- Spacer
- "?" circle on right: 22×22px, white background, #E6E1D8 border, border radius full, "?" text 12px, #9B9490. Tapping opens Quick Why bottom sheet (stops card tap propagation).

Gap: 10px.

Thumbnails row:
- Item photo thumbnails side by side
- Size depends on count: 2 items = 80px each, 3 items = 66px each, 4 items = 58px each
- Each thumbnail: square, border radius 8px, object fit cover
- Gap between thumbnails: 6px

Gap: 8px.

Reason tag:
- Short text e.g. "Casual · Not worn recently", 12px regular, #9B9490
- One line, truncated if needed

---

## 24. Outfit Detail Screen

**Background:** #F7F4EF.

**Top bar:** Back arrow left. "Outfit Detail" centred, 17px bold. No profile avatar on this screen.

**Content (16px horizontal padding, 16px gap between sections):**

---

### Header area

Horizontal row:
- Score pill (see 6.18)
- Gap: 8px
- Occasion chip: outlined pill, #E6E1D8 border, 12px regular, #6B6560
- Gap: 8px
- "X items" text: 12px regular, #9B9490

---

### Items in This Outfit card

Standard white card. Section label: "Items in This Outfit", 12px bold.

Each item row (divider between rows):
- Thumbnail: 48×48px, border radius 10px, object fit cover
- Gap: 12px
- Item name: 13px semibold, #1A1A1A, truncated
- Below name: category + type, 11px regular, #9B9490
- Spacer
- Badge chip if applicable (highest priority badge)
- Gap: 4px
- Chevron: ti-chevron-right, 14px, #C0BAB2

Tapping the row navigates to that item's Item Detail screen.

---

### Why This Outfit section

Section label: "Why this outfit?", 12px bold.

Four rows, no card border needed — open layout:
Each row: ti-check icon (16px, #4A7055) on left + reason text (13px regular, #1A1A1A)
Gap between rows: 8px.

Example reasons:
- "Oxford shirt hasn't been worn in 14 days"
- "Matches the Work occasion"
- "Colours are compatible"
- "No item in this outfit is frequently skipped"

---

### Rule Breakdown card

Standard white card. Section label: "Rule Breakdown", 12px bold.

Five rows (divider between each):
Each row: rule name left (13px semibold, #1A1A1A) + status right (13px semibold, coloured)

Row 1 — Temporal Decay: "Due for rotation" (#4A7055) / "Recently worn" (#9B9490)
Row 2 — Skip Penalty: "Clear" (#4A7055) / "Warning" (#C2410C)
Row 3 — Wear Balance: "Balanced" (#4A7055) / "Check overuse" (#C2410C)
Row 4 — Formality Match: "Matched" (#4A7055)
Row 5 — Colour Compatibility: "Compatible" (#4A7055) / "Soft Warning" (#92400E — amber)

Row 5 "Soft Warning" also shows a small amber warning icon (ti-alert-triangle, 12px, #92400E) before the text.

---

### Sticky bottom buttons

Two buttons, full width each, stacked vertically (8px gap), 16px horizontal margin.

Button 1: "Log Wear" — primary button. Logs WORN event for ALL items in this outfit.
Button 2: "Skip Outfit" — destructive outlined button. Opens Skip Outfit confirmation sheet.

---

## 25. Outfit History Screen

**Background:** #F7F4EF.
**Top bar:** Back arrow + "Outfit History" centred.

**Content (16px horizontal padding):**
White card, list of historical outfit events.

**Each event row:**
- Date: 13px semibold, #1A1A1A on left
- Occasion chip: small outlined pill, centred in row
- Thumbnails: 3–4 small (40px) item photo thumbnails on right
- Divider: 0.5px #F0EDE6 between rows
- No chevron — display only, rows are NOT tappable

---

## 26. Donate Page

**Background:** #F7F4EF.

**Top bar:**
- Title: "Donate", 22px bold, #1A1A1A
- Count badge beside title: pill-shaped, background #FEF2F2, text #B91C1C, 12px bold — shows total candidate count e.g. "8"
- Right: profile avatar

**Content (16px horizontal padding, 12px gap between sections):**

---

### Header card

Standard white card.

- "Donation Candidates" — 16px bold, #1A1A1A, with the count badge inline
- Gap: 4px
- Helper text: "Review clothing items that may no longer be useful in your wardrobe." — 13px regular, #9B9490

---

### Shortcut tiles

Two tiles side by side, 8px gap:

Each tile:
- Background: white
- Border: 0.5px solid #E6E1D8
- Border radius: 14px
- Padding: 12px 14px
- Label on left: 13px semibold, #1A1A1A
- Arrow icon on right: ti-arrow-right, 16px, #9B9490

Tile 1: "Kept Items" → navigates to Kept Items screen
Tile 2: "Donation History" → navigates to Donation History screen

---

### Filter chips

Standard filter chip row:
- All · Never Worn · Long Unused · Skipped Often
- Single-select. Default: All.

---

### Donation candidate cards (vertical list, 10px gap)

**Each card:**
- Background: white
- Border: 0.5px solid #E6E1D8
- Border radius: 16px
- No tier badge displayed on the card itself

**Card body (tappable → Item Detail):**

Horizontal row, 12px padding all sides:
- Item photo on left: 72×72px, border radius 10px, object fit cover
- Gap: 12px
- Text column (fills remaining width):
  - Item name: 13px bold, #1A1A1A
  - "Category · Type": 11px regular, #9B9490
  - Gap: 4px
  - Primary D-rule reason row: small icon (13px, #6B6560) + reason text (12px regular, #6B6560). E.g. "Not worn in 6+ months."
  - Condition label: "Condition: Good", 11px regular, #9B9490

**Button row** (below body, 12px horizontal padding, 12px bottom padding):
Two equal buttons side by side, 8px gap:
- "Keep" button: small action button, neutral style (see 6.4)
- "Donate" button: small action button, destructive style (see 6.4)

---

## 27. Kept Items Screen

**Background:** #F7F4EF.
**Top bar:** Back arrow + "Kept Items" centred.

**Content (16px horizontal padding):**
White card list.

**Each row (divider between rows):**
- Item photo: 52×52px, border radius 10px, left side
- Gap: 12px
- Text column:
  - Item name: 13px semibold, #1A1A1A
  - Below: "Returns in X days" or "Kept indefinitely" — 12px regular, #9B9490
- "Undo Keep" button on right: small outlined button, height 32px, border radius 8px, label 11px semibold, #4A7055 text, #C8DEC8 border. Tapping clears `kept_until` and returns item to donation candidates.

**No chevrons on rows** — rows are NOT individually navigational. Only "Undo Keep" is interactive.

---

## 28. Donation History Screen

**Background:** #F7F4EF.
**Top bar:** Back arrow + "Donation History" centred.

**Category chips:** All · Tops · Bottoms · Outerwear · Shoes — standard filter chips, single-select.

**Content below chips (16px horizontal padding):**
White card list.

**Each row (divider between rows):**
- Item photo: 52×52px, border radius 10px, left side
- Gap: 12px
- Text column:
  - Item name: 13px semibold, #1A1A1A
  - "Donated on 12 May 2026" — 11px regular, #9B9490
- Chevron: ti-chevron-right, 14px, #C0BAB2, right side

---

## 29. Insights Page

**Background:** #F7F4EF.

**Top bar:**
- Title: "Insights", 22px bold
- Right: profile avatar

**Scrollable content (16px horizontal padding, 12px gap between sections):**

---

### Section 1 — Wardrobe Health Score card

Standard white card with 20px internal padding.

**Section label:** "Wardrobe Health Score", 12px bold, #1A1A1A.

**Gap:** 16px.

**Centred column layout:**

Health Score Ring (see 6.19):
- 130×130px centred horizontally
- Ring progress fills to health score percentage
- Score number: 32px bold, #1A1A1A, inside ring
- "/100": 11px regular, #9B9490, below score number

**Gap:** 10px.

**Verdict sentence:** 13px semibold, #1A1A1A, centred.
Score 80–100: "Great job! Your wardrobe rotation is healthy."
Score 60–79: "Good progress — a few items need more attention."
Score 40–59: "Your wardrobe has room for better utilisation."
Score 0–39: "Many items in your wardrobe are being neglected."

**Gap:** 4px.

**Sub-label:** "Based on utilisation & rotation of your active wardrobe" — 11px regular, #9B9490, centred.

**Gap:** 16px.

**Two sub-score tiles side by side (8px gap):**
Each tile:
- Background: #F0EDE6 (Surface-2)
- Border radius: 12px
- Padding: 12px
- Centred content
- Large percentage: 22px bold, #4A7055 (e.g. "54%")
- Label below: 11px regular, #6B6560 (e.g. "Utilisation" or "Rotation")

---

### Section 2 — Quick Stats card

Standard white card. Section label: "Quick Stats", 12px bold.

**Gap:** 12px.

**2×2 tile grid (8px gap between tiles):**

Tile 1 — Total Items:
- Background: #F0EDE6
- Border radius: 12px, padding 12px
- Number: 22px bold, #1A1A1A
- Label: "Total Items", 11px regular, #9B9490

Tile 2 — Worn This Month:
- Background: #EFF6FF (blue light)
- Number: 22px bold, #1D4ED8
- Label: "Worn This Month", 11px, #3B5ED8

Tile 3 — Never Worn:
- Background: #FFFBEB (amber light)
- Number: 22px bold, #92400E
- Label: "Never Worn", 11px, #92400E
- Note: Only items where `is_new_item == true` count here

Tile 4 — Donate Candidates:
- Background: #FEF2F2 (red light)
- Number: 22px bold, #B91C1C
- Label: "Donate Candidates →", 11px, #B91C1C
- Has an arrow (→) in the label
- Entire tile is tappable → switches to Donate tab

---

### Section 3 — Wardrobe Utilisation card

Standard white card. Section label: "Wardrobe Utilisation", 12px bold.

**Content:**

Label row (horizontal):
- Left: "Used this month", 12px regular, #6B6560
- Right: "54% (20 of 37 items)", 13px bold, #1A1A1A

Gap: 6px.

Progress bar: see 6.13. Fills to utilisation percentage.

Gap: 12px.

Divider: 0.5px #F0EDE6.

Gap: 10px.

Sleeping items row (horizontal):
- Left: "9 items not worn in 90+ days", 12px regular, #6B6560
- Right: "View All →", 12px semibold, #4A7055, tappable → View All Sleeping Items screen

Gap: 10px.

Hint text: "Utilisation makes up 50% of your Health Score" — 11px italic, #9B9490.

---

### Section 4 — Items That Need Attention card

Standard white card. Section label: "Items That Need Attention", 12px bold.

Gap: 12px.

**Tab bar with gradient fade overlay:**

The tab row sits inside a Stack. On top of the tab row (pointer-events: none) sits a gradient overlay.

Tab row:
- isScrollable: true (Flutter TabBar setting)
- tabAlignment: start (left-aligned, not stretched)
- Tab indicator: 2.5px green (#4A7055) underline
- Active tab text: #4A7055, 12px semibold
- Inactive tab text: #9B9490, 12px medium
- Divider below tabs: 0.5px #F0EDE6
- Each tab shows label text on top row and count number below (10px bold)
- Gap between tabs: 10px horizontal padding each side of label

Gradient overlay (on top of tab row, right side only):
- Width: 52px
- Height: full height of tab row
- Background: fades from transparent on the left to white (#FFFFFF) on the right
- This communicates "more tabs to the right"

Four tabs: Never Worn · Long Unused · Skipped Often · Overused (with item counts below each label).

Default active tab: Never Worn.

---

**Item list per tab (3 rows + View All):**

Each item row (inside the TabBarView content, divider between rows):
- Left: item photo thumbnail, 46×46px, border radius 10px, object fit cover
- Gap: 10px
- Text column:
  - Item name: 13px semibold, #1A1A1A, truncated
  - Sub-label: 11px regular, #9B9490 (see below for per-tab sub-labels)
- Spacer
- Tab-specific badge chip (see below)
- Gap: 4px
- Chevron: ti-chevron-right, 18px, #C0BAB2

Tapping the row navigates to Item Detail screen.

**Sub-labels and badges per tab:**

Never Worn tab:
- Sub-label: "Added X days ago"
- Badge if daysSinceAdded ≤ 14: background #EFF6FF, text #1D4ED8, label "New"
- Badge if daysSinceAdded > 14: background #FFFBEB, text #92400E, label "Never worn"

Long Unused tab:
- Sub-label: "Last worn X days ago"
- Badge if daysSinceWorn > 90: background #FEF2F2, text #B91C1C, label "X days"
- Badge if daysSinceWorn 60–90: background #FFFBEB, text #92400E, label "X days"

Skipped Often tab:
- Sub-label: "Skipped X of Y times"
- Badge if skipRatio > 0.70: background #FEF2F2, text #B91C1C, label "X% skipped"
- Badge if skipRatio 0.50–0.70: background #FFFBEB, text #92400E, label "X% skipped"

Overused tab:
- Sub-label: "Worn X times in Y days"
- All items: background #FEF2F2, text #B91C1C, label "Overused"

**View All link:**

Below the 3 rows:
- Gap: 12px
- Top divider: 0.5px #F0EDE6
- Gap: 12px
- Centred text: "View All N items →", 12px semibold, #4A7055
- Tapping navigates to the respective View All sub-page

---

## 30. Insights View All Sub-pages

Five sub-pages follow the same layout structure.

**Top bar:** Back arrow + "[Section Name] · N" (e.g. "Long Unused Items · 12"), centred, 17px bold.

**Category chips:** All · Tops · Bottoms · Outerwear · Shoes — standard filter chips, single-select, updates list.

**Content (16px horizontal padding):**
White card, list of all qualifying items.

**Each row (divider between rows):**
- Item photo: 48×48px, border radius 10px, left side
- Gap: 12px
- Text column:
  - Item name: 13px semibold, #1A1A1A
  - Sub-label below: 11px regular, #9B9490 — shows section-specific metric (e.g. "Last worn 120 days ago")
- Spacer
- Badge chip (same badge logic as the corresponding tab)
- Chevron: ti-chevron-right, 14px, #C0BAB2

Tapping row navigates to Item Detail.

**Important rule:** Do NOT show the section name as a chip on each row inside that section's sub-page. Inside "Long Unused Items" page, do not put a "Long unused" badge on every single row — that's redundant. The sub-label provides the metric instead.

**Five sub-pages:**
- View All Never Worn — filter: wear_count==0 AND is_new_item==true
- View All Long Unused — filter: daysSinceWorn > 60
- View All Skipped Often — filter: skipRatio > 0.50
- View All Overused — filter: wearRate >= 0.2
- View All Sleeping Items — filter: daysSinceWorn > 90 AND wear_count > 0 (linked from Section 3)

---

## 31. Profile & Settings Page

**Background:** #F7F4EF.

**Top bar:** Back arrow left. "Profile & Settings" centred, 17px bold. No profile avatar (this IS the profile page).

**Content (16px horizontal padding, 12px gap between sections):**

---

### User card

Standard white card with 20px padding.

Centred column layout:
- Avatar: 72×72px circle, #4A7055 background, white initials 24px bold
- Gap: 8px
- Display name: 16px bold, #1A1A1A
- Email: 12px regular, #9B9490

---

### Account section

Section label above: "ACCOUNT" — uppercase label style.

White card with 2 rows (divider between rows):

Row 1 — My Profile:
- Icon tile: #EBF2EC bg, user icon (ti-user), #4A7055
- Label: "My Profile"
- Trailing: chevron

Row 2 — Style Preferences:
- Icon tile: #EBF2EC bg, palette icon (ti-palette), #4A7055
- Label: "Style Preferences"
- Trailing: chevron

---

### App section

Section label: "APP".

White card with 3 rows (dividers between):

Row 1 — Recommendation Mode:
- Icon tile: #EBF2EC bg, adjustments icon (ti-adjustments-horizontal), #4A7055
- Primary label: "Recommendation Mode"
- Sub-label: "Balanced Rotation" (or "Pure Rotation" depending on current setting)
- Trailing: inline toggle switch (see 6.7)
- Toggle ON = Balanced Rotation. Toggle OFF = Pure Rotation.
- Toggling immediately updates `USERS.recommendation_mode` in Supabase.

Row 2 — Laundry Cycle:
- Icon tile: #EBF2EC bg, wash icon (ti-wash), #4A7055
- Primary label: "Laundry Cycle"
- Sub-label: "Days before items return" — 11px regular, #9B9490
- Trailing: inline stepper control (see 6.8). Current value displayed between − and + buttons.

Row 3 — App Theme:
- Icon tile: #EBF2EC bg, sun icon (ti-sun), #4A7055
- Primary label: "App Theme"
- Sub-label: "System default" (or "Light" or "Dark" depending on current setting)
- Trailing: chevron → App Theme sub-page

---

### Notifications section

Section label: "NOTIFICATIONS".

White card with 1 row:

Row — Notification Settings:
- Icon tile: #EBF2EC bg, bell icon (ti-bell), #4A7055
- Label: "Notification Settings"
- Trailing: chevron → Notification Settings sub-page

---

### More section

Section label: "MORE".

White card with 2 rows (divider between):

Row 1 — Data & Privacy:
- Icon tile: #F7F4EF bg (Background), shield icon (ti-shield), #6B6560
- Label: "Data & Privacy"
- Trailing: chevron

Row 2 — Help / About:
- Icon tile: #F7F4EF bg, info icon (ti-info-circle), #6B6560
- Primary label: "Help / About"
- Sub-label: "Version 1.0.0"
- Trailing: chevron

---

### Log Out card

Separate card at the bottom — NOT inside the More section card.

- Card background: #FEF2F2
- Card border: 0.5px solid #FECACA
- Card border radius: 16px
- Single row inside:
  - Icon tile: 34×34px, border radius 9px, background #FEE2E2, logout icon (ti-logout), 16px, #B91C1C
  - Label: "Log Out", 13px semibold, #B91C1C
  - No chevron
- Tapping calls `AuthService.logout()` → navigates to Login screen

---

## 32. My Profile Screen

**Top bar:** Back + "My Profile" centred.
**Background:** #F7F4EF. 16px horizontal padding.

White card with fields:

- Display name: label above + text input field (pre-filled)
- Email: label above + text input field (pre-filled)

Divider inside card between name/email and password section.

Password section:
- "Change Password" label: 13px semibold, #1A1A1A
- Current password field
- New password field
- Confirm new password field

Sticky "Save" primary button at bottom.

---

## 33. Style Preferences Screen

**Top bar:** Back + "Style Preferences" centred.
**Background:** #F7F4EF.

Identical layout to Onboarding Page 2 (see Section 13) with these differences:
- All fields are pre-filled from `USERS.style_preferences`
- No progress dots at the bottom
- "Next" button replaced with a sticky "Save" primary button at the bottom
- On tap, updates `USERS.style_preferences` in Supabase

---

## 34. App Theme Screen

**Top bar:** Back + "App Theme" centred.
**Background:** #F7F4EF.

White card with 3 rows (dividers between):

**Each row:**
- Left: radio button (see 6.12)
- Gap: 12px
- Text column: option name (13px semibold, #1A1A1A) + description below (11px regular, #9B9490)
- Right: icon (16px, #9B9490)

Row 1 — Light:
- Description: "Always use light mode"
- Icon: sun (ti-sun)

Row 2 — Dark:
- Description: "Always use dark mode"
- Icon: moon (ti-moon)

Row 3 — System Default (pre-selected):
- Description: "Follow device setting"
- Icon: mobile device (ti-device-mobile)

Tapping a row selects it. Only one can be selected at a time. Selection saved to `SharedPreferences` (local device storage — not Supabase).

---

## 35. Notification Settings Screen

**Top bar:** Back + "Notification Settings" centred.
**Background:** #F7F4EF.

White card with 6 rows (dividers between):

**Each row:**
- Left side (fills available space):
  - Label: 13px semibold, #1A1A1A
  - Description below: 11px regular, #9B9490
- Right side: toggle switch (see 6.7)

**Six rows:**

Row 1 — Daily Reminder (N1):
- Description: "Remind me to log today's outfit"
- Default: ON

Row 2 — Inactive Warning (N2):
- Description: "Alert after 3+ days without logging"
- Default: ON

Row 3 — Long-Unworn Alert (N3):
- Description: "Notify about items not worn recently"
- Default: ON

Row 4 — Donation Reminder (N4):
- Description: "Remind about donation candidates"
- Default: OFF

Row 5 — Weekly Summary (N5):
- Description: "Weekly wardrobe stats every week"
- Default: ON

Row 6 — Condition Updates (N6):
- Description: "Alert when item condition changes (Auto mode only)"
- Default: OFF

**Note:** N6 is automatically suppressed by the app when condition_review_mode == MANUAL regardless of toggle state.

---

## 36. Data & Privacy Screen

**Top bar:** Back + "Data & Privacy" centred.
**Background:** #F7F4EF.

Privacy policy section: white card with a short paragraph of text (13px regular, #6B6560) and an optional "Read full policy" link (#4A7055).

Delete Account section: white card with a red-tinted divider from the above content.
- Explanation: "Permanently deletes your account and all wardrobe data. This cannot be undone." — 13px regular, #9B9490
- Gap: 12px
- "Delete Account" button: destructive outlined button (see 6.3), but width auto (not full width), centred horizontally
- Tapping shows a confirmation dialog (not a bottom sheet — a centred alert dialog)

---

## 37. Help / About Screen

**Top bar:** Back + "Help / About" centred.
**Background:** #F7F4EF.

White card:
- App name: "Wardrobe", 16px bold, #1A1A1A
- Version: "Version 1.0.0", 13px regular, #9B9490
- Divider
- Short app description paragraph: 13px regular, #6B6560
- Optional "Send Feedback" link row with ti-mail icon + chevron

---

## 38. Shared Bottom Sheets

**Universal structure for all confirmation sheets:**

Container:
- Background: white
- Border radius: 24px top corners, 0px bottom corners
- Padding: 8px top (for drag handle) then 20px horizontal, 32px bottom

**Elements from top to bottom:**

Drag handle:
- 36px wide, 4px tall
- Border radius: 999px
- Colour: #E6E1D8
- Centred horizontally
- 8px gap below handle

Optional item preview (shown when relevant):
- Item thumbnail: 52×52px, border radius 10px, centred horizontally
- Item name below thumbnail: 14px semibold, #1A1A1A, centred
- 12px gap below preview

Title:
- Font: 18px semibold (600), #1A1A1A, centred

Gap: 8px.

Description:
- Font: 14px regular, #6B6560, centred, line height 1.5

Gap: 24px.

Button row:
- Two buttons side by side, 12px gap
- Left: "Cancel" — outlined button style, fills left half
- Right: confirm button — fills right half, colour varies

**Button colours by context:**

| Context | Confirm label | Confirm button colour |
|---|---|---|
| Log Wear | "Log Wear" | Primary (#4A7055) |
| Build Outfit | "Continue" | Primary (#4A7055) |
| Delete Item | "Delete" | Destructive (#B91C1C) |
| Skip Daily Rotation | "Skip" | Destructive (#B91C1C) |
| Skip Outfit | "Skip" | Destructive (#B91C1C) |
| Donate Item | "Confirm" | Destructive (#B91C1C) |
| Keep Duration | "Confirm" | Primary (#4A7055) |

---

### Keep Duration Bottom Sheet (special variant)

Replaces the description + button row with radio tile options:

After drag handle and title ("Keep for how long?"), show 4 radio tile options:

Each tile:
- Full width
- Background: white
- Border radius: 12px
- Padding: 14px
- Horizontal row: radio button (see 6.12) + text column
- Text column: option name (13px semibold) + description below (11px regular, #9B9490)
- Divider between tiles: 0.5px #F0EDE6

Option 1: "1 month" — "Remove from review for 1 month"
Option 2: "3 months" — "Remove from review for 3 months"
Option 3: "6 months" — "Remove from review for 6 months"
Option 4: "No reminder" — "Remove from review indefinitely"

Below options (16px gap):
- Cancel + Confirm buttons side by side (same as universal pattern)

---

### Wardrobe Filter Bottom Sheet

- Drag handle + "Filter" title (18px semibold, centred)
- Gap: 16px

**Occasion filter (multi-select):**
- Label: "Occasion", 12px semibold, #6B6560
- Chips row: Casual · Work · Active · Relax — multi-select

Gap: 16px.

**Status filter (multi-select):**
- Label: "Status"
- Chips: In Wardrobe · Laundry · Lent · Stored

Gap: 16px.

**Sort by (single-select, RadioListTile style):**
- Label: "Sort by"
- Options: Recently worn · Oldest worn · Name A–Z · Most worn

Gap: 16px.

**Favourites toggle:**
- Full-width row: "Favourites only" label (13px semibold) + toggle switch on right

Gap: 20px.

**Apply button:** primary button, full width.

---

### Quick Why Bottom Sheet (Outfit Generator)

- Drag handle
- "Why this outfit?" — 18px semibold, centred
- Gap: 4px
- "Suggested because:" — 13px regular, #9B9490, centred
- Gap: 16px
- 4 reason rows (same style as Outfit Detail "Why this outfit?" rows)
  - ti-check icon 16px, #4A7055 + reason text 13px regular, #1A1A1A
  - 8px gap between rows
- Gap: 20px
- "Got it" button — primary button, full width

---

## 39. Badge System

**Rule on wardrobe grid cards:** Show only 1 badge per card — the highest priority matching badge. Evaluate in priority order, return first match.

**Rule on Item Detail screen:** Show ALL matching badges — every applicable badge is displayed.

**Priority order:**

| Priority | Badge text | Trigger condition |
|---|---|---|
| 1 | Worn out | condition == 1 |
| 2 | Donation review | flagged by any D-rule (D1–D6) |
| 3 | Overused | wearRate ≥ 0.2 |
| 4 | Skipped often | skipRatio > 0.50 |
| 5 | Never worn | wear_count == 0 AND is_new_item == true |
| 6 | Long unused | daysSinceWorn > 60 AND wear_count > 0 |
| 7 | New | is_new_item == true AND daysSinceAdded ≤ 14 |
| 8 | Most worn | top 10% by wear_count in this user's wardrobe |

**Status badges (shown when no behaviour badge applies):**
- "In Laundry" — shown when status == LAUNDRY
- "Lent Out" — shown when status == LENT
- "Stored Away" — shown when status == STORED

**Badge visual specification:**
- Background: see Section 1 semantic colours table
- Border radius: 999px (full pill)
- Padding: 3px top/bottom, 8px left/right
- Font: 10px semibold (600)
- Text colour: see Section 1 semantic colours table
- No border, no shadow

**CRITICAL — badge vertical alignment:**
Every badge chip must be vertically centred within its parent row using `crossAxisAlignment: CrossAxisAlignment.center` on the parent Row. Without this, badges with different amounts of text appear at different vertical positions, making the wardrobe grid look misaligned.

---

## 40. Flutter Theme File — app_theme.dart

This is the only section of this document that is actual Flutter code. Copy this file directly into `lib/core/theme/app_theme.dart`. Once set up, all screens automatically inherit these styles without needing to specify colours or typography per widget.

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Colour constants ───────────────────────────────────────────
  static const kPrimary        = Color(0xFF4A7055);
  static const kPrimaryMid     = Color(0xFF7FAF8C);
  static const kPrimaryLight   = Color(0xFFEBF2EC);
  static const kDarkPrimaryText = Color(0xFF27500A);

  static const kBackground     = Color(0xFFF7F4EF);
  static const kSurface        = Color(0xFFFFFFFF);
  static const kSurface2       = Color(0xFFF0EDE6);

  static const kTextPrimary    = Color(0xFF1A1A1A);
  static const kTextSecondary  = Color(0xFF6B6560);
  static const kTextTertiary   = Color(0xFF9B9490);

  static const kBorder         = Color(0xFFE6E1D8);
  static const kBorderFocus    = Color(0xFFC8DEC8);

  // Dark theme tokens
  static const kDarkBackground = Color(0xFF111511);
  static const kDarkSurface    = Color(0xFF181E18);
  static const kDarkSurface2   = Color(0xFF202820);
  static const kDarkPrimary    = Color(0xFF6BAF80);
  static const kDarkText       = Color(0xFFF0EFEC);
  static const kDarkTextSecond = Color(0xFF9E9C97);
  static const kDarkBorder     = Color(0xFF2C342C);

  // ── Light theme ────────────────────────────────────────────────
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
        fontSize: 11, fontWeight: FontWeight.w600, color: kTextSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder, width: 0.5)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder, width: 0.5)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w700),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimary,
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: kPrimary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w600),
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

  // ── Dark theme ─────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: kDarkBackground,
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
    // Mirror light theme structure — replace all light tokens with dark tokens
  );
}
```

**In `main.dart`:**
```dart
MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ThemeMode.system,
  home: const SplashScreen(),
)
```

---

## 41. Section 4 Tab Options — Code Comparison

Three options were designed. **Option A is locked as the primary choice.** B and C are documented alternatives.

Full Flutter code for all three options is in the separate file: `option_a_scrollable_tabbar.dart`, `option_b_grid.dart`, `option_chip_style.dart`.

---

### Summary comparison

| Aspect | Option A — Scrollable TabBar | Option B — 2×2 Grid | Option C — Chip Row |
|---|---|---|---|
| Flutter widget type | StatelessWidget | StatefulWidget | StatefulWidget |
| State management | DefaultTabController (built-in, automatic) | Manual `_selectedIndex` + setState | Manual `_selectedIndex` + setState |
| Swipe between tabs | YES — TabBarView handles it | NO | NO |
| Tab visibility | 3 tabs visible, 4th peeks + gradient | All 4 always visible | All 4 visible in a scrollable row |
| Selection lines of code | ~20 lines | ~55 lines | ~45 lines |
| Count shown | Below label, separate line | Below label, inline "N items" | Inline in chip label "Never Worn · 5" |
| Visual consistency with app | Different from chips elsewhere | Different from chips | Same as chips on other pages |
| Chosen? | ✅ YES — locked primary | ❌ Alternative | ❌ Alternative |

**Option A key implementation notes:**
- `isScrollable: true` makes tabs size to their content width
- `tabAlignment: TabAlignment.start` left-aligns them instead of stretching to fill
- The gradient overlay is a `Stack` child with `IgnorePointer` so taps pass through to the TabBar beneath
- Gradient width: 52px, fading from transparent to white (matching card background)

---

## 42. Colour Picker — Both Versions

### Version 1 — Swatch Grid (PRIMARY RECOMMENDATION)

Full visual specification is in Section 13 of this document.

**State logic (this is the one piece of code in this section):**

```dart
class _ColourPickerState extends State<ColourPickerWidget> {
  final Set<String> preferred = {};
  final Set<String> disliked  = {};
  static const int maxSelections = 3;

  // Key rule: a colour cannot be in both sets at the same time
  void togglePreferred(String colour) {
    if (disliked.contains(colour)) return;  // blocked — already disliked
    setState(() {
      if (preferred.contains(colour)) {
        preferred.remove(colour);           // deselect
      } else if (preferred.length < maxSelections) {
        preferred.add(colour);              // select
      }
      // If max reached and not already selected: no-op
      // The tile's visual opacity (35%) already communicates this to the user
    });
  }

  void toggleDisliked(String colour) {
    if (preferred.contains(colour)) return;  // blocked — already preferred
    setState(() {
      if (disliked.contains(colour)) {
        disliked.remove(colour);
      } else if (disliked.length < maxSelections) {
        disliked.add(colour);
      }
    });
  }

  // Tile state resolver — call this per swatch to determine visual state
  SwatchState getSwatchState(String colour, bool isPreferredSection) {
    final targetSet = isPreferredSection ? preferred : disliked;
    final otherSet  = isPreferredSection ? disliked  : preferred;

    if (targetSet.contains(colour))   return SwatchState.selected;
    if (otherSet.contains(colour))    return SwatchState.disabledOtherList;
    if (targetSet.length >= maxSelections) return SwatchState.disabledMaxReached;
    return SwatchState.available;
  }
}

enum SwatchState { available, selected, disabledOtherList, disabledMaxReached }
```

**Visual state mapping:**
- `available`: full opacity, no border, tappable
- `selected`: full opacity, 2.5px border in section colour, checkmark/X badge, tappable (to deselect)
- `disabledOtherList`: 25% opacity, not tappable
- `disabledMaxReached`: 35% opacity, not tappable

---

### Version 2 — Dropdown Checkbox (SIMPLER ALTERNATIVE)

**When to use:** When development time is limited. Produces the same data output. Less visual but fully functional.

**Main page appearance:**
- Two tappable fields (one per section)
- Each field is the standard input field shape (12px radius, 14px padding, #E6E1D8 border)
- When empty: placeholder "Select colours..." in #9B9490
- When populated: shows small 20×20px colour swatches (left) + colour names (right) inside the field
- Border changes to #C8DEC8 when populated (green tint to show it has a value)
- Chevron-down icon on right

**Bottom sheet appearance:**
- Drag handle + section title + "X / 3 selected" counter
- Subtitle: "Select up to 3. Already chosen colours are greyed out."
- Scrollable list of all 12 colours
- Each row: 24×24px colour swatch + colour name (13px semibold) + checkbox on right
- Selected row: light green row background (#EBF2EC), filled checkbox in section colour
- Disabled row (in other section): 50% opacity, label shows "· already disliked/loved" in 11px, #9B9490
- "Done" primary button at bottom

---

## 43. Locked Design Decisions

| # | Decision | What was locked | Reasoning |
|---|---|---|---|
| 1 | Font | Plus Jakarta Sans | Warm, modern, clear at small sizes. Free via Google Fonts. |
| 2 | Background colour | #F7F4EF (warm off-white) | Not pure white. Softer, lifestyle feel. |
| 3 | Brand green | #4A7055 (sage green) | Calm, sustainable. Not aggressive. |
| 4 | Bottom nav | Home · Wardrobe · Outfit · Donate · Insights | Locked. Profile is NOT a bottom tab. |
| 5 | Profile access | Top-right avatar only | Consistent across all 5 main pages. |
| 6 | Section 4 tabs | Option A — scrollable TabBar + gradient | Lowest code, built-in swipe, gradient communicates scrollability. |
| 7 | Gradient fade width | 52px | Fades "Overused" tab text without covering "Skipped Often". |
| 8 | Green swatch hex | #22C55E | Must NOT be #4A7055 (brand colour). Would look selected when not. |
| 9 | Grey swatch hex | #9CA3AF | Must NOT be #9B9490 (Text-Tertiary). Neutral cool grey is more accurate. |
| 10 | Colour picker primary | Version 1 swatch grid | More engaging, faster to use, everything visible immediately. |
| 11 | Colour picker fallback | Version 2 dropdown | Simpler code. Valid when under time pressure. |
| 12 | Max colour selections | 3 per section | Prevents PS formula from becoming noise. Forces genuine prioritisation. |
| 13 | Style preferences content | Colours only | S5 formula only uses colour. Adding type/category would be redundant with S2 SPS. |
| 14 | Max reached hint | Removed | Opacity fade alone is sufficient signal. Text is clutter. |
| 15 | Item Status Manager | Removed from Settings | Status managed from Item Detail. Dedicated screen is redundant scope. |
| 16 | Laundry Cycle control | Inline stepper (no sub-page) | Single number (1–14 days). No sub-page needed. |
| 17 | App Theme | Sub-page with radio buttons | Segmented control too cramped in list row on small phones. |
| 18 | Recommendation Mode | Inline toggle in Settings | Binary choice. Toggle is clearest control for a binary setting. |
| 19 | Delete item flow | Confirmation dialog + 5-second undo snackbar | No trash state. Delete is permanent but undoable briefly. |
| 20 | Donation tier badges | Removed from candidate cards | DPS handles sorting order. "Strong Candidate" label on card adds no value. |
| 21 | Item Donation Detail screen | Does not exist | Item Detail covers everything via Rule-Based Usage Summary section. |
| 22 | Confirmation sheets | One universal widget, 7 uses | All uses share same structure. Only title, description, button label, button colour vary. |
| 23 | Section 4 default tab | Never Worn | Most actionable for new users — new items they should try first. |
| 24 | Sleeping items threshold | 90 days (Section 3 link) | Stronger signal than the 60-day threshold used for Long Unused tab. |
| 25 | FAB position | Bottom-right, no label | Standard Material Design. Label crowds the grid. |
| 26 | Favourite star colour | Yellow #FACC15 | Universal favourite convention. Only shown when `is_favorite == true`. |
| 27 | Onboarding page 4 CTA | "Not Now" (not "Skip") | Permission request context. "Not Now" is softer — user doesn't feel like skipping a feature. |
| 28 | Splash loading indicator | Spinning ring | Dots look like onboarding page indicators — confusing before onboarding. |
| 29 | F1 Season filter | Dropped from MVP | Malaysia's dry/rainy seasons don't strongly dictate clothing choices. |
| 30 | Occasions | Casual · Work · Active · Relax | "Formal" dropped (too niche). "Sport" renamed Active. Four is sufficient. |
| 31 | Outfit tab selector | Segmented pill control | Cleaner than underline tabs for exactly 2 options. |
| 32 | Suggestion cards | PageView carousel with 0.88 viewport fraction | Shows bleed of next card. Communicates scrollability without dots. |
| 33 | Badge alignment | crossAxisAlignment.center on parent Row | Without this, different-length badge texts cause vertical misalignment in the grid. |
| 34 | Card border width | 0.5px | Visible but not heavy. App uses borders not shadows for depth. |

---

*End of Frontend Reference — Plain English Edition v1.0*
*Companion file: `Wardrobe_App_Frontend_Reference.md` (code-heavy version)*
*Both files together cover every detail needed to build the Flutter frontend.*
