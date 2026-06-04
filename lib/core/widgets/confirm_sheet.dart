import 'package:flutter/material.dart';

import '../theme/app_color_scheme.dart';
import '../theme/app_colors.dart';

/// Universal confirmation bottom sheet. Source: FE §38.
///
/// Returns `true` when the user taps the confirm action, `false`/`null` when
/// they cancel or dismiss. Set [isDestructive] for danger-red actions
/// (delete / skip — FE destructive action list).
Future<bool> showConfirmSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  String? message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final c = context.colors;
  final accent = isDestructive ? AppColors.danger : c.primary;

  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(sheetCtx).viewPadding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 20),
          Icon(icon, size: 40, color: accent),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
          const SizedBox(height: 24),
          // Side-by-side: neutral Cancel (left) + filled action (right).
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetCtx).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textPrimary,
                      backgroundColor: c.surface,
                      side: BorderSide(color: c.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(cancelLabel,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(sheetCtx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(confirmLabel,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

/// Confirm sheet for logging a wear (non-destructive). Reused by the Wardrobe
/// card, Item Detail, and Daily Rotation so the message stays consistent.
Future<bool> showLogWearSheet(BuildContext context, String itemName) =>
    showConfirmSheet(
      context,
      icon: Icons.check_circle_outline,
      title: 'Log a wear for $itemName?',
      message: "It won't appear in today's rotation again.",
      confirmLabel: 'Log Wear',
    );
