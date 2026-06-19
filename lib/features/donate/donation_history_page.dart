import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../../data/models/item.dart';
import '../../providers/donation_providers.dart';
import '../../providers/wardrobe_providers.dart';
import '../../routing/app_router.dart';

/// Donation History screen (FE §28): past donated items with category filter.
class DonationHistoryPage extends ConsumerStatefulWidget {
  const DonationHistoryPage({super.key});

  @override
  ConsumerState<DonationHistoryPage> createState() =>
      _DonationHistoryPageState();
}

class _DonationHistoryPageState
    extends ConsumerState<DonationHistoryPage> {
  static const _chipLabels = [
    'All',
    'Tops',
    'Bottoms',
    'Outerwear',
    'Shoes',
  ];
  static const _chipCategories = [
    null,
    ItemCategory.top,
    ItemCategory.bottom,
    ItemCategory.outerwear,
    ItemCategory.footwear,
  ];
  int _chipIndex = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final historyAsync = ref.watch(donationHistoryProvider);

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
          'Donation History',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error loading history',
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
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.volunteer_activism_outlined,
                                  size: 48, color: c.textTertiary),
                              const SizedBox(height: 12),
                              Text(
                                'No donations yet',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: c.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Items you donate will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13, color: c.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: c.border),
                        itemBuilder: (ctx, i) => _DonationHistoryRow(
                          item: filtered[i],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DonationHistoryRow extends ConsumerWidget {
  const _DonationHistoryRow({required this.item});
  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final imageUrlAsync = ref.watch(itemImageUrlProvider(item.imagePath));
    final imageUrl = imageUrlAsync.asData?.value;
    // Historical donation thumbnail: stable path (item never changes after donation)
    // Uses simple cacheKey without version since photo won't change post-donation.
    final cacheKey = item.imagePath;

    final donatedLabel = item.donatedAt != null
        ? 'Donated on ${DateFormat('d MMM yyyy').format(item.donatedAt!)}'
        : 'Donated';

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
                child: imageUrl != null
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
                    donatedLabel,
                    style:
                        TextStyle(fontSize: 11, color: c.textTertiary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 14, color: c.chevron),
          ],
        ),
      ),
    );
  }
}
