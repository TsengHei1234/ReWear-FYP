import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../../core/utils/mutation_helper.dart';
import '../../core/widgets/confirm_sheet.dart';
import '../../core/widgets/main_page_header.dart';
import '../../data/models/item.dart';
import '../../engine/donation/donation_rules.dart';
import '../../providers/donation_providers.dart';
import '../../providers/profile_providers.dart';
import '../../providers/wardrobe_providers.dart';
import '../../routing/app_router.dart';

/// Donate main page (FE §26): candidate cards with filter chips + Keep/Donate
/// buttons, and shortcuts to Kept Items and Donation History.
class DonatePage extends ConsumerStatefulWidget {
  const DonatePage({super.key});

  @override
  ConsumerState<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends ConsumerState<DonatePage> {
  static const _filterLabels = [
    'All',
    'Never Worn',
    'Long Unused',
    'Skipped Often',
    'Poor Condition',
  ];
  int _filterIndex = 0;

  List<DonationCandidateEntry> _applyFilter(
      List<DonationCandidateEntry> all) {
    if (_filterIndex == 0) return all;
    return all.where((e) {
      switch (_filterIndex) {
        case 1:
          return e.assessment.rules.contains(DonationRule.d2NeverWornOld);
        case 2:
          return e.assessment.rules.contains(DonationRule.d1LongUnused);
        case 3:
          return e.assessment.rules.contains(DonationRule.d3FrequentlySkipped);
        case 4:
          return e.assessment.rules.any((r) =>
              r == DonationRule.d4PoorCondition ||
              r == DonationRule.d5WornUnused);
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final candidatesAsync = ref.watch(donationCandidatesProvider);
    final profile = ref.watch(profileProvider).asData?.value;
    final donationCount = candidatesAsync.asData?.value.length ?? 0;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MainPageHeader(
              title: 'Donate',
              avatarSource: profile?.displayName ?? profile?.email,
            ),
            // ── Fixed controls ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderCard(count: donationCount),
                  const SizedBox(height: 12),
                  _ShortcutTiles(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            FilterChipRow(
              labels: _filterLabels,
              selectedIndex: _filterIndex,
              onSelected: (i) => setState(() => _filterIndex = i),
            ),
            const SizedBox(height: 12),
            // ── Scrollable cards ──────────────────────────────────
            Expanded(
              child: candidatesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    child: Text('Error loading candidates',
                        style: TextStyle(color: c.textSecondary))),
                data: (all) {
                  final filtered = _applyFilter(all);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite_outline,
                                size: 48, color: c.textTertiary),
                            const SizedBox(height: 12),
                            Text(
                              all.isEmpty
                                  ? 'Your wardrobe looks great!'
                                  : 'No items match this filter.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: c.textSecondary,
                              ),
                            ),
                            if (all.isEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'No items currently need your attention.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13, color: c.textTertiary),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _DonationCandidateCard(
                      entry: filtered[i],
                      onKeep: () => _keepItem(filtered[i].item),
                      onDonate: () => _donateItem(filtered[i].item),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _keepItem(Item item) async {
    final chosen = await _showKeepDurationSheet(context);
    if (chosen == null || !mounted) return;
    await runMutation(
      context,
      action: () => ref.read(wardrobeProvider.notifier).setKeptUntil(
            itemId: item.id,
            keptUntil: chosen,
          ),
      successMessage: '${item.name} deferred from donation',
    );
  }

  Future<void> _donateItem(Item item) async {
    final ok = await showConfirmSheet(
      context,
      icon: Icons.favorite_border_rounded,
      title: 'Donate ${item.name}?',
      message: 'This will mark the item as donated and remove it from your wardrobe.',
      confirmLabel: 'Donate',
      isDestructive: true,
    );
    if (!ok || !mounted) return;
    await runMutation(
      context,
      action: () => ref.read(wardrobeProvider.notifier).confirmDonation(item.id),
      successMessage: '${item.name} marked as donated',
    );
  }
}

// ── Header area ───────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              count > 0 ? 'Donation Candidates ·' : 'Donation Candidates',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count item${count == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Review clothing items that may no longer be useful in your wardrobe.',
          style: TextStyle(fontSize: 13, color: c.textTertiary),
        ),
      ],
    );
  }
}

// ── Shortcut tiles ───────────────────────────────────────────────────────────

class _ShortcutTiles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ShortcutTile(
            label: 'Kept Items',
            onTap: () => context.push(Routes.keptItems),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ShortcutTile(
            label: 'Donation History',
            onTap: () => context.push(Routes.donationHistory),
          ),
        ),
      ],
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
            Icon(Icons.arrow_forward, size: 16, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Donation candidate card ───────────────────────────────────────────────────

class _DonationCandidateCard extends ConsumerWidget {
  const _DonationCandidateCard({
    required this.entry,
    required this.onKeep,
    required this.onDonate,
  });

  final DonationCandidateEntry entry;
  final VoidCallback onKeep;
  final VoidCallback onDonate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final item = entry.item;
    final imageUrlAsync =
        ref.watch(itemImageUrlProvider(item.imagePath));
    final imageUrl = imageUrlAsync.asData?.value;
    final cacheKey = item.imagePath != null
        ? '${item.imagePath}_v${item.updatedAt.millisecondsSinceEpoch}'
        : null;
    final primaryReason = entry.assessment.messages.isNotEmpty
        ? entry.assessment.messages.first
        : '';
    final categoryLabel = _categoryLabel(item.category);
    final typeLabel = item.type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');

    return GestureDetector(
      onTap: () => context.push(Routes.itemDetail, extra: item),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // ── Card body ──
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: imageUrl != null && cacheKey != null
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              cacheKey: cacheKey,
                              fit: BoxFit.cover,
                              memCacheWidth: 200,
                              memCacheHeight: 200,
                              placeholder: (_, _) =>
                                  _photoPlaceholder(c),
                              errorWidget: (_, _, _) =>
                                  _photoPlaceholder(c),
                            )
                          : _photoPlaceholder(c),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$categoryLabel · $typeLabel',
                          style: TextStyle(
                              fontSize: 11, color: c.textTertiary),
                        ),
                        const SizedBox(height: 4),
                        if (primaryReason.isNotEmpty)
                          Row(
                            children: [
                              Icon(Icons.schedule_outlined,
                                  size: 13, color: c.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  primaryReason,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 2),
                        Text(
                          'Condition: ${_conditionLabel(item.condition)}',
                          style: TextStyle(
                              fontSize: 11, color: c.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Button row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: onKeep,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.textPrimary,
                          side: BorderSide(color: c.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Keep',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: onDonate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Donate',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder(AppColorsTheme c) => Container(
        color: c.surface2,
        child: Icon(Icons.checkroom_outlined,
            size: 28, color: c.textTertiary),
      );

  String _categoryLabel(ItemCategory cat) => switch (cat) {
        ItemCategory.top => 'Top',
        ItemCategory.bottom => 'Bottom',
        ItemCategory.outerwear => 'Outerwear',
        ItemCategory.footwear => 'Shoes',
        ItemCategory.others => 'Others',
      };

  String _conditionLabel(int c) => switch (c) {
        5 => 'Excellent',
        4 => 'Good',
        3 => 'Fair',
        2 => 'Poor',
        _ => 'Worn Out',
      };
}

// ── Keep duration sheet ──────────────────────────────────────────────────────

Future<DateTime?> _showKeepDurationSheet(BuildContext context) {
  final now = DateTime.now();
  final options = [
    ('1 Week', now.add(const Duration(days: 7))),
    ('1 Month', now.add(const Duration(days: 30))),
    ('3 Months', now.add(const Duration(days: 90))),
    ('6 Months', now.add(const Duration(days: 180))),
    ('Indefinitely', DateTime(2099, 12, 31)),
  ];

  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetCtx) {
      final c = sheetCtx.colors;
      return SafeArea(
        top: false,
        child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
            const SizedBox(height: 20),
            Text(
              'How long would you like to keep it?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'The item won\'t appear as a donation candidate until the period ends.',
              style: TextStyle(fontSize: 13, color: c.textSecondary),
            ),
            const SizedBox(height: 16),
            ...options.map(
              (opt) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(
                  opt.$1,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: c.chevron),
                onTap: () => Navigator.of(sheetCtx).pop(opt.$2),
              ),
            ),
          ],
        ),
      ),
      );
    },
  );
}
