# Feature Contract — Auth + Onboarding (Phase 2)

**Search keywords:** Splash, Login, Sign Up, Forgot Password, Onboarding, Skip,
colour picker, recommendation mode, style_preferences, auth session.

## Source sections used
- FE: §7 (nav flow), §8 Splash, §9 Login, §10 Sign Up, §11 Forgot Password,
  §12–§15 Onboarding 1–4, §42 Colour picker V1, §6 components.
- RE: "Locked Occasions", S5 PS (colour prefs), S6 FRS Mode A/B.
- DB: `profiles` (display_name, style_preferences, recommendation_mode, laundry_cycle_days).
- DECISIONS: C-colour picker V1, M2 (notif times — N/A here, just the permission ask).

## Navigation flow (FE §7)
Splash → check Supabase session → if logged in: Home; else: Login.
After Sign Up → Onboarding 1. After onboarding complete → Home.
Login/Signup/Forgot are full pushed routes. Onboarding is a 4-page flow.

## Screens & required behaviour
- **Splash (§8):** green bg, app icon tile, "ReWear" wordmark, spinner near bottom.
  Decides route from `auth.currentSession`. (Also: future home for laundry auto-return.)
- **Login (§9):** email + password (eye toggle) fields, Forgot link, Sign In (primary),
  Sign Up link. On success → Home.
- **Sign Up (§10):** display name, email, password, confirm password (eye toggles).
  Validate match. On success → Onboarding 1 (signup trigger auto-creates profiles row).
- **Forgot Password (§11):** email field → send reset link → success state. Supabase
  default hosted reset flow (DECISIONS M3).
- **Onboarding 1 Welcome (§12):** icon, headline, description, 4 progress dots (1 active),
  Get Started.
- **Onboarding 2 Style Preferences (§13, §42):** colour picker **V1 swatch grid** —
  "Colours I Love" (max 3) + "Colours I Dislike" (max 3), mutual exclusion, 12 swatches.
  Skip allowed. Writes to `profiles.style_preferences = {preferred_colours, disliked_colours}`.
- **Onboarding 3 Recommendation Mode (§14):** two radio cards — Balanced (pre-selected,
  "Recommended") vs Pure Rotation. Writes `profiles.recommendation_mode` (BALANCED/PURE_ROTATION).
- **Onboarding 4 Notifications (§15):** feature list + "Allow Notifications" + "Not Now".
  Request OS notification permission (deferred to Phase 8 service; here just the ask/skip).
  On finish → Home.

## DB reads/writes
- reads: `auth.currentSession` / auth state stream.
- writes: auth signUp/signInWithPassword/resetPasswordForEmail/signOut.
  `profiles` update: display_name (from signup), style_preferences, recommendation_mode,
  laundry_cycle_days (default 3 already in DB). Onboarding collects then writes once.

## Colour picker V1 state logic (§42)
Two Set<String> (preferred, disliked), max 3 each, a colour cannot be in both.
States: available / selected / disabledOtherList (25% opacity) / disabledMaxReached (35%).

## Edge cases / empty & error states
- [ ] Wrong password / unknown email → friendly error (snackbar/inline).
- [ ] Sign up password mismatch → inline validation, block submit.
- [ ] Email already registered → surface Supabase error.
- [ ] Skip on onboarding 2/3 → keep DB defaults (empty prefs / BALANCED).
- [ ] Network failure on auth → snackbar, stay on screen.

## Open questions
- Notification permission: full impl deferred to Phase 8. Phase 2 = UI + skip only.

## Verification checklist
- [ ] `flutter analyze` clean.
- [ ] `flutter run --dart-define-from-file=config/supabase.local.json` boots to Login.
- [ ] Sign up a test user → lands on Onboarding 1 → finishes → Home.
- [ ] Confirm a `profiles` row exists for the new user (trigger) with onboarding values saved.
- [ ] Log out → Login; log back in → Home (session persists on restart).
