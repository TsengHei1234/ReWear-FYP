import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/data/models/outfit_log.dart';
import 'package:rewear/data/models/outfit_log_item.dart';
import 'package:rewear/data/repositories/item_repository.dart';
import 'package:rewear/data/repositories/outfit_log_repository.dart';
import 'package:rewear/providers/outfit_history_providers.dart';
import 'package:rewear/providers/wardrobe_providers.dart';

import '../engine/support/item_factory.dart';

class MockItemRepository extends Mock implements ItemRepository {}

class MockOutfitLogRepository extends Mock implements OutfitLogRepository {}

void main() {
  setUpAll(() => registerFallbackValue(<String>[]));

  late MockItemRepository itemRepo;
  late MockOutfitLogRepository outfitLogRepo;

  setUp(() {
    itemRepo = MockItemRepository();
    outfitLogRepo = MockOutfitLogRepository();
  });

  OutfitLog log(String id, Occasion occ, DateTime at) => OutfitLog(
        id: id,
        userId: 'u',
        source: OutfitLogSource.outfitGenerator,
        occasion: occ,
        loggedAt: at,
      );
  OutfitLogItem oli(String logId, String itemId, LayerType layer) =>
      OutfitLogItem(
        id: '$logId-$itemId',
        userId: 'u',
        outfitLogId: logId,
        itemId: itemId,
        layerType: layer,
      );

  ProviderContainer container() {
    // outfitHistoryProvider watches wardrobeProvider, which loads the wardrobe.
    when(() => itemRepo.getWardrobeItems(any())).thenAnswer((_) async => []);
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('u'),
      itemRepositoryProvider.overrideWithValue(itemRepo),
      outfitLogRepositoryProvider.overrideWithValue(outfitLogRepo),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('groups items per log in layer order, preserving log order', () async {
    when(() => outfitLogRepo.getOutfitHistory(
          userId: any(named: 'userId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => [
          log('l1', Occasion.casual, DateTime(2026, 6, 4)),
          log('l2', Occasion.work, DateTime(2026, 6, 3)),
        ]);
    when(() => outfitLogRepo.getOutfitItemsForLogs(any())).thenAnswer((_) async => [
          oli('l1', 'a', LayerType.bottom), // out of layer order on purpose
          oli('l1', 'b', LayerType.top),
          oli('l2', 'c', LayerType.top),
        ]);
    when(() => itemRepo.getItemsByIds(any())).thenAnswer((_) async => [
          makeItem(id: 'a').copyWith(imagePath: 'a.jpg'),
          makeItem(id: 'b').copyWith(imagePath: 'b.jpg'),
          makeItem(id: 'c').copyWith(imagePath: 'c.jpg'),
        ]);

    final c = container();
    c.listen(outfitHistoryProvider, (_, _) {}); // keep alive (autoDispose)
    final entries = await c.read(outfitHistoryProvider.future);

    expect(entries.length, 2);
    expect(entries[0].log.id, 'l1');
    expect(entries[0].imagePaths, ['b.jpg', 'a.jpg'], reason: 'top before bottom');
    expect(entries[1].log.id, 'l2');
    expect(entries[1].imagePaths, ['c.jpg']);
  });

  test('returns empty when there is no history', () async {
    when(() => outfitLogRepo.getOutfitHistory(
          userId: any(named: 'userId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => []);

    final c = container();
    c.listen(outfitHistoryProvider, (_, _) {}); // keep alive (autoDispose)
    final entries = await c.read(outfitHistoryProvider.future);
    expect(entries, isEmpty);
  });
}
