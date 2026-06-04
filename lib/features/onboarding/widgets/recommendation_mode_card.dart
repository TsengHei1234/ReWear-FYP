import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';

/// Selectable option card for Recommendation Mode (Frontend §14).
/// Reused by onboarding page 3 and the App Theme / settings screens.
class RecommendationModeCard extends StatelessWidget {
  const RecommendationModeCard({
    super.key,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.recommended = false,
  });

  final String title;
  final String description;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? context.colors.primary : context.colors.border,
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Radio(selected: selected),
                const SizedBox(width: 10),
                Text(title,
                    style: AppText.bodyM.copyWith(fontWeight: FontWeight.w700)),
                if (recommended) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: context.colors.primaryLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('Recommended',
                        style: AppText.micro.copyWith(
                            color: context.colors.onPrimaryLight,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(description,
                  style: AppText.labelS.copyWith(
                      color: context.colors.textSecondary, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Radio dot (Frontend §6.12).
class _Radio extends StatelessWidget {
  const _Radio({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: selected ? context.colors.primary : context.colors.surface,
        shape: BoxShape.circle,
        border: selected ? null : Border.all(color: context.colors.border, width: 1.5),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
            )
          : null,
    );
  }
}
