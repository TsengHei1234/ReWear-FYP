import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../../core/widgets/badge_chip.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../data/models/item.dart';
import '../../engine/badges/badge_engine.dart';
import '../../engine/daily/daily_rotation_display.dart';
import '../../engine/scoring/frs.dart';
import '../../providers/home_providers.dart';
import '../../providers/profile_providers.dart';
import '../../providers/wardrobe_providers.dart';
import '../../routing/app_router.dart';
import '../outfit/build_outfit_action.dart';

/// Home (FE §16): greeting, occasion chips, Today's Suggestions carousel
/// (individual items via `rankDailyRotation`), and the Wardrobe Snapshot.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const _occasions = [
    (label: 'All', value: null),
    (label: 'Casual', value: Occasion.casual),
    (label: 'Work', value: Occasion.work),
    (label: 'Active', value: Occasion.active),
    (label: 'Relax', value: Occasion.relax),
  ];
  int _occasionIndex = 0;

  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = ref.watch(wardrobeProvider).asData?.value ?? const <Item>[];
    final profile = ref.watch(profileProvider).asData?.value;
    final now = DateTime.now();

    final ranked = rankDailyRotation(
      items,
      occasion: _occasions[_occasionIndex].value,
      mode: profile?.recommendationMode ?? RecommendationMode.balanced,
      now: now,
      preferredColours: profile?.preferredColours.toSet() ?? const {},
      dislikedColours: profile?.dislikedColours.toSet() ?? const {},
    );
    final picks = ranked.take(3).toList();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
          children: [
            _TopBar(displayName: profile?.displayName ?? profile?.email),
            const SizedBox(height: 12),

            // Section 1 — Occasion chips
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('What are you dressing for?',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 8),
            FilterChipRow(
              labels: [for (final o in _occasions) o.label],
              selectedIndex: _occasionIndex,
              onSelected: (i) {
                setState(() {
                  _occasionIndex = i;
                  _currentPage = 0;
                });
                if (_pageController.hasClients) _pageController.jumpToPage(0);
              },
            ),
            const SizedBox(height: 16),

            // Section 2 — Today's Suggestions carousel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("Today's Suggestions",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary)),
            ),
            const SizedBox(height: 12),
            if (picks.isEmpty)
              _EmptySuggestions(hasItems: items.isNotEmpty)
            else ...[
              SizedBox(
                height: 322,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: picks.length,
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.only(
                        left: 16, right: i == picks.length - 1 ? 16 : 0),
                    child: _SuggestionCard(
                      scored: picks[i],
                      allItems: items,
                      now: now,
                      onTap: () =>
                          context.push(Routes.itemDetail, extra: picks[i].item),
                      onWear: () => _wear(picks[i].item),
                      onBuildOutfit: () =>
                          openGeneratorWithPin(context, ref, picks[i].item),
                    ),
                  ),
                ),
              ),
              if (picks.length > 1) ...[
                const SizedBox(height: 12),
                _CarouselDots(
                  count: picks.length,
                  active: _currentPage.clamp(0, picks.length - 1),
                ),
              ],
            ],
            const SizedBox(height: 16),

            // Section 3 — Wardrobe Snapshot
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _WardrobeSnapshotCard(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _wear(Item item) async {
    final ok = await showLogWearSheet(context, item.name);
    if (!ok) return;
    await ref.read(wardrobeProvider.notifier).logWorn(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged a wear for ${item.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({this.displayName});
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final h = DateTime.now().hour;
    final greeting = h < 12
        ? 'Good morning'
        : h < 17
            ? 'Good afternoon'
            : 'Good evening';
    final first = (displayName ?? '').trim().split(RegExp(r'\s+')).first;
    final title = first.isEmpty ? greeting : '$greeting, $first';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary)),
          ),
          const SizedBox(width: 12),
          ProfileAvatarButton(source: displayName),
        ],
      ),
    );
  }

}

// ── Suggestion card ───────────────────────────────────────────────────────

class _SuggestionCard extends ConsumerWidget {
  const _SuggestionCard({
    required this.scored,
    required this.allItems,
    required this.now,
    required this.onTap,
    required this.onWear,
    required this.onBuildOutfit,
  });

  final ItemScore scored;
  final List<Item> allItems;
  final DateTime now;

  /// Tapping the card body (photo / name) opens Item Detail.
  final VoidCallback onTap;
  final VoidCallback onWear;
  final VoidCallback onBuildOutfit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final item = scored.item;
    final imageUrl =
        ref.watch(itemImageUrlProvider(item.imagePath)).asData?.value;
    final badges = computeAllBadges(item, allItems, now: now);
    final primaryBadge = badges.isEmpty ? null : badges.first;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo + overlays
          SizedBox(
            height: 210,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                imageUrl == null
                    ? Container(
                        color: const Color(0xFFEDE4D4),
                        child: Icon(Icons.checkroom_outlined,
                            size: 40, color: c.textTertiary))
                    : CachedNetworkImage(
                        imageUrl: imageUrl,
                        cacheKey: item.imagePath != null
                            ? '${item.imagePath}_v${item.updatedAt.millisecondsSinceEpoch}'
                            : null,
                        fit: BoxFit.cover,
                      ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: _OverlayScore(score: dailyRotationDisplayScore(scored.frs)),
                ),
                if (primaryBadge != null)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: BadgeChip(badge: primaryBadge),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary)),
                const SizedBox(height: 2),
                Text('${_categoryLabel(item.category)} · ${_typeLabel(item.type)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: c.textTertiary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SmallButton(
                        icon: Icons.check,
                        label: 'Wear Today',
                        filled: true,
                        onTap: onWear,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SmallButton(
                        icon: Icons.auto_fix_high,
                        label: 'Build Outfit',
                        filled: false,
                        onTap: onBuildOutfit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

class _OverlayScore extends StatelessWidget {
  const _OverlayScore({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('Score $score',
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = filled ? Colors.white : c.textPrimary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? c.primary : c.surface,
          border: filled ? null : Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: filled ? FontWeight.w700 : FontWeight.w600,
                    color: fg)),
          ],
        ),
      ),
    );
  }
}

/// Small subtle page-dots under the suggestions carousel (active = primary pill).
class _CarouselDots extends StatelessWidget {
  const _CarouselDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: i == active ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == active ? c.primary : c.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptySuggestions extends StatelessWidget {
  const _EmptySuggestions({required this.hasItems});
  final bool hasItems;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.checkroom_outlined, size: 36, color: c.textTertiary),
          const SizedBox(height: 10),
          Text(
            hasItems
                ? 'Nothing to suggest for this occasion'
                : 'Add items to get suggestions',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ── Wardrobe Snapshot ─────────────────────────────────────────────────────

class _WardrobeSnapshotCard extends ConsumerWidget {
  const _WardrobeSnapshotCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final stats = ref.watch(homeSnapshotProvider).asData?.value;

    final total = stats?.totalItems ?? 0;
    final active = stats?.wornThisMonth ?? 0;
    final dormant = (total - active).clamp(0, total);
    final donation = stats?.donationCandidates ?? 0;
    final utilisation = total == 0 ? 0 : ((active / total) * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Wardrobe Snapshot',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('Utilisation Rate',
                    style: TextStyle(fontSize: 12, color: c.textSecondary)),
              ),
              Text('$utilisation%',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: utilisation / 100,
              minHeight: 8,
              backgroundColor: c.surface2,
              valueColor:
                  AlwaysStoppedAnimation(AppColors.utilisationFill(utilisation)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: '$active items',
                  label: 'Active Rotation',
                  bg: c.primaryLight,
                  valueColor: c.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  value: '$dormant items',
                  label: 'Dormant Items',
                  bg: c.surface2,
                  valueColor: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.go(Routes.shellDonate),
            behavior: HitTestBehavior.opaque,
            child: Text('$donation items for donation review →',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.primary)),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.bg,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color bg;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, color: c.textSecondary)),
        ],
      ),
    );
  }
}
