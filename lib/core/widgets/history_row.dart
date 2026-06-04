import 'package:flutter/material.dart';

import '../theme/app_color_scheme.dart';

/// Reusable list row: leading circular icon + title + subtitle + optional
/// trailing widget.
///
/// Shared design for wear history and (future) kept items, donation history,
/// and the Insights View-All lists — they are all the same row shape.
class HistoryRow extends StatelessWidget {
  const HistoryRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.positive = true,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// true → green/primary tone (e.g. WORN); false → neutral grey (e.g. SKIPPED).
  final bool positive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: positive ? c.primaryLight : c.surface2,
            ),
            child: Icon(icon,
                size: 16, color: positive ? c.primary : c.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: TextStyle(fontSize: 11, color: c.textTertiary)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
