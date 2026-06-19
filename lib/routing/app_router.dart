import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/item.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/set_new_password_screen.dart';
import '../features/donate/donate_page.dart';
import '../features/donate/donation_history_page.dart';
import '../features/donate/kept_items_page.dart';
import '../features/insights/insights_page.dart';
import '../features/insights/view_all_page.dart';
import '../features/profile/app_theme_screen.dart';
import '../features/profile/data_privacy_page.dart';
import '../features/profile/help_about_page.dart';
import '../features/profile/my_profile_page.dart';
import '../features/profile/notification_settings_page.dart';
import '../features/profile/settings_page.dart';
import '../features/profile/style_prefs_edit_page.dart';
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
import '../features/wardrobe/add_edit_item_page.dart';
import '../features/wardrobe/wardrobe_page.dart';
import '../providers/insights_providers.dart';
import '../providers/wardrobe_providers.dart';

/// App route paths — avoid string typos across the codebase.
abstract class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const setNewPassword = '/set-new-password';
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
  static const itemDetailById = '/item-detail-id';
  static const wearHistory = '/wear-history';

  // ── Outfit sub-pages ──────────────────────────────────────────
  static const outfitDetail = '/outfit-detail';
  static const outfitHistory = '/outfit-history';

  // ── Donate sub-pages ──────────────────────────────────────────
  static const keptItems = '/kept-items';
  static const donationHistory = '/donation-history';

  // ── Insights sub-pages ────────────────────────────────────────
  static const viewAll = '/view-all';

  // Profile & Settings sub-pages
  static const settings = '/settings';
  static const settingsProfile = '/settings/profile';
  static const settingsStylePrefs = '/settings/style-prefs';
  static const settingsTheme = '/settings/theme';
  static const settingsNotifications = '/settings/notifications';
  static const settingsDataPrivacy = '/settings/data-privacy';
  static const settingsHelpAbout = '/settings/help-about';
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
      path: Routes.setNewPassword,
      builder: (context, state) => const SetNewPasswordScreen(),
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
    // Notification tap adapter: resolves itemId → Item from wardrobe state.
    GoRoute(
      path: '${Routes.itemDetailById}/:id',
      builder: (context, state) {
        final itemId = state.pathParameters['id']!;
        return _ItemDetailByIdPage(itemId: itemId);
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

    // ── Donate sub-pages (no shell nav bar) ──────────────────────
    GoRoute(
      path: Routes.keptItems,
      builder: (context, state) => const KeptItemsPage(),
    ),
    GoRoute(
      path: Routes.donationHistory,
      builder: (context, state) => const DonationHistoryPage(),
    ),

    // ── Insights sub-pages (no shell nav bar) ────────────────────
    GoRoute(
      path: Routes.viewAll,
      builder: (context, state) {
        final type = state.extra as InsightViewAllType;
        return ViewAllPage(type: type);
      },
    ),

    // Profile & Settings sub-pages (no shell nav bar)
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: Routes.settingsProfile,
      builder: (context, state) => const MyProfilePage(),
    ),
    GoRoute(
      path: Routes.settingsStylePrefs,
      builder: (context, state) => const StylePrefsEditPage(),
    ),
    GoRoute(
      path: Routes.settingsTheme,
      builder: (context, state) => const AppThemeScreen(),
    ),
    GoRoute(
      path: Routes.settingsNotifications,
      builder: (context, state) => const NotificationSettingsPage(),
    ),
    GoRoute(
      path: Routes.settingsDataPrivacy,
      builder: (context, state) => const DataPrivacyPage(),
    ),
    GoRoute(
      path: Routes.settingsHelpAbout,
      builder: (context, state) => const HelpAboutPage(),
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
              builder: (context, state) => const DonatePage(),
            ),
          ],
        ),

        // Branch 4 — Insights (Phase 7)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.shellInsights,
              builder: (context, state) => const InsightsPage(),
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

/// Looks up [itemId] in the live wardrobe state and renders [ItemDetailPage].
/// Used by N6 notification taps so the deep-link only needs the item's UUID.
class _ItemDetailByIdPage extends ConsumerWidget {
  const _ItemDetailByIdPage({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(wardrobeProvider).when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Item not found')),
      ),
      data: (items) {
        final item = items.where((i) => i.id == itemId).firstOrNull;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Item not found')),
          );
        }
        return ItemDetailPage(item: item);
      },
    );
  }
}
