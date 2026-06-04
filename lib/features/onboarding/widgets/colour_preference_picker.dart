import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Colour picker — Version 1 swatch grid (Frontend §13, §42, locked #10).
///
/// Controlled widget: the parent owns the two sets and the toggle logic
/// (max 3 each, a colour cannot be in both). Reused by onboarding page 2 and
/// the Style Preferences settings screen.
class ColourPreferencePicker extends StatelessWidget {
  const ColourPreferencePicker({
    super.key,
    required this.preferred,
    required this.disliked,
    required this.onTogglePreferred,
    required this.onToggleDisliked,
    this.maxPerSection = AppConstants.maxColourSelections,
  });

  final Set<String> preferred;
  final Set<String> disliked;
  final ValueChanged<String> onTogglePreferred;
  final ValueChanged<String> onToggleDisliked;
  final int maxPerSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          title: 'COLOURS I LOVE',
          accent: context.colors.primary,
          selected: preferred,
          other: disliked,
          onToggle: onTogglePreferred,
          isPreferred: true,
        ),
        const SizedBox(height: 20),
        _section(
          title: 'COLOURS I DISLIKE',
          accent: AppColors.danger,
          selected: disliked,
          other: preferred,
          onToggle: onToggleDisliked,
          isPreferred: false,
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    required Color accent,
    required Set<String> selected,
    required Set<String> other,
    required ValueChanged<String> onToggle,
    required bool isPreferred,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: AppText.captionBold.copyWith(
                    color: accent, letterSpacing: 0.08 * 11)),
            Text('${selected.length} / $maxPerSection',
                style: AppText.caption.copyWith(
                    color: accent, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final swatch in SwatchColour.values)
              _Swatch(
                colour: kSwatchColours[swatch]!,
                accent: accent,
                isPreferred: isPreferred,
                state: _stateFor(swatch.value, selected, other),
                onTap: () => onToggle(swatch.value),
              ),
          ],
        ),
      ],
    );
  }

  _SwatchState _stateFor(String value, Set<String> target, Set<String> other) {
    if (target.contains(value)) return _SwatchState.selected;
    if (other.contains(value)) return _SwatchState.disabledOtherList;
    if (target.length >= maxPerSection) return _SwatchState.disabledMaxReached;
    return _SwatchState.available;
  }
}

enum _SwatchState { available, selected, disabledOtherList, disabledMaxReached }

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.colour,
    required this.accent,
    required this.isPreferred,
    required this.state,
    required this.onTap,
  });

  final Color colour;
  final Color accent;
  final bool isPreferred;
  final _SwatchState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = colour == AppColors.swatchWhite;
    final opacity = switch (state) {
      _SwatchState.disabledOtherList => 0.25,
      _SwatchState.disabledMaxReached => 0.35,
      _ => 1.0,
    };
    final selected = state == _SwatchState.selected;
    final tappable =
        state == _SwatchState.available || state == _SwatchState.selected;

    return GestureDetector(
      onTap: tappable ? onTap : null,
      child: Opacity(
        opacity: opacity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colour,
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(color: accent, width: 2.5)
                    : isWhite
                        ? Border.all(color: context.colors.border, width: 1)
                        : null,
              ),
            ),
            if (selected)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: Icon(
                    isPreferred ? Icons.check : Icons.close,
                    size: 9,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
