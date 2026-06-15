import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../routing/app_router.dart';

/// Top-bar avatar circle: shows the user's initials and pushes [Routes.settings].
/// Used in Home, Outfit, Donate, and Insights top bars.
class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({
    super.key,
    required this.source,
    this.size = 36,
  });

  /// Display name or email — used to compute the 1–2 letter initials.
  final String? source;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () => context.push(Routes.settings),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          _initials(source),
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
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
