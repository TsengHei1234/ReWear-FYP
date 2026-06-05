import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../engine/daily/daily_rotation_display.dart';
import '../../../engine/scoring/frs.dart';
import '../../../providers/wardrobe_providers.dart';

/// A single Daily Rotation recommendation card. Source: FE §22 + agreed mock
/// (layout LOCKED). Pure display of an already-scored [ItemScore]; all labels
/// come from the engine's `daily_rotation_display.dart`.
class DailyRotationCard extends ConsumerWidget {
  const DailyRotationCard({
    super.key,
    required this.scored,
    required this.now,
    required this.onTap,
    required this.onWear,
    required this.onSkip,
    required this.onBuildOutfit,
  });

  final ItemScore scored;
  final DateTime now;

  /// Tapping the card (anywhere except the buttons) opens Item Detail.
  final VoidCallback onTap;
  final VoidCallback onWear;
  final VoidCallback onSkip;
  final VoidCallback onBuildOutfit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final item = scored.item;
    final imageUrl = ref.watch(itemImageUrlProvider(item.imagePath)).asData?.value;
    final priority = priorityLabel(nibs: scored.nibs, tds: scored.tds);
    // Wear-balance line: "{status} · {n} wears" (e.g. "Rarely Worn · 3 wears").
    // Status text comes from the engine; only its capitalisation is display.
    final status = _titleCase(wearStatusLabel(item, now: now));
    final wearBalance =
        item.wearCountUnknown ? status : '$status · ${wearCountLabel(item)}';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: photo + score | info ──────────────────────────────
          // Two tight, top-aligned columns. Left = image then score pill
          // (small fixed gap). Right = details, spaced so its height balances
          // the image+pill column and the wear line sits near the pill level.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: _Photo(
                      imageUrl: imageUrl,
                      cacheKey: item.imagePath != null
                          ? '${item.imagePath}_v${item.updatedAt.millisecondsSinceEpoch}'
                          : null,
                    ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _ScorePill(score: dailyRotationDisplayScore(scored.frs)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_categoryLabel(item.category)} · ${_typeLabel(item.type)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: c.textTertiary),
                    ),
                    const SizedBox(height: 7),
                    _PriorityBadge(label: priority),
                    const SizedBox(height: 7),
                    _IconLine(
                      icon: Icons.schedule,
                      label: lastWornLabel(item, now: now),
                    ),
                    const SizedBox(height: 5),
                    _IconLine(
                      icon: Icons.autorenew,
                      label: wearBalance,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Row 2: Wear / Skip, then Build Outfit ────────────────────
          Row(
            children: [
              Expanded(
                child: _OutlineAction(
                  icon: Icons.check,
                  label: 'Wear',
                  onTap: onWear,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OutlineAction(
                  icon: Icons.skip_next_outlined,
                  label: 'Skip',
                  onTap: onSkip,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _PrimaryAction(
            icon: Icons.auto_fix_high,
            label: 'Build Outfit',
            onTap: onBuildOutfit,
          ),
        ],
      ),
      ),
    );
  }

  String _categoryLabel(ItemCategory cat) => switch (cat) {
        ItemCategory.top => 'Top',
        ItemCategory.bottom => 'Bottom',
        ItemCategory.outerwear => 'Outerwear',
        ItemCategory.footwear => 'Shoes',
        ItemCategory.others => 'Others',
      };

  String _typeLabel(String stored) => stored
      .split('_')
      .map((w) => w.isEmpty
          ? ''
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}

class _Photo extends StatelessWidget {
  const _Photo({this.imageUrl, this.cacheKey});

  final String? imageUrl;
  /// Stable Supabase storage path used as the CachedNetworkImage cache key so
  /// the disk cache survives signed-URL regeneration (see RULE in
  /// wardrobe_item_card.dart). Pass item.imagePath from the parent widget.
  final String? cacheKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget placeholder() => Container(
          color: c.surface2,
          child: Icon(Icons.checkroom_outlined, size: 28, color: c.textTertiary),
        );
    if (imageUrl == null) return placeholder();
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      cacheKey: cacheKey,
      fit: BoxFit.cover,
      placeholder: (_, _) => placeholder(),
      errorWidget: (_, _, _) => placeholder(),
    );
  }
}

/// Score status label — light-green pill, dark-green text, ~image width.
class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 88,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: c.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        'Score $score',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: c.onPrimaryLight,
        ),
      ),
    );
  }
}

/// Title-cases each word for display (engine labels are sentence-case).
String _titleCase(String s) => s
    .split(' ')
    .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// Priority pill — colour driven by the engine label (FE §22 colours, brand-fixed).
class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _style(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, Color, IconData) _style(String label) => switch (label) {
        'High Rotation Priority' => (
            const Color(0xFFFEF2F2),
            AppColors.danger,
            Icons.local_fire_department,
          ),
        'Medium Rotation Priority' => (
            const Color(0xFFFFFBEB),
            AppColors.amberText,
            Icons.trending_up,
          ),
        'New Item' => (
            AppColors.badgeNewBg,
            AppColors.badgeNewText,
            Icons.auto_awesome,
          ),
        _ => (
            AppColors.badgeNeutralBg,
            AppColors.badgeNeutralText,
            Icons.remove,
          ),
      };
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 12, color: c.textTertiary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: c.textTertiary),
          ),
        ),
      ],
    );
  }
}

/// Compact (36h) outlined action used for Wear / Skip.
class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: c.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact (36h) primary action used for Build Outfit.
class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        width: double.infinity,
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
