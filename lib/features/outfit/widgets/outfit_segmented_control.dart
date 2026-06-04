import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';

/// Rounded segmented pill that switches between the Daily Rotation and Outfit
/// Generator tabs. Source: FE §6.17.
class OutfitSegmentedControl extends StatelessWidget {
  const OutfitSegmentedControl({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    this.labels = const ['Daily Rotation', 'Outfit Generator'],
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        // §6.17: slightly darker than background. surface2 carries this tone in
        // both themes.
        color: c.surface2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: _Segment(
                label: labels[i],
                active: selectedIndex == i,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? c.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? c.textPrimary : c.textTertiary,
          ),
        ),
      ),
    );
  }
}
