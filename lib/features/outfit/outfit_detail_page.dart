import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../data/models/item.dart';
import '../../engine/daily/daily_rotation_display.dart';
import '../../engine/outfit/generator_session.dart';
import '../../engine/outfit/outfit.dart';
import '../../engine/outfit/outfit_explanation.dart';
import '../../providers/outfit_generator_provider.dart';
import '../../providers/profile_providers.dart';
import '../../providers/wardrobe_providers.dart';
import '../../routing/app_router.dart';

/// Navigation payload for the Outfit Detail screen.
class OutfitDetailArgs {
  const OutfitDetailArgs({
    required this.scored,
    required this.occasion,
    required this.optionNumber,
  });

  final ScoredOutfit scored;
  final Occasion occasion;
  final int optionNumber;
}

/// Outfit Detail (FE §24 + agreed mock). Renders `buildExplanationForOutfit`
/// (re-running scoreItem per item) for Why Suggested + Rule Breakdown. Skip Item
/// / Skip Outfit drive the generator's cascade; Log Outfit writes the outfit log.
class OutfitDetailPage extends ConsumerWidget {
  const OutfitDetailPage({super.key, required this.args});

  final OutfitDetailArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final scored = args.scored;
    final outfit = scored.outfit;
    final wardrobe = ref.watch(wardrobeProvider).asData?.value ?? const [];
    final profile = ref.watch(profileProvider).asData?.value;
    final pin = ref.watch(outfitGeneratorProvider).pinnedItem;

    final exp = buildExplanationForOutfit(
      outfit: outfit,
      wardrobe: wardrobe,
      mode: profile?.recommendationMode ?? RecommendationMode.balanced,
      preferredColours: profile?.preferredColours.toSet() ?? const {},
      dislikedColours: profile?.dislikedColours.toSet() ?? const {},
      formality: scored.formality,
      colourScore: scored.colourScore,
      displayScore: scored.displayScore,
      occasion: args.occasion,
      pinnedItem: pin,
      now: DateTime.now(),
    );
    final summary =
        pin != null ? 'Built around your selected item.' : exp.scoreMessage;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: c.textPrimary,
        title: Text('Outfit Detail',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          _HeaderCard(
            optionNumber: args.optionNumber,
            occasion: args.occasion,
            score: scored.displayScore,
            itemCount: outfit.items.length,
            summary: summary,
          ),
          const SizedBox(height: 16),
          _ItemsCard(outfit: outfit, onSkipItem: (i) => _skipItem(context, ref, i)),
          const SizedBox(height: 16),
          _WhyCard(reasons: exp.whyReasons),
          const SizedBox(height: 16),
          _RuleBreakdownCard(rows: exp.ruleBreakdown),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        onSkipOutfit: () => _skipOutfit(context, ref, outfit),
        onLogOutfit: () => _logOutfit(context, ref, outfit),
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _skipItem(BuildContext context, WidgetRef ref, Item item) async {
    final ok = await showConfirmSheet(
      context,
      icon: Icons.skip_next_outlined,
      title: 'Skip this item?',
      message: "It'll be replaced here and suggested less often.",
      confirmLabel: 'Skip Item',
      isDestructive: true,
    );
    if (!ok) return;
    await ref.read(outfitGeneratorProvider.notifier).skip([item]);
    if (context.mounted) context.pop();
  }

  Future<void> _skipOutfit(
      BuildContext context, WidgetRef ref, Outfit outfit) async {
    final ok = await showConfirmSheet(
      context,
      icon: Icons.skip_next_outlined,
      title: 'Skip this outfit?',
      message: 'Every item will be replaced where possible and suggested less often.',
      confirmLabel: 'Skip Outfit',
      isDestructive: true,
    );
    if (!ok) return;
    await ref.read(outfitGeneratorProvider.notifier).skip(outfit.items);
    if (context.mounted) context.pop();
  }

  Future<void> _logOutfit(
      BuildContext context, WidgetRef ref, Outfit outfit) async {
    final ok = await showConfirmSheet(
      context,
      icon: Icons.check_circle_outline,
      title: 'Log this outfit?',
      message: "All items will be marked worn today, so they won't appear in today's rotation.",
      confirmLabel: 'Log Outfit',
    );
    if (!ok) return;
    final pieces = [
      for (final slot in outfit.filledSlots)
        (item: outfit.itemAt(slot)!, layer: _layerOf(slot)),
    ];
    await ref.read(wardrobeProvider.notifier).logOutfitWorn(
          pieces: pieces,
          occasion: args.occasion,
          outfitScore: args.scored.score,
        );
    if (!context.mounted) return;
    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Outfit logged'), duration: Duration(seconds: 2)),
    );
  }
}

LayerType _layerOf(OutfitSlot slot) => switch (slot) {
      OutfitSlot.top => LayerType.top,
      OutfitSlot.bottom => LayerType.bottom,
      OutfitSlot.outerwear => LayerType.outerwear,
      OutfitSlot.shoes => LayerType.shoes,
    };

String _layerLabel(OutfitSlot slot) => switch (slot) {
      OutfitSlot.top => 'Top',
      OutfitSlot.bottom => 'Bottom',
      OutfitSlot.outerwear => 'Outerwear',
      OutfitSlot.shoes => 'Shoes',
    };

// ── Sections ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.optionNumber,
    required this.occasion,
    required this.score,
    required this.itemCount,
    required this.summary,
  });

  final int optionNumber;
  final Occasion occasion;
  final int score;
  final int itemCount;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outfit Option $optionNumber',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary)),
                    const SizedBox(height: 6),
                    _OccasionPill(label: _occLabel(occasion)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ScorePill(score: score),
            ],
          ),
          const SizedBox(height: 10),
          Text('$itemCount items',
              style: TextStyle(fontSize: 12, color: c.textTertiary)),
          const SizedBox(height: 8),
          Text(summary,
              style: TextStyle(
                  fontSize: 13, height: 1.35, color: c.textSecondary)),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.outfit, required this.onSkipItem});

  final Outfit outfit;
  final void Function(Item) onSkipItem;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final slots = outfit.filledSlots;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Items in This Outfit',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          const SizedBox(height: 8),
          for (int i = 0; i < slots.length; i++) ...[
            if (i > 0) Divider(color: c.border, height: 1, thickness: 0.5),
            _ItemRow(
              item: outfit.itemAt(slots[i])!,
              layerLabel: _layerLabel(slots[i]),
              onSkip: () => onSkipItem(outfit.itemAt(slots[i])!),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends ConsumerWidget {
  const _ItemRow({
    required this.item,
    required this.layerLabel,
    required this.onSkip,
  });

  final Item item;
  final String layerLabel;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final imageUrl =
        ref.watch(itemImageUrlProvider(item.imagePath)).asData?.value;
    // Whole row → Item Detail (incl. the chevron). The skip icon is a nested
    // tap target that consumes its own taps, so it won't navigate.
    return GestureDetector(
      onTap: () => context.push(Routes.itemDetail, extra: item),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 48,
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
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(layerLabel,
                      style: TextStyle(fontSize: 11, color: c.textTertiary)),
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary)),
                  const SizedBox(height: 1),
                  Text(lastWornLabel(item, now: DateTime.now()),
                      style: TextStyle(fontSize: 11, color: c.textTertiary)),
                ],
              ),
            ),
            // Skip icon — separate tap target (consumes its own taps).
            GestureDetector(
              onTap: onSkip,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.skip_next_outlined,
                    size: 20, color: c.textTertiary),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.chevron),
          ],
        ),
      ),
    );
  }
}

class _WhyCard extends StatelessWidget {
  const _WhyCard({required this.reasons});
  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: c.primary),
              const SizedBox(width: 6),
              Text('Why Suggested',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          for (final reason in reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: c.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(reason,
                        style:
                            TextStyle(fontSize: 13, color: c.textPrimary)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RuleBreakdownCard extends StatelessWidget {
  const _RuleBreakdownCard({required this.rows});
  final List<RuleRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rule Breakdown',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          const SizedBox(height: 4),
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(color: c.border, height: 1, thickness: 0.5),
            _RuleRowTile(row: rows[i], isLast: i == rows.length - 1),
          ],
        ],
      ),
    );
  }
}

class _RuleRowTile extends StatelessWidget {
  const _RuleRowTile({required this.row, this.isLast = false});
  final RuleRow row;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = _badgeColours(row.badge);
    return Padding(
      // Last row drops its bottom padding so the card's own padding provides
      // the gap (consistent with the other rows' spacing).
      padding: EdgeInsets.only(top: 12, bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_friendlyName(row.name),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary)),
                const SizedBox(height: 2),
                Text(row.description,
                    style: TextStyle(fontSize: 11, color: c.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
            child: Text(row.badge,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
          ),
        ],
      ),
    );
  }

  /// Friendly display names for the engine's rule rows (DECISIONS — confirmed).
  static String _friendlyName(String engineName) => switch (engineName) {
        'Temporal Decay' => 'Rotation Priority',
        'Skip Penalty' => 'Skip Feedback',
        _ => engineName, // Wear Balance / Formality Match / Colour Compatibility
      };

  static (Color, Color) _badgeColours(String badge) {
    const good = {
      'High Rotation',
      'Clear',
      'Balanced',
      'Matched',
      'Strong',
      'Compatible'
    };
    const warn = {
      'Medium Rotation',
      'Minor Skips',
      'Moderate',
      'Loose',
      'Weak'
    };
    if (good.contains(badge)) {
      return (AppColors.primaryLight, AppColors.darkPrimaryText);
    }
    if (warn.contains(badge)) {
      return (AppColors.badgeNeverWornBg, AppColors.badgeNeverWornText);
    }
    return (AppColors.badgeWornOutBg, AppColors.badgeWornOutText);
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onSkipOutfit, required this.onLogOutfit});

  final VoidCallback onSkipOutfit;
  final VoidCallback onLogOutfit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: onSkipOutfit,
                    icon: const Icon(Icons.skip_next_outlined, size: 18),
                    label: const Text('Skip Outfit',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textPrimary,
                      backgroundColor: c.surface,
                      side: BorderSide(color: c.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onLogOutfit,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Log Outfit',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = AppColors.scoreBandColours(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('SCORE',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: fg)),
          Text('$score',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

class _OccasionPill extends StatelessWidget {
  const _OccasionPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: c.onPrimaryLight)),
    );
  }
}

String _occLabel(Occasion o) => switch (o) {
      Occasion.casual => 'Casual',
      Occasion.work => 'Work',
      Occasion.active => 'Active',
      Occasion.relax => 'Relax',
    };
