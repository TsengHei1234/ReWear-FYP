import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/widgets/history_row.dart';
import '../../data/models/item.dart';
import '../../data/models/item_event.dart';
import '../../providers/wardrobe_providers.dart';

/// Full chronological wear/skip history for one item. Source: FE §21.
class FullWearHistoryPage extends ConsumerWidget {
  const FullWearHistoryPage({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final eventsAsync = ref.watch(itemEventsProvider(item.id));
    final events = switch (eventsAsync) {
      AsyncData(:final value) => value,
      _ => <ItemEvent>[],
    };

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Wear History · ${events.length}',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: eventsAsync.isLoading
          ? Center(child: CircularProgressIndicator(color: c.primary))
          : events.isEmpty
              ? Center(
                  child: Text('No wear history yet',
                      style: TextStyle(fontSize: 14, color: c.textTertiary)),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: c.surface,
                        border: Border.all(color: c.border, width: 0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: events.asMap().entries.map((e) {
                            final isLast = e.key == events.length - 1;
                            return Column(
                              children: [
                                _wearRow(e.value, c),
                                if (!isLast)
                                  Divider(
                                      height: 1,
                                      thickness: 0.5,
                                      color: c.surface2),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
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
          e.occasion != null ? _occChip(_occLabel(e.occasion!), c) : null,
    );
  }

  Widget _occChip(String label, AppColorsTheme c) => Container(
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

  String _occLabel(Occasion o) => o.name[0].toUpperCase() + o.name.substring(1);

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
