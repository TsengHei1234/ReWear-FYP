import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/outfit_log.dart';
import '../data/models/outfit_log_item.dart';
import 'wardrobe_providers.dart';

/// One row of Outfit History: the logged outfit + its item image paths in layer
/// order (top → bottom → outerwear → shoes). A null path = no photo / missing item.
class OutfitHistoryEntry {
  const OutfitHistoryEntry({required this.log, required this.imagePaths});

  final OutfitLog log;
  final List<String?> imagePaths;
}

/// Outfit History (FE §25). Newest first. Resolves each log's item thumbnails in
/// three batched queries (logs → log items → items). Re-fetches after a logged
/// outfit (watches [wardrobeProvider], which `logOutfitWorn` invalidates).
final outfitHistoryProvider =
    FutureProvider.autoDispose<List<OutfitHistoryEntry>>((ref) async {
  ref.watch(wardrobeProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final logRepo = ref.read(outfitLogRepositoryProvider);
  final logs = await logRepo.getOutfitHistory(userId: userId);
  if (logs.isEmpty) return [];

  final logItems =
      await logRepo.getOutfitItemsForLogs(logs.map((l) => l.id).toList());
  final items = await ref.read(itemRepositoryProvider).getItemsByIds(
        logItems.map((li) => li.itemId).toSet().toList(),
      );
  final imagePathById = {for (final i in items) i.id: i.imagePath};

  // Group items by log, ordered by layer (top, bottom, outerwear, shoes).
  final byLog = <String, List<OutfitLogItem>>{};
  for (final li in logItems) {
    (byLog[li.outfitLogId] ??= []).add(li);
  }
  for (final list in byLog.values) {
    list.sort((a, b) => a.layerType.index.compareTo(b.layerType.index));
  }

  return [
    for (final log in logs)
      OutfitHistoryEntry(
        log: log,
        imagePaths: [
          for (final li in (byLog[log.id] ?? const <OutfitLogItem>[]))
            imagePathById[li.itemId],
        ],
      ),
  ];
});
