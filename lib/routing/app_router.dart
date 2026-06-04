import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/item.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/wardrobe/full_wear_history_page.dart';
import '../features/wardrobe/item_detail_page.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/home/home_page.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../features/outfit/outfit_detail_page.dart';
import '../features/outfit/outfit_history_page.dart';
import '../features/outfit/outfit_page.dart';
import '../features/shell/main_shell.dart';
import '../features/shell/placeholder_page.dart';
import '../features/wardrobe/add_edit_item_page.dart';
import '../features/wardrobe/wardrobe_page.dart';

/// App route paths — avoid string typos across the codebase.
abstract class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const onboarding = '/onboarding';

  // ── Main shell tabs ────────────────────────────────────────────
  static const shellHome = '/home';
  static const shellWardrobe = '/wardrobe';
  static const shellOutfit = '/outfit';
  static const shellDonate = '/donate';
  static const shellInsights = '/insights';

  // ── Wardrobe sub-pages (full-screen, no nav bar) ──────────────
  static const addItem = '/add-item';
  static const editItem = '/edit-item';
  static const itemDetail = '/item-detail';
  static const wearHistory = '/wear-history';

  // ── Outfit sub-pages ──────────────────────────────────────────
  static const outfitDetail = '/outfit-detail';
  static const outfitHistory = '/outfit-history';
}

/// Central router.
/// Splash checks session → routes to login or /wardrobe.
/// After signup + onboarding → /wardrobe (default until Home is built, Phase 6).
final appRouter = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    // ── Auth / onboarding (no shell) ──────────────────────────────
    GoRoute(
      path: Routes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: Routes.signup,
      builder: (context, state) => const SignUpScreen(),
    ),
    GoRoute(
      path: Routes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: Routes.onboarding,
      builder: (context, state) => const OnboardingFlow(),
    ),

    // ── Full-screen wardrobe flows (no shell nav bar) ────────────
    GoRoute(
      path: Routes.addItem,
      builder: (context, state) => const AddItemPage(),
    ),
    GoRoute(
      path: Routes.editItem,
      builder: (context, state) {
        final item = state.extra as Item;
        return EditItemPage(item: item);
      },
    ),
    GoRoute(
      path: Routes.itemDetail,
      builder: (context, state) {
        final item = state.extra as Item;
        return ItemDetailPage(item: item);
      },
    ),
    GoRoute(
      path: Routes.wearHistory,
      builder: (context, state) {
        final item = state.extra as Item;
        return FullWearHistoryPage(item: item);
      },
    ),
    GoRoute(
      path: Routes.outfitDetail,
      builder: (context, state) {
        final args = state.extra as OutfitDetailArgs;
        return OutfitDetailPage(args: args);
      },
    ),
    GoRoute(
      path: Routes.outfitHistory,
      builder: (context, state) => const OutfitHistoryPage(),
    ),

    // ── Main shell (5-tab persistent nav) ────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        // Branch 0 — Home (Phase 6)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.shellHome,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),

        // Branch 1 — Wardrobe (Phase 4)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.shellWardrobe,
              builder: (context, state) => const WardrobePage(),
            ),
          ],
        ),

        // Branch 2 — Outfit (Phase 6)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.shellOutfit,
              builder: (context, state) => const OutfitPage(),
            ),
          ],
        ),

        // Branch 3 — Donate (Phase 7)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.shellDonate,
              builder: (context, state) =>
                  const PlaceholderPage(title: 'Donate'),
            ),
          ],
        ),

        // Branch 4 — Insights (Phase 7)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.shellInsights,
              builder: (context, state) =>
                  const PlaceholderPage(title: 'Insights'),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Route not found: ${state.uri}')),
  ),
);
