import 'package:flutter/material.dart';

import '../theme/app_color_scheme.dart';

/// Onboarding page indicator (Frontend §12). Active dot is a wide green pill;
/// inactive dots are small grey circles.
class ProgressDots extends StatelessWidget {
  const ProgressDots({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? context.colors.primary : context.colors.border,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
