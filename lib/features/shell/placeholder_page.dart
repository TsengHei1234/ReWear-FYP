import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';

/// Temporary placeholder used for tabs not yet built (Phases 6–7).
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: Center(
        child: Text(
          '$title\n(coming soon)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: c.textSecondary,
          ),
        ),
      ),
    );
  }
}
