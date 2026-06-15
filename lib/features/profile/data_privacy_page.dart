import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../providers/auth_providers.dart';
import '../../routing/app_router.dart';

/// Account control: sign out and deletion-request info (FE §36).
///
/// MVP constraint: no in-app hard-delete of Supabase Auth accounts.
/// Users must contact the developer to request permanent data removal.
class DataPrivacyPage extends ConsumerWidget {
  const DataPrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Data & Privacy',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
        children: [
          // ── Your data ─────────────────────────────────────────────────────
          const _SectionCard(
            label: 'YOUR DATA',
            children: [
              _InfoRow(
                icon: Icons.security_outlined,
                body:
                    'ReWear stores your wardrobe items, outfit history, and style '
                    'preferences securely in the cloud. Your data is associated with '
                    'your account and is not shared with third parties.',
              ),
            ],
          ),
          // ── Sign out ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIGN OUT',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                      letterSpacing: 1.1),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _signOut(context, ref),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      border: Border.all(
                          color: AppColors.dangerBorder, width: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            size: 18, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Account deletion ──────────────────────────────────────────────
          const _SectionCard(
            label: 'ACCOUNT DELETION',
            children: [
              _InfoRow(
                icon: Icons.person_remove_outlined,
                title: 'Request Account Deletion',
                body:
                    'To permanently delete your account and all associated data, '
                    'please contact the app developer. We will process your request '
                    'within a reasonable timeframe.',
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                border:
                    Border.all(color: AppColors.dangerBorder, width: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.danger),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'In-app account deletion is not available in this version. '
                      'Please contact the developer to request permanent removal '
                      'of your data.',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.danger,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
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
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.children});
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
                letterSpacing: 1.1),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border, width: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, this.title, required this.body});
  final IconData icon;
  final String? title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: c.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  body,
                  style: TextStyle(
                      fontSize: 13, color: c.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
