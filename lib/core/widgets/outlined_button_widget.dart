import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-width outlined button. Source: FE §6.2.
///
/// Named [OutlinedButtonWidget] to avoid clashing with Flutter's [OutlinedButton].
class OutlinedButtonWidget extends StatelessWidget {
  const OutlinedButtonWidget({
    super.key,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// When true, renders in danger red (FE §6.3 Destructive Outlined Button).
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colour = isDestructive ? AppColors.danger : AppColors.primary;
    final pressedBg =
        isDestructive ? AppColors.dangerBg : const Color(0xFFEBF2EC);

    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colour,
          side: BorderSide(
            color: colour,
            width: isDestructive ? 1.5 : 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.transparent,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return pressedBg;
            return null;
          }),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colour,
          ),
        ),
      ),
    );
  }
}
