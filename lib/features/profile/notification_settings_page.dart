import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../providers/notification_settings_provider.dart';

/// Notification Settings — per-notification toggles for N1–N6 (FE §35).
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final togglesAsync = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

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
          'Notification Settings',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: togglesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Text('Could not load settings',
              style: TextStyle(color: c.textSecondary)),
        ),
        data: (toggles) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            _SectionHeader(label: 'Logging Reminders', colors: c),
            _ToggleTile(
              colors: c,
              icon: Icons.wb_sunny_outlined,
              title: 'Daily Reminder',
              subtitle: "Remind me to log today's outfit",
              value: toggles.n1,
              onChanged: notifier.setN1,
            ),
            _ToggleTile(
              colors: c,
              icon: Icons.warning_amber_outlined,
              title: 'Inactive Warning',
              subtitle: 'Alert after 3+ days without logging',
              value: toggles.n2,
              onChanged: notifier.setN2,
            ),
            const SizedBox(height: 12),
            _SectionHeader(label: 'Wardrobe Insights', colors: c),
            _ToggleTile(
              colors: c,
              icon: Icons.bedtime_outlined,
              title: 'Long-Unworn Alert',
              subtitle: 'Notify about items not worn recently',
              value: toggles.n3,
              onChanged: notifier.setN3,
            ),
            _ToggleTile(
              colors: c,
              icon: Icons.volunteer_activism_outlined,
              title: 'Donation Reminder',
              subtitle: 'Remind about donation candidates',
              value: toggles.n4,
              onChanged: notifier.setN4,
            ),
            _ToggleTile(
              colors: c,
              icon: Icons.bar_chart_rounded,
              title: 'Weekly Summary',
              subtitle: 'Weekly wardrobe stats every Sunday',
              value: toggles.n5,
              onChanged: notifier.setN5,
            ),
            const SizedBox(height: 12),
            _SectionHeader(label: 'Item Updates', colors: c),
            _ToggleTile(
              colors: c,
              icon: Icons.auto_awesome_outlined,
              title: 'Condition Updates',
              subtitle: 'Alert when item condition changes (Auto mode only)',
              value: toggles.n6,
              onChanged: notifier.setN6,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.colors});

  final String label;
  final AppColorsTheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.colors,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final AppColorsTheme colors;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: colors.textSecondary),
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
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
