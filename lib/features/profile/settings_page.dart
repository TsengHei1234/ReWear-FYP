import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../data/models/profile.dart';
import '../../providers/auth_providers.dart';
import '../../providers/profile_providers.dart';
import '../../providers/theme_mode_provider.dart';
import '../../routing/app_router.dart';

/// Profile & Settings hub (FE §31).
///
/// Shows the user's avatar + name, and provides navigation to all sub-screens.
/// Recommendation Mode and Laundry Cycle are inline interactive controls that
/// write directly to [profileProvider]; all other items navigate to sub-pages.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final profile = ref.watch(profileProvider).asData?.value;
    final themeMode =
        ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Profile & Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
        children: [
          _AvatarBlock(profile: profile),
          const SizedBox(height: 4),
          _Section(
            label: 'ACCOUNT',
            children: [
              _NavTile(
                icon: Icons.person_outline_rounded,
                title: 'My Profile',
                onTap: () => context.push(Routes.settingsProfile),
              ),
              _NavTile(
                icon: Icons.palette_outlined,
                title: 'Style Preferences',
                onTap: () => context.push(Routes.settingsStylePrefs),
              ),
            ],
          ),
          _Section(
            label: 'APP',
            children: [
              _RecommendationModeTile(
                mode: profile?.recommendationMode,
                onChanged: profile == null
                    ? null
                    : (v) => ref
                        .read(profileProvider.notifier)
                        .updateProfile(profile.copyWith(
                          recommendationMode: v
                              ? RecommendationMode.balanced
                              : RecommendationMode.pureRotation,
                        )),
              ),
              _LaundryCycleTile(
                days: profile?.laundryCycleDays ?? 3,
                enabled: profile != null,
                onDecrement: profile != null && profile.laundryCycleDays > 1
                    ? () => ref
                        .read(profileProvider.notifier)
                        .updateProfile(profile.copyWith(
                          laundryCycleDays: profile.laundryCycleDays - 1,
                        ))
                    : null,
                onIncrement: profile != null && profile.laundryCycleDays < 14
                    ? () => ref
                        .read(profileProvider.notifier)
                        .updateProfile(profile.copyWith(
                          laundryCycleDays: profile.laundryCycleDays + 1,
                        ))
                    : null,
              ),
              _NavTile(
                icon: Icons.brightness_6_outlined,
                title: 'App Theme',
                subtitle: _themeLabel(themeMode),
                onTap: () => context.push(Routes.settingsTheme),
              ),
            ],
          ),
          _Section(
            label: 'NOTIFICATIONS',
            children: [
              _NavTile(
                icon: Icons.notifications_outlined,
                title: 'Notification Settings',
                onTap: () => context.push(Routes.settingsNotifications),
              ),
            ],
          ),
          _Section(
            label: 'MORE',
            children: [
              _NavTile(
                icon: Icons.shield_outlined,
                title: 'Data & Privacy',
                onTap: () => context.push(Routes.settingsDataPrivacy),
              ),
              _NavTile(
                icon: Icons.info_outline_rounded,
                title: 'Help / About',
                subtitle: 'Version 1.0.0',
                onTap: () => context.push(Routes.settingsHelpAbout),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _LogOutButton(
              onTap: () => _signOut(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmSheet(
      context,
      icon: Icons.logout_rounded,
      title: 'Log out?',
      message: 'You will be returned to the login screen.',
      confirmLabel: 'Log Out',
      isDestructive: false,
    );
    if (!ok) return;
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    context.go(Routes.login);
  }

  static String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System default',
      };
}

// ── Avatar block ─────────────────────────────────────────────────────────────

class _AvatarBlock extends StatelessWidget {
  const _AvatarBlock({required this.profile});
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final source = profile?.displayName ?? profile?.email;
    final name = profile?.displayName?.trim() ?? '';
    final email = profile?.email?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration:
                BoxDecoration(color: c.primary, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              _initials(source),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ],
          if (email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              email,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  static String _initials(String? source) {
    if (source == null || source.trim().isEmpty) return '?';
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border, width: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(height: 0.5, thickness: 0.5, color: c.border),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Standard navigation tile ──────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(subtitle!,
                        style:
                            TextStyle(fontSize: 12, color: c.textSecondary)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 20, color: c.chevron),
          ],
        ),
      ),
    );
  }
}

// ── Recommendation Mode tile (inline toggle) ──────────────────────────────────

class _RecommendationModeTile extends StatelessWidget {
  const _RecommendationModeTile({
    required this.mode,
    required this.onChanged,
  });

  final RecommendationMode? mode;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isBalanced = mode == null || mode == RecommendationMode.balanced;
    final subtitle = isBalanced ? 'Balanced Rotation' : 'Pure Rotation';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, size: 20, color: c.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recommendation Mode',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: c.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: isBalanced,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: c.primary,
          ),
        ],
      ),
    );
  }
}

// ── Laundry Cycle tile (inline stepper) ───────────────────────────────────────

class _LaundryCycleTile extends StatelessWidget {
  const _LaundryCycleTile({
    required this.days,
    required this.enabled,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int days;
  final bool enabled;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.local_laundry_service_outlined,
              size: 20, color: c.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Laundry Cycle',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary)),
                const SizedBox(height: 1),
                Text('Days before items return',
                    style: TextStyle(fontSize: 12, color: c.textSecondary)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: enabled ? onDecrement : null,
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$days',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                onTap: enabled ? onIncrement : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: active ? c.primaryLight : c.surface2,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(icon,
            size: 16,
            color: active ? c.primary : c.textTertiary),
      ),
    );
  }
}

// ── Log Out button ────────────────────────────────────────────────────────────

class _LogOutButton extends StatelessWidget {
  const _LogOutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          border: Border.all(color: AppColors.dangerBorder, width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded,
                size: 18, color: AppColors.danger),
            const SizedBox(width: 8),
            const Text(
              'Log Out',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
