import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/constants/item_type_dictionary.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/outlined_button_widget.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/item.dart';
import '../../engine/outfit/generator_session.dart';
import '../../engine/outfit/outfit_explanation.dart';
import '../../providers/outfit_generator_provider.dart';
import '../../providers/profile_providers.dart';
import '../../providers/wardrobe_providers.dart';
import '../../routing/app_router.dart';
import 'outfit_detail_page.dart';
import 'widgets/type_filter_sheet.dart';

/// Outfit Generator tab content. Source: FE §23 + RE generator behaviour.
/// Session lifecycle per DECISIONS.md G1 (pinned protects the session).
class OutfitGeneratorTab extends ConsumerStatefulWidget {
  const OutfitGeneratorTab({super.key});

  @override
  ConsumerState<OutfitGeneratorTab> createState() => _OutfitGeneratorTabState();
}

class _OutfitGeneratorTabState extends ConsumerState<OutfitGeneratorTab> {
  static const _occasions = [
    Occasion.casual,
    Occasion.work,
    Occasion.active,
    Occasion.relax,
  ];

  @override
  void initState() {
    super.initState();
    // Default occasion = Casual (FE §23, no "All"). Pin constraints (occasion
    // limited to the pin + its layer forced on) are applied by the provider in
    // setPinnedItem (DECISIONS G1), so nothing pin-specific is needed here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(outfitGeneratorProvider).occasion == null) {
        ref.read(outfitGeneratorProvider.notifier).setOccasion(Occasion.casual);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(outfitGeneratorProvider);
    final wardrobeAsync = ref.watch(wardrobeProvider);

    if (wardrobeAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final pin = state.pinnedItem;
    // Chips reflect the SELECTED occasion (staged); the result cards + Outfit
    // Detail show the occasion the cards were GENERATED with (DECISIONS G1) so a
    // staged change doesn't relabel them until next generation.
    final selectedOccasion = state.occasion ?? Occasion.casual;
    final displayedOccasion = state.generatedOccasion ?? selectedOccasion;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        // ── OCCASION ────────────────────────────────────────────────
        const _SectionLabel('Occasion'),
        const SizedBox(height: 6),
        _ChipScroll(children: [
          for (final o in _occasions)
            _GenChip(
              label: _occLabel(o),
              selected: selectedOccasion == o,
              enabled: pin == null || pin.occasionTags.contains(o),
              onTap: () => _changeFilter(() =>
                  ref.read(outfitGeneratorProvider.notifier).setOccasion(o)),
            ),
        ]),
        const SizedBox(height: 12),

        // ── LAYERS ──────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel('Layers'),
            _FilterButton(
              active: state.selectedTypes.isNotEmpty,
              onTap: _openTypeFilterSheet,
            ),
          ],
        ),
        const SizedBox(height: 6),
        _ChipScroll(children: [
          const _GenChip(label: 'Top', selected: true, locked: true),
          const _GenChip(label: 'Bottom', selected: true, locked: true),
          _GenChip(
            label: 'Outerwear',
            selected: state.requireOuterwear,
            locked: pin?.category == ItemCategory.outerwear,
            enabled: pin?.category != ItemCategory.outerwear,
            onTap: () => _changeFilter(() => ref
                .read(outfitGeneratorProvider.notifier)
                .setRequireOuterwear(!state.requireOuterwear)),
          ),
          _GenChip(
            label: 'Shoes',
            selected: state.requireShoes,
            locked: pin?.category == ItemCategory.footwear,
            enabled: pin?.category != ItemCategory.footwear,
            onTap: () => _changeFilter(() => ref
                .read(outfitGeneratorProvider.notifier)
                .setRequireShoes(!state.requireShoes)),
          ),
        ]),
        if (state.selectedTypes.isNotEmpty) ...[
          const SizedBox(height: 6),
          _ActiveFilterSummary(selectedTypes: state.selectedTypes),
        ],
        const SizedBox(height: 14),

        // ── Pinned strip ────────────────────────────────────────────
        if (pin != null) ...[
          _PinnedStrip(item: pin, onClear: _clearPin),
          const SizedBox(height: 14),
        ],

        // ── Generate / Start Over ───────────────────────────────────
        if (!state.hasGenerated)
          PrimaryButton(
            label: 'Generate Outfit',
            onPressed: state.isGenerating
                ? null
                : () => ref.read(outfitGeneratorProvider.notifier).generate(),
          )
        else
          OutlinedButtonWidget(
            label: 'Start Over',
            onPressed: state.isGenerating ? null : _startOver,
          ),

        // ── Empty state hint (before first generation / after reset) ─
        if (!state.hasGenerated) ...[
          const SizedBox(height: 32),
          const _EmptyGeneratorHint(),
        ],

        // ── Results / failure ───────────────────────────────────────
        if (state.hasGenerated && state.failureMessage != null) ...[
          const SizedBox(height: 16),
          _FailureCard(message: state.failureMessage!),
        ],
        if (state.hasGenerated && state.outfits.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _DividerLabel('Generated Outfits'),
          const SizedBox(height: 12),
          for (int i = 0; i < state.outfits.length; i++) ...[
            _ResultCard(
              scored: state.outfits[i],
              optionNumber: i + 1,
              occasion: displayedOccasion,
              onOpenWhy: (exp) => _showQuickWhy(context, exp),
              onTap: () => context.push(
                Routes.outfitDetail,
                extra: OutfitDetailArgs(
                  scored: state.outfits[i],
                  occasion: displayedOccasion,
                  optionNumber: i + 1,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  /// Filter-change orchestration. Active session (hasGenerated=true, including
  /// the "no more combinations" state) → warn before applying any filter change;
  /// on confirm apply the new filter and clear the session (button returns to
  /// "Generate Outfit"). Cancel → keep old cards + old filter. Else apply
  /// directly. Blocked while skip replacement is loading.
  Future<void> _changeFilter(VoidCallback apply) async {
    final state = ref.read(outfitGeneratorProvider);
    if (state.isGenerating) return;
    if (state.hasGenerated) {
      final ok = await showConfirmSheet(
        context,
        icon: Icons.filter_list,
        title: 'Change filters?',
        message:
            'This will clear your current generated outfits and skipped items for this session.',
        confirmLabel: 'Change Filters',
      );
      if (!ok) return;
      apply();
      ref.read(outfitGeneratorProvider.notifier).clearGenerated();
    } else {
      apply(); // nothing generated yet — apply directly
    }
  }

  /// Remove the pin. Confirms first when an active session exists (hasGenerated
  /// = true, covers both cards visible and "no more combinations" states).
  /// Blocked while skip replacement is loading.
  Future<void> _clearPin() async {
    final state = ref.read(outfitGeneratorProvider);
    if (state.isGenerating) return;
    if (state.hasGenerated) {
      final ok = await showConfirmSheet(
        context,
        icon: Icons.close,
        title: 'Remove pinned item?',
        message:
            'This will clear your current generated outfits and start a new generation setup.',
        confirmLabel: 'Remove Pin',
        isDestructive: true,
      );
      if (!ok) return;
    }
    ref.read(outfitGeneratorProvider.notifier).clearPin();
  }

  /// Start Over — clears the active session and skipped items for this session
  /// (does NOT touch database skip_count or item_events). Blocked while loading.
  Future<void> _startOver() async {
    if (!mounted) return;
    final state = ref.read(outfitGeneratorProvider);
    if (state.isGenerating) return;
    final ok = await showConfirmSheet(
      context,
      icon: Icons.refresh,
      title: 'Start over?',
      message:
          'This will clear your current generated outfits and skipped items for this session.',
      confirmLabel: 'Start Over',
    );
    if (!ok || !mounted) return;
    ref.read(outfitGeneratorProvider.notifier).clearGenerated();
  }

  Future<void> _openTypeFilterSheet() async {
    final state = ref.read(outfitGeneratorProvider);
    final wardrobe = ref.read(wardrobeProvider).asData?.value ?? const [];
    final result = await showModalBottomSheet<Map<ItemCategory, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TypeFilterSheet(
        selectedTypes: state.selectedTypes,
        requireOuterwear: state.requireOuterwear,
        requireShoes: state.requireShoes,
        pinnedItem: state.pinnedItem,
        occasion: state.occasion,
        wardrobe: wardrobe,
      ),
    );
    if (result == null || !mounted) return;
    await _changeFilter(
      () => ref
          .read(outfitGeneratorProvider.notifier)
          .setSelectedTypes(result),
    );
  }

  void _showQuickWhy(BuildContext context, OutfitExplanation exp) {
    final c = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(sheetCtx).viewPadding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Why this outfit?',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary)),
            const SizedBox(height: 12),
            for (final reason in exp.whyReasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check, size: 16, color: c.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(reason,
                          style: TextStyle(
                              fontSize: 13, color: c.textPrimary)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _occLabel(Occasion o) => switch (o) {
      Occasion.casual => 'Casual',
      Occasion.work => 'Work',
      Occasion.active => 'Active',
      Occasion.relax => 'Relax',
    };

// ── Small widgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: c.textTertiary,
      ),
    );
  }
}

class _ChipScroll extends StatelessWidget {
  const _ChipScroll({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _GenChip extends StatelessWidget {
  const _GenChip({
    required this.label,
    required this.selected,
    this.enabled = true,
    this.locked = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = selected
        ? Colors.white
        : enabled
            ? c.textSecondary
            : c.textTertiary;
    return Opacity(
      opacity: enabled || selected ? 1 : 0.5,
      child: GestureDetector(
        onTap: (enabled && !locked) ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? c.primary : c.surface,
            border: Border.all(
                color: selected ? c.primary : c.border, width: 0.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (locked) ...[
                Icon(Icons.lock, size: 9, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinnedStrip extends ConsumerWidget {
  const _PinnedStrip({required this.item, required this.onClear});
  final Item item;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final imageUrl =
        ref.watch(itemImageUrlProvider(item.imagePath)).asData?.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.primaryLight,
        border: Border.all(color: c.primary.withValues(alpha: 0.35), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.push_pin, size: 20, color: c.primary),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 36,
              height: 36,
              child: imageUrl == null
                  ? Container(
                      color: c.surface2,
                      child: Icon(Icons.checkroom_outlined,
                          size: 18, color: c.textTertiary))
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      cacheKey: item.imagePath != null
                          ? '${item.imagePath}_v${item.updatedAt.millisecondsSinceEpoch}'
                          : null,
                      fit: BoxFit.cover,
                      memCacheWidth: 100,
                      memCacheHeight: 100,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary)),
          ),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: Icon(Icons.close, size: 16, color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(child: Divider(color: c.border, thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(text,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary)),
        ),
        Expanded(child: Divider(color: c.border, thickness: 0.5)),
      ],
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 28, color: c.textTertiary),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
        ],
      ),
    );
  }
}

/// One generated-outfit result card (FE §23). Computes its explanation from the
/// ScoredOutfit (which carries formality/colourScore/displayScore) + wardrobe.
class _ResultCard extends ConsumerWidget {
  const _ResultCard({
    required this.scored,
    required this.optionNumber,
    required this.occasion,
    required this.onOpenWhy,
    required this.onTap,
  });

  final ScoredOutfit scored;
  final int optionNumber;
  final Occasion occasion;
  final void Function(OutfitExplanation) onOpenWhy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final items = scored.outfit.items;
    final wardrobe = ref.watch(wardrobeProvider).asData?.value ?? const [];
    final profile = ref.watch(profileProvider).asData?.value;
    final pin = ref.watch(outfitGeneratorProvider).pinnedItem;

    final exp = buildExplanationForOutfit(
      outfit: scored.outfit,
      wardrobe: wardrobe,
      mode: profile?.recommendationMode ?? RecommendationMode.balanced,
      preferredColours: profile?.preferredColours.toSet() ?? const {},
      dislikedColours: profile?.dislikedColours.toSet() ?? const {},
      formality: scored.formality,
      colourScore: scored.colourScore,
      displayScore: scored.displayScore,
      occasion: occasion,
      pinnedItem: pin,
      now: DateTime.now(),
    );
    final highlights = exp.highlights;
    // highlights always has 3 FRS entries (4 when New Item leads).
    const badFrsLabels = {'Low Rotation', 'Penalty', 'Overused'};
    final primary = highlights.isEmpty ? null : highlights.first;
    final extra = highlights.length - 1;
    final isBadFrs = primary != null && badFrsLabels.contains(primary);
    final displayPrimary = isBadFrs ? '⚠ $primary' : primary;
    final label = displayPrimary == null
        ? _occLabel(occasion)
        : '${_occLabel(occasion)} · $displayPrimary';
    final isLoose = scored.formality.loose;
    final isWeakColour = scored.colourScore < 0.60;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(14),
        // "?" (top) and chevron (bottom) share the same right edge so they read
        // as one balanced right-hand column; content reserves a right gutter.
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 22,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _ScorePill(score: scored.displayScore),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Outfit Option $optionNumber',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary)),
                  const SizedBox(height: 4),
                  // Line 1: Occasion · primary FRS [+N]
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      if (extra > 0) ...[
                        const SizedBox(width: 6),
                        _ExtraBadge(count: extra),
                      ],
                    ],
                  ),
                  // Line 2 (amber): ⚠ non-FRS warnings [+1] — own row so line 1 never truncates
                  if (isLoose || isWeakColour) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '⚠ ${isLoose ? 'Loose formality' : 'Weak colour match'}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.utilisationAmber,
                          ),
                        ),
                        if (isLoose && isWeakColour) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '+1',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.utilisationAmber,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  // Item thumbnails (responsive — share the row width equally).
                  Row(
                    children: [
                      for (int i = 0; i < items.length; i++) ...[
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _Thumb(item: items[i]),
                          ),
                        ),
                        if (i < items.length - 1) const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // "?" — top-right.
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => onOpenWhy(exp),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: c.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.border, width: 0.5),
                  ),
                  alignment: Alignment.center,
                  child: Text('?',
                      style: TextStyle(fontSize: 12, color: c.textTertiary)),
                ),
              ),
            ),
            // Chevron — vertically centered on the right edge (same edge as "?").
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: Center(
                child:
                    Icon(Icons.chevron_right, size: 20, color: c.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Score N" pill, tinted by score band (green/amber/red — DECISIONS/UI).
class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppColors.scoreBandColours(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('Score $score',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

/// Small "+N" pill beside the highlight label.
class _ExtraBadge extends StatelessWidget {
  const _ExtraBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('+$count',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c.onPrimaryLight)),
    );
  }
}

class _EmptyGeneratorHint extends StatelessWidget {
  const _EmptyGeneratorHint();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Icon(Icons.checkroom_outlined, size: 48, color: c.textTertiary),
        const SizedBox(height: 12),
        Text(
          'Ready to generate',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Set your occasion and layers above,\nthen tap Generate to discover outfit combinations.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: c.textTertiary),
        ),
      ],
    );
  }
}

/// Filter icon + "Filter" label shown to the right of the LAYERS section header.
/// Turns primary-green when at least one type filter is active.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = active ? c.primary : c.textTertiary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filter',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.tune, size: 14, color: color),
        ],
      ),
    );
  }
}

/// One-line summary of active type filters shown below the layer chips.
/// Categories appear in a fixed order: Top → Bottom → Outerwear → Shoes.
class _ActiveFilterSummary extends StatelessWidget {
  const _ActiveFilterSummary({required this.selectedTypes});
  final Map<ItemCategory, String> selectedTypes;

  static const _order = [
    ItemCategory.top,
    ItemCategory.bottom,
    ItemCategory.outerwear,
    ItemCategory.footwear,
  ];

  String _catLabel(ItemCategory cat) => switch (cat) {
        ItemCategory.top => 'Top',
        ItemCategory.bottom => 'Bottom',
        ItemCategory.outerwear => 'Outerwear',
        ItemCategory.footwear => 'Shoes',
        ItemCategory.others => 'Other',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final parts = [
      for (final cat in _order)
        if (selectedTypes.containsKey(cat))
          '${_catLabel(cat)}: ${ItemTypeDictionary.byStoredValue(selectedTypes[cat]!)?.displayLabel ?? selectedTypes[cat]!}',
    ];
    return Row(
      children: [
        Icon(Icons.filter_list, size: 11, color: c.primary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            parts.join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: c.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Thumb extends ConsumerWidget {
  const _Thumb({required this.item});
  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final imageUrl =
        ref.watch(itemImageUrlProvider(item.imagePath)).asData?.value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageUrl == null
          ? Container(
              color: c.surface2,
              child: Icon(Icons.checkroom_outlined,
                  size: 22, color: c.textTertiary))
          : CachedNetworkImage(
              imageUrl: imageUrl,
              cacheKey: item.imagePath != null
                  ? '${item.imagePath}_v${item.updatedAt.millisecondsSinceEpoch}'
                  : null,
              fit: BoxFit.cover,
              memCacheWidth: 500,
              memCacheHeight: 500,
            ),
    );
  }
}
