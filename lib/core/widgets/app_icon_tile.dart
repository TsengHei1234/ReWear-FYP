import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rounded-square icon tile used on auth/onboarding headers and settings rows
/// (Frontend §6.11, §8–§15). Size, colours and radius vary by context.
class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.icon,
    this.size = 60,
    this.radius = 18,
    this.background = AppColors.primary,
    this.iconColor = Colors.white,
    double? iconSize,
  }) : iconSize = iconSize ?? size * 0.46;

  final IconData icon;
  final double size;
  final double radius;
  final Color background;
  final Color iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }
}
