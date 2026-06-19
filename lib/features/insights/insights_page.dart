import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/main_page_header.dart';
import '../../data/models/item.dart';
import '../../providers/insights_providers.dart';
import '../../providers/profile_providers.dart';
import '../../providers/wardrobe_providers.dart';
import '../../routing/app_router.dart';

/// Insights page (FE §29, §41): health ring, quick stats, utilisation card,
/// and the "Items That Need Attention" scrollable tab bar.
class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final dataAsync = ref.watch(insightsProvider);
    final profile = ref.watch(profileProvider).asData?.value;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            MainPageHeader(
              title: 'Insights',
              avatarSource: profile?.displayName ?? profile?.email,
            ),
            Expanded(
              child: dataAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    child: Text('Error loading insights',
                        style: TextStyle(color: c.textSecondary))),
                data: (data) {
                  if (data == null) {
                    return Center(
                      child: Text(
                        'Sign in to see your insights.',
                        style:
                            TextStyle(color: c.textSecondary),
                      ),
                    );
                  }
                  return _InsightsContent(data: data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main scrollable content ──────────────────────────────────────────────────

class _InsightsContent extends StatefulWidget {
  const _InsightsContent({required this.data});
  final InsightsData data;

  @override
  State<_InsightsContent> createState() => _InsightsContentState();
}

class _InsightsContentState extends State<_InsightsContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 4 attention tabs (Sleeping Items link is in the Utilisation card)
  static const _tabTitles = [
    'Never Worn',
    'Long Unused',
    'Skipped Often',
    'Overused',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_rebuild);
  }

  void _rebuild() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_rebuild);
    _tabController.dispose();
    super.dispose();
  }

  List<Item> _tabItems(int index) {
    switch (index) {
      case 0: return widget.data.neverWornItems;
      case 1: return widget.data.longUnusedItems;
      case 2: return widget.data.skippedOftenItems;
      case 3: return widget.data.overusedItems;
      default: return [];
    }
  }

  InsightViewAllType _viewAllType(int index) {
    switch (index) {
      case 0: return InsightViewAllType.neverWorn;
      case 1: return InsightViewAllType.longUnused;
      case 2: return InsightViewAllType.skippedOften;
      case 3: return InsightViewAllType.overused;
      default: return InsightViewAllType.neverWorn;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final data = widget.data;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // ── Section 1: Health Score ──────────────────────────────
        _SectionCard(
          label: 'Wardrobe Health Score',
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Ring
              _HealthRing(
                score: data.health.score,
                color: c.primary,
              ),
              const SizedBox(height: 10),
              // Verdict
              Text(
                data.health.verdict,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.health.partial
                    ? data.health.message
                    : 'Based on utilisation & rotation of your active wardrobe',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    fontStyle: data.health.partial
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: c.textTertiary),
              ),
              const SizedBox(height: 16),
              // Sub-score tiles
              Row(
                children: [
                  Expanded(
                    child: _SubScoreTile(
                      pct: data.utilisationPct,
                      label: 'Utilisation',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SubScoreTile(
                      pct: data.rotationPct,
                      label: 'Rotation',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Section 2: Quick Stats ───────────────────────────────
        _SectionCard(
          label: 'Quick Stats',
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.0,
              children: [
                _StatTile(
                  value: '${data.stats.totalItems}',
                  label: 'Total Items',
                  bg: c.surface2,
                  valueFg: c.textPrimary,
                  labelFg: c.textTertiary,
                ),
                _StatTile(
                  value: '${data.stats.wornThisMonth}',
                  label: 'Worn This Month',
                  bg: const Color(0xFFEFF6FF),
                  valueFg: const Color(0xFF1D4ED8),
                  labelFg: const Color(0xFF3B5ED8),
                ),
                _StatTile(
                  value: '${data.stats.neverWorn}',
                  label: 'Never Worn',
                  bg: const Color(0xFFFFFBEB),
                  valueFg: const Color(0xFF92400E),
                  labelFg: const Color(0xFF92400E),
                ),
                _StatTile(
                  value: '${data.stats.donationCandidates}',
                  label: 'Donate Candidates →',
                  bg: AppColors.dangerBg,
                  valueFg: AppColors.danger,
                  labelFg: AppColors.danger,
                  onTap: () => context.go(Routes.shellDonate),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Section 3: Wardrobe Health Breakdown ────────────────────
        _SectionCard(
          label: 'Wardrobe Health Breakdown',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'Utilisation',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${data.stats.wornThisMonth} of ${data.stats.totalItems} active items',
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ),
                  Text(
                    '${data.utilisationPct}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: data.utilisationPct / 100,
                  minHeight: 8,
                  backgroundColor: c.surface2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.utilisationFill(data.utilisationPct)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Rotation',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(
                      Routes.viewAll,
                      extra: InsightViewAllType.overused,
                    ),
                    child: Text(
                      'View All →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${data.overusedItems.length} overused item${data.overusedItems.length == 1 ? '' : 's'}',
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ),
                  Text(
                    '${data.rotationPct}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: data.rotationPct / 100,
                  minHeight: 8,
                  backgroundColor: c.surface2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.utilisationFill(data.rotationPct)),
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: c.border),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${data.sleepingItems.length} items not worn in 90+ days',
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(
                      Routes.viewAll,
                      extra: InsightViewAllType.sleeping,
                    ),
                    child: Text(
                      'View All →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Each score contributes 50% to your Health Score.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: c.textTertiary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Section 4: Items That Need Attention ─────────────────
        _SectionCard(
          label: 'Items That Need Attention',
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Scrollable tab bar with gradient fade overlay
              Stack(
                children: [
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: c.primary,
                    indicatorWeight: 2.5,
                    labelColor: c.primary,
                    unselectedLabelColor: c.textTertiary,
                    dividerColor: c.border,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      for (int i = 0; i < _tabTitles.length; i++)
                        Tab(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_tabTitles[i]),
                              Text(
                                '${_tabItems(i).length}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _tabController.index == i
                                      ? c.primary
                                      : c.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  // Gradient fade on the right edge to hint more tabs
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              c.surface.withValues(alpha: 0),
                              c.surface,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Tab content: 3 rows + View All link
              AnimatedBuilder(
                animation: _tabController,
                builder: (ctx, _) {
                  final tabIdx = _tabController.index;
                  final tabItems = _tabItems(tabIdx);
                  final shown = tabItems.take(3).toList();
                  return Column(
                    children: [
                      for (int i = 0; i < shown.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: c.border),
                        _AttentionRow(
                          item: shown[i],
                          tabIndex: tabIdx,
                        ),
                      ],
                      if (tabItems.isEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No items here — great job!',
                            style: TextStyle(
                                fontSize: 13, color: c.textTertiary),
                          ),
                        ),
                      if (tabItems.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Divider(height: 1, color: c.border),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => context.push(
                            Routes.viewAll,
                            extra: _viewAllType(tabIdx),
                          ),
                          child: Text(
                            'View All ${tabItems.length} items →',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Health ring ──────────────────────────────────────────────────────────────

class _HealthRing extends StatelessWidget {
  const _HealthRing({required this.score, required this.color});
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 130,
      height: 130,
      child: CustomPaint(
        painter: _RingPainter(
          progress: score / 100,
          ringColor: color,
          trackColor: c.surface2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$score',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            Text(
              '/100',
              style: TextStyle(fontSize: 11, color: c.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  final double progress;
  final Color ringColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 12.0;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - strokeWidth) / 2,
    );

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
          rect, -math.pi / 2, 2 * math.pi * progress, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.ringColor != ringColor ||
      old.trackColor != trackColor;
}

// ── Sub-score tile ───────────────────────────────────────────────────────────

class _SubScoreTile extends StatelessWidget {
  const _SubScoreTile({required this.pct, required this.label});
  final int pct;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: c.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Quick stat tile ──────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.bg,
    required this.valueFg,
    required this.labelFg,
    this.onTap,
  });

  final String value;
  final String label;
  final Color bg;
  final Color valueFg;
  final Color labelFg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: valueFg,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: labelFg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Attention tab row ─────────────────────────────────────────────────────────

class _AttentionRow extends ConsumerWidget {
  const _AttentionRow({required this.item, required this.tabIndex});
  final Item item;
  final int tabIndex;

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
    final subLabel = _subLabel(item, tabIndex, now);
    final badge = _badge(item, tabIndex, now);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(Routes.itemDetail, extra: item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 46,
                height: 46,
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
            const SizedBox(width: 10),
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
                  Text(
                    subLabel,
                    style: TextStyle(
                        fontSize: 11, color: c.textTertiary),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 4),
              _BadgePill(
                  label: badge.$1, bg: badge.$2, fg: badge.$3),
            ],
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: c.chevron),
          ],
        ),
      ),
    );
  }

  String _subLabel(Item item, int tabIndex, DateTime now) {
    switch (tabIndex) {
      case 0: // Never Worn
        final daysSinceAdded = now.difference(item.dateAdded).inDays;
        final totalDays = item.initialUsageAgeDays + daysSinceAdded;
        if (item.initialUsageAgeDays > 0) {
          return 'Owned $totalDays days, never worn';
        }
        if (daysSinceAdded == 0) return 'Added today';
        if (daysSinceAdded == 1) return 'Added 1 day ago';
        return 'Added $daysSinceAdded days ago';
      case 1: // Long Unused
        if (item.lastWornDate == null) return 'Never worn';
        final d = now.difference(item.lastWornDate!).inDays;
        return 'Last worn $d days ago';
      case 2: // Skipped Often
        final total = item.wearCount + item.skipCount;
        return total == 0
            ? 'No wear/skip data'
            : 'Skipped ${item.skipCount} of $total times';
      case 3: // Overused — mirrors itemWearRate() usage period
        final daysSinceAdded = now.difference(item.dateAdded).inDays;
        final int usageDays;
        if (item.initialWearCountOption == 'dontRemember') {
          usageDays = daysSinceAdded < 1 ? 1 : daysSinceAdded;
        } else {
          final raw = item.initialUsageAgeDays + daysSinceAdded;
          usageDays = raw < 1 ? 1 : raw;
        }
        return 'Worn ${item.wearCount} times in $usageDays days';
      default:
        return '';
    }
  }

  (String, Color, Color)? _badge(Item item, int tabIndex, DateTime now) {
    switch (tabIndex) {
      case 0: // Never Worn — use total ownership period for "New" threshold
        final daysSinceAdded = now.difference(item.dateAdded).inDays;
        final totalDays = item.initialUsageAgeDays + daysSinceAdded;
        if (totalDays <= 14) {
          return ('New', AppColors.badgeNewBg, AppColors.badgeNewText);
        }
        return ('Never worn', AppColors.badgeNeverWornBg,
            AppColors.badgeNeverWornText);
      case 1: // Long Unused
        if (item.lastWornDate == null) return null;
        final d = now.difference(item.lastWornDate!).inDays;
        if (d > 90) {
          return ('$d days', AppColors.badgeWornOutBg,
              AppColors.badgeWornOutText);
        }
        return ('$d days', AppColors.badgeNeverWornBg,
            AppColors.badgeNeverWornText);
      case 2: // Skipped Often
        final total = item.wearCount + item.skipCount;
        if (total == 0) return null;
        final pct = (item.skipCount / total * 100).round();
        if (item.skipCount / total > 0.70) {
          return ('$pct% skipped', AppColors.badgeWornOutBg,
              AppColors.badgeWornOutText);
        }
        return ('$pct% skipped', AppColors.badgeNeverWornBg,
            AppColors.badgeNeverWornText);
      case 3: // Overused
        return ('Overused', AppColors.badgeOverusedBg,
            AppColors.badgeOverusedText);
      default:
        return null;
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

// ── Section card wrapper ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          child,
        ],
      ),
    );
  }
}
