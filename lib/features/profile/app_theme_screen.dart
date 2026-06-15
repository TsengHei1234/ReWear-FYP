import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../providers/theme_mode_provider.dart';

/// Light / Dark / System theme selector — persisted via [themeModeProvider]
/// to SharedPreferences (FE §34).
class AppThemeScreen extends ConsumerWidget {
  const AppThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final current =
        ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system;

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
          'App Theme',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'APPEARANCE',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
                letterSpacing: 1.1),
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
                _ThemeTile(
                  icon: Icons.brightness_auto_rounded,
                  title: 'System default',
                  subtitle: 'Follows your device setting',
                  selected: current == ThemeMode.system,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.system),
                ),
                Divider(height: 0.5, thickness: 0.5, color: c.border),
                _ThemeTile(
                  icon: Icons.brightness_high_rounded,
                  title: 'Light',
                  subtitle: 'Always use light mode',
                  selected: current == ThemeMode.light,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.light),
                ),
                Divider(height: 0.5, thickness: 0.5, color: c.border),
                _ThemeTile(
                  icon: Icons.brightness_2_rounded,
                  title: 'Dark',
                  subtitle: 'Always use dark mode',
                  selected: current == ThemeMode.dark,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
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
            Icon(icon, size: 20, color: selected ? c.primary : c.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? c.primary : c.textPrimary),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style:
                        TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? c.primary : c.border,
            ),
          ],
        ),
      ),
    );
  }
}
