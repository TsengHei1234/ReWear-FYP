import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../../data/models/item.dart';
import '../../providers/insights_providers.dart';
import '../../providers/wardrobe_providers.dart';
import '../../routing/app_router.dart';

/// The 5 "View All" sub-pages for the Insights attention tabs (FE §30).
/// A single widget parameterised by [InsightViewAllType].
class ViewAllPage extends ConsumerStatefulWidget {
  const ViewAllPage({super.key, required this.type});
  final InsightViewAllType type;

  @override
  ConsumerState<ViewAllPage> createState() => _ViewAllPageState();
}

class _ViewAllPageState extends ConsumerState<ViewAllPage> {
  static const _chipLabels = [
    'All',
    'Tops',
    'Bottoms',
    'Outerwear',
    'Shoes',
    'Others',
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

  String get _title => switch (widget.type) {
        InsightViewAllType.neverWorn => 'Never Worn Items',
        InsightViewAllType.longUnused => 'Long Unused Items',
        InsightViewAllType.skippedOften => 'Skipped Often Items',
        InsightViewAllType.overused => 'Overused Items',
        InsightViewAllType.sleeping => 'Sleeping Items',
      };

  List<Item> _typeItems(InsightsData data) => switch (widget.type) {
        InsightViewAllType.neverWorn => data.neverWornItems,
        InsightViewAllType.longUnused => data.longUnusedItems,
        InsightViewAllType.skippedOften => data.skippedOftenItems,
        InsightViewAllType.overused => data.overusedItems,
        InsightViewAllType.sleeping => data.sleepingItems,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dataAsync = ref.watch(insightsProvider);

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
        title: dataAsync.when(
          loading: () => Text(_title,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          error: (_, _) => Text(_title,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          data: (data) {
            final count = data == null ? 0 : _typeItems(data).length;
            return Text(
              '$_title · $count',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary),
            );
          },
        ),
        centerTitle: true,
      ),
      body: dataAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error loading data',
                style: TextStyle(color: c.textSecondary))),
        data: (data) {
          if (data == null) {
            return const SizedBox.shrink();
          }
          final all = _typeItems(data);
          final filtered = _chipIndex == 0
              ? all
              : all
                  .where(
                      (i) => i.category == _chipCategories[_chipIndex])
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
                              Icon(Icons.check_circle_outline,
                                  size: 48, color: c.textTertiary),
                              const SizedBox(height: 12),
                              Text(
                                all.isEmpty
                                    ? 'Nothing to see here!'
                                    : 'No items match this filter.',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: c.textSecondary),
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
                        itemBuilder: (ctx, i) => _ViewAllRow(
                          item: filtered[i],
                          type: widget.type,
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

// ── View All row ─────────────────────────────────────────────────────────────

class _ViewAllRow extends ConsumerWidget {
  const _ViewAllRow({required this.item, required this.type});
  final Item item;
  final InsightViewAllType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final imageUrlAsync =
        ref.watch(itemImageUrlProvider(item.imagePath));
    final imageUrl = imageUrlAsync.asData?.value;
    final cacheKey = item.imagePath != null
        ? '${item.imagePath}_v${item.updatedAt.millisecondsSinceEpoch}'
        : null;

    final now = DateTime.now();
    final subLabel = _subLabel(item, type, now);
    final badge = _badge(item, type, now);

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
                width: 48,
                height: 48,
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
            // Text — Expanded fills all remaining space before badge/chevron
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
                    subLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, color: c.textTertiary),
                  ),
                ],
              ),
            ),
            // Badge — only shown when non-trivial info (FE §30: don't repeat section name)
            if (badge != null) ...[
              const SizedBox(width: 8),
              _BadgePill(
                  label: badge.$1, bg: badge.$2, fg: badge.$3),
            ],
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 14, color: c.chevron),
          ],
        ),
      ),
    );
  }

  String _subLabel(Item item, InsightViewAllType type, DateTime now) {
    switch (type) {
      case InsightViewAllType.neverWorn:
        final daysSinceAdded = now.difference(item.dateAdded).inDays;
        if (item.initialUsageAgeDays > 0) {
          return 'Owned ${item.initialUsageAgeDays + daysSinceAdded} days, never worn';
        }
        if (daysSinceAdded == 0) return 'Added today';
        if (daysSinceAdded == 1) return 'Added 1 day ago';
        return 'Added $daysSinceAdded days ago';
      case InsightViewAllType.longUnused:
        if (item.lastWornDate == null) return 'Never worn';
        return 'Last worn ${now.difference(item.lastWornDate!).inDays} days ago';
      case InsightViewAllType.skippedOften:
        final total = item.wearCount + item.skipCount;
        return total == 0
            ? 'No wear/skip data'
            : 'Skipped ${item.skipCount} of $total times';
      case InsightViewAllType.overused: // mirrors itemWearRate() usage period
        final daysSinceAdded = now.difference(item.dateAdded).inDays;
        final int usageDays;
        if (item.initialWearCountOption == 'dontRemember') {
          usageDays = daysSinceAdded < 1 ? 1 : daysSinceAdded;
        } else {
          final raw = item.initialUsageAgeDays + daysSinceAdded;
          usageDays = raw < 1 ? 1 : raw;
        }
        return 'Worn ${item.wearCount} times in $usageDays days';
      case InsightViewAllType.sleeping:
        if (item.lastWornDate == null) return 'Never worn';
        return 'Last worn ${now.difference(item.lastWornDate!).inDays} days ago';
    }
  }

  // Badge is suppressed for the View-All page per FE §30 note:
  // "Do NOT show the section name as a chip on each row inside that section's sub-page."
  // We still show the metric badge (days/ratio) since it's informative, not redundant.
  (String, Color, Color)? _badge(
      Item item, InsightViewAllType type, DateTime now) {
    switch (type) {
      case InsightViewAllType.neverWorn:
        final daysSinceAdded = now.difference(item.dateAdded).inDays;
        final totalDays = item.initialUsageAgeDays + daysSinceAdded;
        if (totalDays <= 14) {
          return ('New', AppColors.badgeNewBg, AppColors.badgeNewText);
        }
        return ('Never worn', AppColors.badgeNeverWornBg,
            AppColors.badgeNeverWornText);
      case InsightViewAllType.longUnused:
        if (item.lastWornDate == null) return null;
        final d = now.difference(item.lastWornDate!).inDays;
        return ('$d days',
            d > 90 ? AppColors.badgeWornOutBg : AppColors.badgeNeverWornBg,
            d > 90
                ? AppColors.badgeWornOutText
                : AppColors.badgeNeverWornText);
      case InsightViewAllType.skippedOften:
        final total = item.wearCount + item.skipCount;
        if (total == 0) return null;
        final pct = (item.skipCount / total * 100).round();
        return ('$pct%',
            item.skipCount / total > 0.70
                ? AppColors.badgeWornOutBg
                : AppColors.badgeNeverWornBg,
            item.skipCount / total > 0.70
                ? AppColors.badgeWornOutText
                : AppColors.badgeNeverWornText);
      case InsightViewAllType.overused:
        return ('Overused', AppColors.badgeOverusedBg, AppColors.badgeOverusedText);
      case InsightViewAllType.sleeping:
        if (item.lastWornDate == null) return null;
        final d = now.difference(item.lastWornDate!).inDays;
        return ('$d days', AppColors.badgeWornOutBg,
            AppColors.badgeWornOutText);
    }
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill(
      {required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
