import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/constants/item_type_dictionary.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_x.dart';
import '../../core/widgets/badge_chip.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/history_row.dart';
import '../../data/models/item.dart';
import '../../data/models/item_event.dart';
import '../../engine/badges/badge_engine.dart';
import '../../providers/wardrobe_providers.dart';
import '../../routing/app_router.dart';
import '../outfit/build_outfit_action.dart';

/// Full-screen item detail page. Source: FE §19 + agreed mock.
/// Item is passed via [GoRouter.extra]; the page also watches [wardrobeProvider]
/// so edits / wears reflect immediately without re-navigation.
class ItemDetailPage extends ConsumerWidget {
  const ItemDetailPage({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;

    final allItems = switch (ref.watch(wardrobeProvider)) {
      AsyncData(:final value) => value,
      _ => <Item>[],
    };
    final it = allItems.isEmpty
        ? item
        : allItems.firstWhere((i) => i.id == item.id, orElse: () => item);

    final imageAsync = it.imagePath != null
        ? ref.watch(itemImageUrlProvider(it.imagePath))
        : null;
    final imageUrl = switch (imageAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };

    final badges = computeAllBadges(it, allItems);
    final isDonationFlagged = badges.contains(BadgeType.donationReview);

    return Scaffold(
      backgroundColor: c.background,
      body: CustomScrollView(
        slivers: [
          // ── Photo header (1:1) with floating circle buttons ──────
          SliverToBoxAdapter(
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: _buildPhoto(c, imageUrl, it),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _circleButton(
                        icon: Icons.arrow_back,
                        iconColor: c.textPrimary,
                        bg: c.surface,
                        onTap: () => context.pop(),
                      ),
                      const Spacer(),
                      _circleButton(
                        icon: it.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        iconColor: it.isFavorite
                            ? AppColors.favouriteStar
                            : c.textSecondary,
                        bg: c.surface,
                        onTap: () => ref.read(wardrobeProvider.notifier).editItem(
                              item: it.copyWith(isFavorite: !it.isFavorite),
                            ),
                      ),
                      const SizedBox(width: 8),
                      _circleButton(
                        icon: Icons.edit_outlined,
                        iconColor: c.textPrimary,
                        bg: c.surface,
                        onTap: () =>
                            context.push(Routes.editItem, extra: it),
                      ),
                      const SizedBox(width: 8),
                      _circleButton(
                        icon: Icons.delete_outline,
                        iconColor: AppColors.danger,
                        bg: c.surface,
                        onTap: () => _confirmDelete(context, ref, it),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    it.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Category · Type · Colour
                  Text(
                    _categoryTypeColour(it),
                    style: TextStyle(fontSize: 13, color: c.textTertiary),
                  ),

                  // Occasion chips (read-only)
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: it.occasionTags
                        .map((o) => _readonlyChip(_occLabel(o), c))
                        .toList(),
                  ),

                  // Badges
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          badges.map((b) => BadgeChip(badge: b)).toList(),
                    ),
                  ],

                  // Stats row
                  const SizedBox(height: 16),
                  _buildStatsRow(it, c),

                  // Status + Condition
                  const SizedBox(height: 16),
                  _buildStatusConditionRow(it, c),

                  // Rule-Based Usage Summary
                  const SizedBox(height: 16),
                  _buildUsageSummaryCard(it, badges, c),

                  // Consider Donating — always available unless already gone
                  if (it.status != ItemStatus.donated &&
                      it.status != ItemStatus.deleted) ...[
                    const SizedBox(height: 12),
                    _buildConsiderDonating(context, c, flagged: isDonationFlagged),
                  ],

                  // Recent Wear History
                  const SizedBox(height: 16),
                  _buildWearHistoryCard(context, ref, it, c),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Sticky bottom buttons ──────────────────────────────────
      bottomNavigationBar: _buildBottomButtons(context, ref, it, c),
    );
  }

  // ── Photo ─────────────────────────────────────────────────────────────────

  Widget _buildPhoto(AppColorsTheme c, String? imageUrl, Item it) {
    if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        // Versioned by updatedAt: same key on URL regen (cache hit, no egress);
        // new key on photo edit (cache miss, downloads new image).
        cacheKey: it.imagePath != null
            ? '${it.imagePath}_v${it.updatedAt.millisecondsSinceEpoch}'
            : null,
        fit: BoxFit.cover,
        placeholder: (ctx, url) => Container(
          color: c.surface,
          child: Center(
            child:
                CircularProgressIndicator(color: c.primary, strokeWidth: 2),
          ),
        ),
        errorWidget: (ctx, url, err) => _photoPlaceholder(c, it),
      );
    }
    return _photoPlaceholder(c, it);
  }

  Widget _photoPlaceholder(AppColorsTheme c, Item it) => Container(
        color: c.surface2,
        child: Center(
          child: Icon(
            it.category == ItemCategory.footwear
                ? Icons.ice_skating_outlined
                : Icons.checkroom_outlined,
            size: 64,
            color: c.textTertiary,
          ),
        ),
      );

  Widget _circleButton({
    required IconData icon,
    required Color iconColor,
    required Color bg,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      );

  // ── Stats row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow(Item it, AppColorsTheme c) => Row(
        children: [
          _statTile(
            value: it.wearCountUnknown ? '~${it.wearCount}' : '${it.wearCount}',
            label: 'Wears',
            c: c,
          ),
          const SizedBox(width: 8),
          _statTile(
            value: _lastWornShort(it.lastWornDate),
            label: 'Last Worn',
            c: c,
          ),
          const SizedBox(width: 8),
          _statTile(value: '${it.skipCount}', label: 'Skipped', c: c),
        ],
      );

  Widget _statTile({
    required String value,
    required String label,
    required AppColorsTheme c,
  }) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(fontSize: 11, color: c.textTertiary)),
            ],
          ),
        ),
      );

  // ── Status & Condition ─────────────────────────────────────────────────────

  Widget _buildStatusConditionRow(Item it, AppColorsTheme c) {
    final available = it.status == ItemStatus.inWardrobe;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status pill — small status dot + label
        _pill(
          c: c,
          leading: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: available ? c.primary : c.textTertiary,
            ),
          ),
          label: _statusLabel(it.status),
        ),
        const SizedBox(width: 8),
        // Condition pill — check-circle icon + label
        _pill(
          c: c,
          leading: Icon(Icons.check_circle_outline,
              size: 14, color: c.textSecondary),
          label: 'Condition: ${conditionLabel(it.condition)}',
        ),
      ],
    );
  }

  Widget _pill({
    required Widget leading,
    required String label,
    required AppColorsTheme c,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary)),
          ],
        ),
      );

  // ── Rule-Based Usage Summary ────────────────────────────────────────────────

  Widget _buildUsageSummaryCard(
      Item it, List<BadgeType> badges, AppColorsTheme c) {
    final rotation = _rotationPriority(it, c);
    final wearBalance = badges.contains(BadgeType.overused)
        ? ('Overused', AppColors.danger, 'Used heavily for its age')
        : ('Good', c.primary, 'Healthy wear rate');
    final skipFeedback = badges.contains(BadgeType.skippedOften)
        ? ('High', AppColors.danger, 'Skipped more than worn')
        : ('Low', c.primary, 'Rarely skipped');
    final donation = badges.contains(BadgeType.donationReview)
        ? ('Under review', const Color(0xFFC2410C), 'Flagged for donation')
        : ('Not needed', c.primary, 'No donation concerns');

    return _card(
      c,
      label: 'Rule-Based Usage Summary',
      child: Column(
        children: [
          _usageRow('Rotation Priority', rotation.$1, rotation.$2, rotation.$3, c),
          _usageDivider(c),
          _usageRow('Wear Balance', wearBalance.$1, wearBalance.$2,
              wearBalance.$3, c),
          _usageDivider(c),
          _usageRow('Skip Feedback', skipFeedback.$1, skipFeedback.$2,
              skipFeedback.$3, c),
          _usageDivider(c),
          _usageRow('Donation Review', donation.$1, donation.$2, donation.$3, c,
              last: true),
        ],
      ),
    );
  }

  Widget _usageRow(
    String label,
    String value,
    Color valueColor,
    String subtitle,
    AppColorsTheme c, {
    bool last = false,
  }) =>
      Padding(
        padding: EdgeInsets.only(top: 11, bottom: last ? 0 : 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 11, color: c.textTertiary)),
                ],
              ),
            ),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: valueColor)),
          ],
        ),
      );

  Widget _usageDivider(AppColorsTheme c) =>
      Divider(height: 1, thickness: 0.5, color: c.surface2);

  /// Rotation priority from days since worn (provisional until Phase 5 rotation
  /// window lands). Returns (value, colour, subtitle).
  (String, Color, String) _rotationPriority(Item it, AppColorsTheme c) {
    if (it.wearCount == 0 && it.lastWornDate == null) {
      final added = daysSince(it.dateAdded);
      if (added > 14) return ('High', AppColors.danger, 'Never worn');
      return ('Low', c.primary, 'Recently added');
    }
    final d = it.lastWornDate == null ? 9999 : daysSince(it.lastWornDate!);
    if (d > 21) return ('High', AppColors.danger, 'Not worn in $d days');
    if (d > 7) return ('Medium', AppColors.amberText, 'Not worn in $d days');
    return ('Low', c.primary, 'Worn recently');
  }

  // ── Consider Donating ───────────────────────────────────────────────────────

  /// Donate entry point — always shown so any item can be donated. When the
  /// item is D-rule flagged it reads "Consider Donating"; otherwise "Donate
  /// This Item". (Donate page lands in Phase 7.)
  Widget _buildConsiderDonating(BuildContext context, AppColorsTheme c,
          {required bool flagged}) =>
      SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Donate page arrives in a later update')),
            );
          },
          icon: const Icon(Icons.volunteer_activism_outlined,
              size: 18, color: AppColors.danger),
          label: Text(flagged ? 'Consider Donating' : 'Donate This Item',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.dangerBorder),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  // ── Recent Wear History ─────────────────────────────────────────────────────

  Widget _buildWearHistoryCard(
      BuildContext context, WidgetRef ref, Item it, AppColorsTheme c) {
    final eventsAsync = ref.watch(itemEventsProvider(it.id));
    final events = switch (eventsAsync) {
      AsyncData(:final value) => value,
      _ => <ItemEvent>[],
    };
    final recent = events.take(2).toList();

    final viewAll = events.isNotEmpty
        ? GestureDetector(
            onTap: () => context.push(Routes.wearHistory, extra: it),
            child: Text('View All →',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.primary)),
          )
        : null;

    return _card(
      c,
      label: 'Recent Wear History',
      trailing: viewAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eventsAsync.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: c.primary, strokeWidth: 2),
                ),
              ),
            )
          else if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No wear history yet',
                  style: TextStyle(fontSize: 12, color: c.textTertiary)),
            )
          else
            ...recent.map((e) => _wearRow(e, c)),
        ],
      ),
    );
  }

  Widget _wearRow(ItemEvent e, AppColorsTheme c) {
    final worn = e.eventType == EventType.worn;
    return HistoryRow(
      icon: worn ? Icons.check : Icons.skip_next,
      positive: worn,
      title: worn ? 'Worn' : 'Skipped',
      subtitle: _formatDate(e.eventAt),
      trailing:
          e.occasion != null ? _readonlyChip(_occLabel(e.occasion!), c) : null,
    );
  }

  // ── Sticky bottom buttons ───────────────────────────────────────────────────

  Widget _buildBottomButtons(
      BuildContext context, WidgetRef ref, Item it, AppColorsTheme c) {
    final available = it.status == ItemStatus.inWardrobe;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: available
                      ? () async {
                          final ok = await showLogWearSheet(context, it.name);
                          if (!ok) return;
                          await ref
                              .read(wardrobeProvider.notifier)
                              .logWorn(it);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Logged a wear for ${it.name}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    disabledBackgroundColor: c.border,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 18),
                      SizedBox(width: 8),
                      Text('Log Wear',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => openGeneratorWithPin(context, ref, it),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: c.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_fix_high, size: 18, color: c.primary),
                      const SizedBox(width: 8),
                      Text('Build Outfit',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.primary)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete confirmation ─────────────────────────────────────────────────────

  void _confirmDelete(BuildContext context, WidgetRef ref, Item it) {
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
            20, 8, 20, MediaQuery.of(sheetCtx).viewPadding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.delete_outline, size: 40, color: AppColors.danger),
            const SizedBox(height: 12),
            Text('Remove "${it.name}"?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary)),
            const SizedBox(height: 6),
            Text('This will archive the item from your wardrobe.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.textSecondary)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(sheetCtx).pop();
                  await ref.read(wardrobeProvider.notifier).deleteItem(it.id);
                  if (context.mounted) context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Remove Item',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.of(sheetCtx).pop(),
                child: Text('Cancel',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared small widgets ────────────────────────────────────────────────────

  Widget _card(AppColorsTheme c,
          {required String label, required Widget child, Widget? trailing}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary)),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      );

  Widget _readonlyChip(String label, AppColorsTheme c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border, width: 0.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.textSecondary)),
      );

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _categoryTypeColour(Item it) {
    final catLabel = switch (it.category) {
      ItemCategory.top => 'Tops',
      ItemCategory.bottom => 'Bottoms',
      ItemCategory.outerwear => 'Outerwear',
      ItemCategory.footwear => 'Shoes',
      ItemCategory.others => 'Others',
    };
    final typeDef = ItemTypeDictionary.byStoredValue(it.type);
    final typeLabel = typeDef?.displayLabel ?? it.type;
    final colour = it.colorTags.isNotEmpty ? ' · ${_colourName(it.colorTags.first)}' : '';
    return '$catLabel · $typeLabel$colour';
  }

  String _colourName(String tag) {
    try {
      final name = SwatchColour.fromValue(tag).name;
      return name[0].toUpperCase() + name.substring(1);
    } catch (_) {
      return tag;
    }
  }

  String _occLabel(Occasion o) => o.name[0].toUpperCase() + o.name.substring(1);

  String _statusLabel(ItemStatus s) => switch (s) {
        ItemStatus.inWardrobe => 'In Wardrobe',
        ItemStatus.laundry => 'In Laundry',
        ItemStatus.lent => 'Lent Out',
        ItemStatus.stored => 'Stored',
        ItemStatus.donated => 'Donated',
        ItemStatus.deleted => 'Removed',
      };

  String _lastWornShort(DateTime? d) {
    if (d == null) return 'Never';
    final days = daysSince(d);
    if (days == 0) return 'Today';
    if (days < 30) return '${days}d';
    if (days < 365) return '${(days / 30).floor()}mo';
    return '${(days / 365).floor()}yr';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final d = dt.toLocal();
    final hour12 = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    final time = '$hour12:${d.minute.toString().padLeft(2, '0')} $ampm';
    return '${d.day} ${months[d.month - 1]} ${d.year} · $time';
  }
}
