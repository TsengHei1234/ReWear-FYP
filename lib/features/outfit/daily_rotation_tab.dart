import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../data/models/item.dart';
import '../../engine/daily/daily_rotation_display.dart';
import '../../engine/scoring/frs.dart';
import '../../providers/daily_rotation_providers.dart';
import '../../providers/profile_providers.dart';
import '../../providers/wardrobe_providers.dart';
import '../../routing/app_router.dart';
import 'widgets/daily_rotation_card.dart';

/// Daily Rotation tab content. Source: FE §22 + RE "Daily Rotation — Backend
/// Behaviour". Recommends individual items via the engine's `rankDailyRotation`.
class DailyRotationTab extends ConsumerStatefulWidget {
  const DailyRotationTab({super.key, required this.onBuildOutfit});

  /// Pins [item] in the generator and switches to the Generator tab.
  final void Function(Item item) onBuildOutfit;

  @override
  ConsumerState<DailyRotationTab> createState() => _DailyRotationTabState();
}

class _DailyRotationTabState extends ConsumerState<DailyRotationTab> {
  static const _occasions = [
    (label: 'All', value: null),
    (label: 'Casual', value: Occasion.casual),
    (label: 'Work', value: Occasion.work),
    (label: 'Active', value: Occasion.active),
    (label: 'Relax', value: Occasion.relax),
  ];
  static const _layers = [
    (label: 'All', value: null),
    (label: 'Top', value: ItemCategory.top),
    (label: 'Bottom', value: ItemCategory.bottom),
    (label: 'Outerwear', value: ItemCategory.outerwear),
    (label: 'Shoes', value: ItemCategory.footwear),
  ];

  int _occasionIndex = 0;
  int _layerIndex = 0;

  /// Instant in-memory removal on Skip (snappy UX before the day-scoped
  /// [dailyRotationSkippedTodayProvider] re-fetches and takes over persistence).
  final Set<String> _sessionExcluded = {};

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wardrobeAsync = ref.watch(wardrobeProvider);
    final profile = ref.watch(profileProvider).asData?.value;
    // Day-scoped skips (DECISIONS G3): persist across restarts, reset at
    // midnight. Unioned with the in-memory set for instant removal on tap.
    final skippedToday =
        ref.watch(dailyRotationSkippedTodayProvider).asData?.value ??
            const <String>{};

    return wardrobeAsync.when(
      // Keep the list visible during a post-mutation refresh; the worn item
      // simply drops out once the new data settles (no spinner flash).
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load your wardrobe.\n$e',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary)),
        ),
      ),
      data: (items) {
        final now = DateTime.now();
        final ranked = rankDailyRotation(
          items,
          occasion: _occasions[_occasionIndex].value,
          mode: profile?.recommendationMode ?? RecommendationMode.balanced,
          now: now,
          preferredColours: profile?.preferredColours.toSet() ?? const {},
          dislikedColours: profile?.dislikedColours.toSet() ?? const {},
        );
        final layer = _layers[_layerIndex].value;
        final picks = ranked
            .where((s) =>
                !_sessionExcluded.contains(s.item.id) &&
                !skippedToday.contains(s.item.id))
            .where((s) => layer == null || s.item.category == layer)
            .take(5)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            const _FieldLabel('Occasion'),
            const SizedBox(height: 6),
            _ChipGroup(
              labels: [for (final o in _occasions) o.label],
              selectedIndex: _occasionIndex,
              onSelected: (i) => setState(() => _occasionIndex = i),
            ),
            const SizedBox(height: 12),
            const _FieldLabel('Layers'),
            const SizedBox(height: 6),
            _ChipGroup(
              labels: [for (final l in _layers) l.label],
              selectedIndex: _layerIndex,
              onSelected: (i) => setState(() => _layerIndex = i),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Top ${picks.length} Rotation Pick${picks.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: picks.isEmpty
                  ? _EmptyState(hasItems: items.isNotEmpty)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: picks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => DailyRotationCard(
                        scored: picks[i],
                        now: now,
                        onTap: () => context.push(Routes.itemDetail,
                            extra: picks[i].item),
                        onWear: () => _wear(picks[i]),
                        onSkip: () => _skip(picks[i]),
                        onBuildOutfit: () =>
                            widget.onBuildOutfit(picks[i].item),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _wear(ItemScore scored) async {
    final ok = await showLogWearSheet(context, scored.item.name);
    if (!ok) return;
    await ref.read(wardrobeProvider.notifier).logWorn(
          scored.item,
          source: ItemEventSource.dailyRotation,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged a wear for ${scored.item.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _skip(ItemScore scored) async {
    final confirmed = await showConfirmSheet(
      context,
      icon: Icons.skip_next_outlined,
      title: 'Skip ${scored.item.name}?',
      message: 'It won\'t appear in today\'s rotation again.',
      confirmLabel: 'Skip',
      isDestructive: true,
    );
    if (!confirmed) return;
    await ref.read(wardrobeProvider.notifier).logSkipped(
          scored.item,
          source: ItemEventSource.dailyRotation,
        );
    if (!mounted) return;
    setState(() => _sessionExcluded.add(scored.item.id));
  }
}

/// Small uppercase section label above a chip row (FE §23 label style).
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: c.textTertiary,
        ),
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChipRow(
      labels: labels,
      selectedIndex: selectedIndex,
      onSelected: onSelected,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasItems});

  /// Whether the wardrobe has any items at all (vs just none matching filters).
  final bool hasItems;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checkroom_outlined, size: 44, color: c.textTertiary),
            const SizedBox(height: 12),
            Text(
              hasItems ? 'Nothing matches these filters' : 'Your wardrobe is empty',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasItems
                  ? 'Try a different occasion or layer.'
                  : 'Add a few items to get rotation picks.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
