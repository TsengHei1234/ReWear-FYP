import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/data/models/item_event.dart';
import 'package:rewear/data/repositories/item_event_repository.dart';
import 'package:rewear/data/repositories/item_repository.dart';
import 'package:rewear/providers/home_providers.dart';
import 'package:rewear/providers/wardrobe_providers.dart';

import '../engine/support/item_factory.dart';

class MockItemRepository extends Mock implements ItemRepository {}

class MockItemEventRepository extends Mock implements ItemEventRepository {}

void main() {
  late MockItemRepository itemRepo;
  late MockItemEventRepository eventRepo;

  setUp(() {
    itemRepo = MockItemRepository();
    eventRepo = MockItemEventRepository();
  });

  test('computes quick stats from the wardrobe + last-30d worn events',
      () async {
    final now = DateTime.now();
    final wornRecently = makeItem(id: 'a', wearCount: 3);
    final neverWorn = makeItem(id: 'b', wearCount: 0);

    when(() => itemRepo.getWardrobeItems(any()))
        .thenAnswer((_) async => [wornRecently, neverWorn]);
    when(() => eventRepo.getEventsInRange(
          userId: any(named: 'userId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        )).thenAnswer((_) async => [
          ItemEvent(
            id: 'e1',
            userId: 'u',
            itemId: 'a',
            eventType: EventType.worn,
            source: ItemEventSource.dailyRotation,
            eventAt: now.subtract(const Duration(days: 2)),
          ),
        ]);

    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('u'),
      itemRepositoryProvider.overrideWithValue(itemRepo),
      itemEventRepositoryProvider.overrideWithValue(eventRepo),
    ]);
    addTearDown(c.dispose);
    c.listen(homeSnapshotProvider, (_, _) {}); // keep alive (autoDispose)

    final stats = await c.read(homeSnapshotProvider.future);

    expect(stats, isNotNull);
    expect(stats!.totalItems, 2);
    expect(stats.wornThisMonth, 1, reason: 'item a worn in last 30 days');
    expect(stats.neverWorn, 1, reason: 'item b never worn');
  });
}
