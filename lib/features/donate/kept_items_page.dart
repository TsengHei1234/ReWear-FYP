import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../data/models/item.dart';
import '../../providers/donation_providers.dart';
import '../../providers/wardrobe_providers.dart';
import '../../routing/app_router.dart';

/// Kept Items screen (FE §27): items deferred from donation, with Undo Keep.
///
/// Uses keptItemsPageProvider (FutureProvider.autoDispose + direct DB call),
/// the same proven pattern as DonationHistoryPage. keptItemsProvider remains
/// in donation_providers.dart for unit tests only.
class KeptItemsPage extends ConsumerStatefulWidget {
  const KeptItemsPage({super.key});

  @override
  ConsumerState<KeptItemsPage> createState() => _KeptItemsPageState();
}

class _KeptItemsPageState extends ConsumerState<KeptItemsPage> {
  static const _chipLabels = [
    'All', 'Tops', 'Bottoms', 'Outerwear', 'Shoes', 'Others'
  ];
  static const _chipCategories = [
    null,
    ItemCategory.top,
    ItemCategory.bottom,
    ItemCategory.outerwear,
    ItemCategory.footwear,
    ItemCategory.others,
  ];
  int _chipIndex = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final keptAsync = ref.watch(keptItemsPageProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Kept Items',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: keptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error loading kept items',
                style: TextStyle(color: c.textSecondary))),
        data: (items) {
          final filtered = _chipIndex == 0
              ? items
              : items
                  .where((i) => i.category == _chipCategories[_chipIndex])
                  .toList();

          return Column(
            children: [
              const SizedBox(height: 8),
              FilterChipRow(
                labels: _chipLabels,
                selectedIndex: _chipIndex,
                onSelected: (i) => setState(() => _chipIndex = i),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bookmark_border_rounded,
                                  size: 52, color: c.textSecondary),
                              const SizedBox(height: 16),
                              Text(
                                items.isEmpty
                                    ? 'No kept items'
                                    : 'No kept items here',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: c.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                items.isEmpty
                                    ? 'Tap "Keep" on any item in the Donate tab to defer it from donation. It will appear here until the keep period ends.'
                                    : 'No kept items in this category.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: c.border),
                        itemBuilder: (ctx, i) {
                          final item = filtered[i];
                          return _KeptItemRow(
                            item: item,
                            onUndo: () async {
                              await ref
                                  .read(wardrobeProvider.notifier)
                                  .clearKeptUntil(item.id);
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${item.name} returned to donation review'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KeptItemRow extends ConsumerWidget {
  const _KeptItemRow({required this.item, required this.onUndo});

  final Item item;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final imageUrlAsync = ref.watch(itemImageUrlProvider(item.imagePath));
    final imageUrl = imageUrlAsync.asData?.value;
    final cacheKey = item.imagePath != null
        ? '${item.imagePath}_v${item.updatedAt.millisecondsSinceEpoch}'
        : null;

    final keptLabel = _keptLabel(item.keptUntil);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(Routes.itemDetail, extra: item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
          // Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: imageUrl != null && cacheKey != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      cacheKey: cacheKey,
                      fit: BoxFit.cover,
                      memCacheWidth: 150,
                      memCacheHeight: 150,
                      placeholder: (_, _) =>
                          Container(color: c.surface2),
                      errorWidget: (_, _, _) =>
                          Container(color: c.surface2),
                    )
                  : Container(color: c.surface2),
            ),
          ),
          const SizedBox(width: 12),
          // Text
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
                const SizedBox(height: 2),
                Text(
                  keptLabel,
                  style: TextStyle(fontSize: 12, color: c.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Undo Keep button
          SizedBox(
            width: 92,
            height: 32,
            child: OutlinedButton(
              onPressed: () async {
                final confirmed = await showConfirmSheet(
                  context,
                  icon: Icons.bookmark_remove_rounded,
                  title: 'Return to donation review?',
                  message:
                      '"${item.name}" will be removed from Kept Items and placed back in Donation Candidates.',
                  confirmLabel: 'Return',
                );
                if (confirmed) onUndo();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: c.primary,
                minimumSize: Size.zero,
                side: BorderSide(color: c.borderFocus, width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text(
                'Undo Keep',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, size: 14, color: c.chevron),
          ],
        ),
      ),
    );
  }

  String _keptLabel(DateTime? keptUntil) {
    if (keptUntil == null) return 'Kept indefinitely';
    if (keptUntil.year >= 2099) return 'Kept indefinitely';
    final days = keptUntil.difference(DateTime.now()).inDays;
    if (days <= 0) return 'Returning soon';
    if (days == 1) return 'Returns in 1 day';
    return 'Returns in $days days';
  }
}
