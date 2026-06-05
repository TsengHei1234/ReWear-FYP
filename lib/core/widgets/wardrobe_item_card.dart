import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/enums.dart';
import '../theme/app_color_scheme.dart';
import '../theme/app_colors.dart';
import '../utils/date_x.dart';
import '../../data/models/item.dart';
import '../../engine/badges/badge_engine.dart';
import 'badge_chip.dart';

/// 2-column wardrobe grid card. Source: FE §17 + agreed mock.
///
/// Layout:
///   ┌──────────────────────┐
///   │  photo (1:1)         │  ← fav star TL, last-worn pill TR,
///   │           [badge +N] │    primary badge BL, status overlay
///   ├──────────────────────┤
///   │  name                │  ← info area (surface bg)
///   │  Category · Type  [✓][✦] ← quick actions BR
///   └──────────────────────┘
///
/// [imageUrl] is a pre-resolved signed URL (null → placeholder).
/// [allItems] is required for the Most Worn badge calculation.
/// [onLogWear] / [onBuildOutfit] power the two quick-action buttons (null hides
/// them — disabled automatically for non-IN_WARDROBE items).
class WardrobeItemCard extends StatelessWidget {
  const WardrobeItemCard({
    super.key,
    required this.item,
    required this.allItems,
    required this.onTap,
    this.imageUrl,
    this.onLogWear,
    this.onBuildOutfit,
  });

  final Item item;
  final List<Item> allItems;
  final VoidCallback onTap;
  final String? imageUrl;
  final VoidCallback? onLogWear;
  final VoidCallback? onBuildOutfit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final badges = computeAllBadges(item, allItems);
    final primary = badges.isEmpty ? null : badges.first;
    final extraCount = badges.isEmpty ? 0 : badges.length - 1;
    final isAvailable = item.status == ItemStatus.inWardrobe;
    final lastWorn = lastWornLabel(item.lastWornDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo area (1:1 square) ─────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPhoto(c),

                    // Status grey overlay (non-active items)
                    if (!isAvailable)
                      ColoredBox(
                        color: Colors.black.withValues(alpha: 0.45),
                      ),

                    // Status label (centre) for non-active items
                    if (!isAvailable)
                      Center(
                        child: Text(
                          _statusLabel(item.status),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),

                    // Favourite star — top-left
                    if (item.isFavorite)
                      const Positioned(
                        top: 8,
                        left: 8,
                        child: Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: AppColors.favouriteStar,
                        ),
                      ),

                    // Last worn pill — top-right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _LastWornPill(label: lastWorn),
                    ),

                    // Primary badge (+N) — bottom-left on photo
                    if (primary != null)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: BadgeChip(badge: primary, extraCount: extraCount),
                      ),
                  ],
                ),
              ),
            ),

            // ── Info area ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
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
                  const SizedBox(height: 2),
                  // Category · Type
                  Text(
                    '${_categoryLabel(item.category)} · ${_typeLabel(item.type)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: c.textTertiary,
                    ),
                  ),
                  // Quick-action buttons — below, right-aligned
                  if (onLogWear != null || onBuildOutfit != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onBuildOutfit != null) ...[
                          _QuickActionButton(
                            icon: Icons.auto_fix_high_outlined,
                            enabled: isAvailable,
                            onTap: onBuildOutfit!,
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (onLogWear != null)
                          _QuickActionButton(
                            icon: Icons.check_rounded,
                            enabled: isAvailable,
                            onTap: onLogWear!,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(ItemStatus s) => switch (s) {
        ItemStatus.laundry => 'In Laundry',
        ItemStatus.lent => 'Lent Out',
        ItemStatus.stored => 'Stored',
        _ => '',
      };

  Widget _buildPhoto(AppColorsTheme c) {
    if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        // Versioned by updatedAt: same key on URL regen (cache hit, no egress);
        // new key on photo edit (cache miss, downloads new image). RULE: every
        // CachedNetworkImage consuming itemImageUrlProvider must follow this pattern.
        cacheKey: item.imagePath != null
            ? '${item.imagePath}_v${item.updatedAt.millisecondsSinceEpoch}'
            : null,
        fit: BoxFit.cover,
        placeholder: (_, _) => _photoPlaceholder(c),
        errorWidget: (_, _, _) => _photoPlaceholder(c),
      );
    }
    return _photoPlaceholder(c);
  }

  Widget _photoPlaceholder(AppColorsTheme c) => Container(
        color: c.surface2,
        child: Center(
          child: Icon(
            Icons.checkroom_outlined,
            size: 36,
            color: c.textTertiary,
          ),
        ),
      );

  String _categoryLabel(ItemCategory c) => switch (c) {
        ItemCategory.top => 'Top',
        ItemCategory.bottom => 'Bottom',
        ItemCategory.outerwear => 'Outerwear',
        ItemCategory.footwear => 'Shoes',
        ItemCategory.others => 'Others',
      };

  // Converts stored type value to a readable label by capitalising words.
  String _typeLabel(String stored) => stored
      .split('_')
      .map((w) => w.isEmpty
          ? ''
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}

/// Small icon-only quick-action button shown at the bottom-right of a card.
class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? c.primaryLight : c.surface2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? c.primary : c.textTertiary,
        ),
      ),
    );
  }
}

class _LastWornPill extends StatelessWidget {
  const _LastWornPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
