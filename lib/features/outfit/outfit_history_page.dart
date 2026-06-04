import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../providers/outfit_history_providers.dart';
import '../../providers/wardrobe_providers.dart';

/// Outfit History (FE §25). Display-only list of logged outfits, newest first.
/// Rows are NOT tappable.
class OutfitHistoryPage extends ConsumerWidget {
  const OutfitHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final historyAsync = ref.watch(outfitHistoryProvider);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: c.textPrimary,
        title: Text('Outfit History',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.textPrimary)),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load your outfit history.\n$e',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary)),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) return const _EmptyState();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.border, width: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    for (int i = 0; i < entries.length; i++) ...[
                      if (i > 0)
                        Divider(color: c.surface2, height: 1, thickness: 0.5),
                      _HistoryRow(entry: entries[i]),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final OutfitHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final at = entry.log.loggedAt.toLocal();
    final occ = entry.log.occasion;
    final subtitle = occ == null
        ? _formatTime(at)
        : '${_occLabel(occ)} · ${_formatTime(at)}';
    final paths = entry.imagePaths.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Left column: date + "occasion · time".
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_formatDate(at),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: c.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right: item thumbnails.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < paths.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                _HistoryThumb(imagePath: paths[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryThumb extends ConsumerWidget {
  const _HistoryThumb({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final url = imagePath == null
        ? null
        : ref.watch(itemImageUrlProvider(imagePath)).asData?.value;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 40,
        height: 40,
        child: url == null
            ? Container(
                color: c.surface2,
                child: Icon(Icons.checkroom_outlined,
                    size: 18, color: c.textTertiary))
            : CachedNetworkImage(imageUrl: url, fit: BoxFit.cover),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 44, color: c.textTertiary),
            const SizedBox(height: 12),
            Text('No outfits logged yet',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary)),
            const SizedBox(height: 4),
            Text('Log an outfit from the generator to see it here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.textSecondary)),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

String _formatTime(DateTime d) {
  final hour12 = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '$hour12:${d.minute.toString().padLeft(2, '0')} $ampm';
}

String _occLabel(Occasion o) => switch (o) {
      Occasion.casual => 'Casual',
      Occasion.work => 'Work',
      Occasion.active => 'Active',
      Occasion.relax => 'Relax',
    };
