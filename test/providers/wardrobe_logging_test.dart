import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/data/models/item_event.dart';
import 'package:rewear/data/models/outfit_log.dart';
import 'package:rewear/data/models/profile.dart';
import 'package:rewear/data/repositories/item_event_repository.dart';
import 'package:rewear/data/repositories/item_repository.dart';
import 'package:rewear/data/repositories/outfit_log_repository.dart';
import 'package:rewear/providers/profile_providers.dart';
import 'package:rewear/providers/wardrobe_providers.dart';

import '../engine/support/item_factory.dart';

class MockItemRepository extends Mock implements ItemRepository {}

class MockItemEventRepository extends Mock implements ItemEventRepository {}

class MockOutfitLogRepository extends Mock implements OutfitLogRepository {}

class _StubProfileNotifier extends ProfileNotifier {
  @override
  Future<Profile?> build() async => null;
}

final _dummyEvent = ItemEvent(
  id: 'evt',
  userId: 'user-1',
  itemId: 'item',
  eventType: EventType.skipped,
  source: ItemEventSource.dailyRotation,
  eventAt: DateTime(2026, 1, 1),
);

final _dummyLog = OutfitLog(
  id: 'log1',
  userId: 'user-1',
  source: OutfitLogSource.outfitGenerator,
  loggedAt: DateTime(2026, 1, 1),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_dummyEvent);
    registerFallbackValue(Occasion.casual);
    registerFallbackValue(OutfitLogSource.outfitGenerator);
    registerFallbackValue(<({String itemId, LayerType layerType})>[]);
  });

  late MockItemRepository itemRepo;
  late MockItemEventRepository eventRepo;
  late MockOutfitLogRepository outfitLogRepo;

  ProviderContainer makeContainer(List items) {
    when(() => itemRepo.getWardrobeItems(any()))
        .thenAnswer((_) async => items.cast());
    when(() => eventRepo.logEvent(any())).thenAnswer((_) async => _dummyEvent);
    when(() => itemRepo.updateWearStats(
          itemId: any(named: 'itemId'),
          wearCount: any(named: 'wearCount'),
          skipCount: any(named: 'skipCount'),
          wearCountUnknown: any(named: 'wearCountUnknown'),
          lastWornUnknown: any(named: 'lastWornUnknown'),
          lastWornDate: any(named: 'lastWornDate'),
        )).thenAnswer((_) async {});
    when(() => itemRepo.updateCondition(
          itemId: any(named: 'itemId'),
          condition: any(named: 'condition'),
          conditionNextDrop: any(named: 'conditionNextDrop'),
        )).thenAnswer((_) async {});
    when(() => outfitLogRepo.logOutfit(
          userId: any(named: 'userId'),
          source: any(named: 'source'),
          items: any(named: 'items'),
          occasion: any(named: 'occasion'),
          outfitScore: any(named: 'outfitScore'),
        )).thenAnswer((_) async => _dummyLog);

    when(() => itemRepo.getLaundryItems(any())).thenAnswer((_) async => []);
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      itemRepositoryProvider.overrideWithValue(itemRepo),
      itemEventRepositoryProvider.overrideWithValue(eventRepo),
      outfitLogRepositoryProvider.overrideWithValue(outfitLogRepo),
      profileProvider.overrideWith(_StubProfileNotifier.new),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    itemRepo = MockItemRepository();
    eventRepo = MockItemEventRepository();
    outfitLogRepo = MockOutfitLogRepository();
  });

  test('logSkipped writes one SKIPPED event with the given source', () async {
    final item = makeItem(id: 'i1', wearCount: 4, skipCount: 2);
    final c = makeContainer([item]);
    await c.read(wardrobeProvider.future);

    await c
        .read(wardrobeProvider.notifier)
        .logSkipped(item, source: ItemEventSource.dailyRotation);

    final event = verify(() => eventRepo.logEvent(captureAny())).captured.single
        as ItemEvent;
    expect(event.eventType, EventType.skipped);
    expect(event.source, ItemEventSource.dailyRotation);
    expect(event.itemId, 'i1');
  });

  test('logSkipped bumps only skip_count, leaving wear stats untouched',
      () async {
    final item = makeItem(
      id: 'i1',
      wearCount: 4,
      skipCount: 2,
      wearCountUnknown: false,
      lastWornUnknown: true,
    );
    final c = makeContainer([item]);
    await c.read(wardrobeProvider.future);

    await c.read(wardrobeProvider.notifier).logSkipped(item);

    // skip_count +1, wear_count unchanged, unknown flags preserved as-is,
    // last_worn_date NOT touched (null → repo omits it).
    verify(() => itemRepo.updateWearStats(
          itemId: 'i1',
          wearCount: 4,
          skipCount: 3,
          wearCountUnknown: false,
          lastWornUnknown: true,
          lastWornDate: null,
        )).called(1);
  });

  test('logSkipped never applies a condition drop', () async {
    final item = makeItem(id: 'i1', condition: 3, conditionNextDrop: 1);
    final c = makeContainer([item]);
    await c.read(wardrobeProvider.future);

    await c.read(wardrobeProvider.notifier).logSkipped(item);

    verifyNever(() => itemRepo.updateCondition(
          itemId: any(named: 'itemId'),
          condition: any(named: 'condition'),
          conditionNextDrop: any(named: 'conditionNextDrop'),
        ));
  });

  test('logSkippedItems records a SKIPPED event per item (generator source)',
      () async {
    final a = makeItem(id: 'a', skipCount: 0);
    final b = makeItem(id: 'b', skipCount: 5);
    final c = makeContainer([a, b]);
    await c.read(wardrobeProvider.future);

    await c
        .read(wardrobeProvider.notifier)
        .logSkippedItems([a, b], source: ItemEventSource.outfitGenerator);

    final events = verify(() => eventRepo.logEvent(captureAny()))
        .captured
        .cast<ItemEvent>();
    expect(events.length, 2);
    expect(events.map((e) => e.itemId), containsAll(['a', 'b']));
    expect(
      events.every((e) =>
          e.eventType == EventType.skipped &&
          e.source == ItemEventSource.outfitGenerator),
      isTrue,
    );
    verify(() => itemRepo.updateWearStats(
          itemId: 'a',
          wearCount: any(named: 'wearCount'),
          skipCount: 1,
          wearCountUnknown: any(named: 'wearCountUnknown'),
          lastWornUnknown: any(named: 'lastWornUnknown'),
          lastWornDate: null,
        )).called(1);
    verify(() => itemRepo.updateWearStats(
          itemId: 'b',
          wearCount: any(named: 'wearCount'),
          skipCount: 6,
          wearCountUnknown: any(named: 'wearCountUnknown'),
          lastWornUnknown: any(named: 'lastWornUnknown'),
          lastWornDate: null,
        )).called(1);
  });

  test('logOutfitWorn writes an outfit log + a linked WORN event per item',
      () async {
    final top = makeItem(id: 'top', category: ItemCategory.top, wearCount: 1);
    final bottom =
        makeItem(id: 'bottom', category: ItemCategory.bottom, wearCount: 4);
    final c = makeContainer([top, bottom]);
    await c.read(wardrobeProvider.future);

    await c.read(wardrobeProvider.notifier).logOutfitWorn(
      pieces: [
        (item: top, layer: LayerType.top),
        (item: bottom, layer: LayerType.bottom),
      ],
      occasion: Occasion.casual,
      outfitScore: 0.82,
    );

    // One outfit_log + its item rows, with the slot mapping preserved.
    final captured = verify(() => outfitLogRepo.logOutfit(
          userId: 'user-1',
          source: OutfitLogSource.outfitGenerator,
          items: captureAny(named: 'items'),
          occasion: Occasion.casual,
          outfitScore: 0.82,
        )).captured.single as List<({String itemId, LayerType layerType})>;
    expect(captured, [
      (itemId: 'top', layerType: LayerType.top),
      (itemId: 'bottom', layerType: LayerType.bottom),
    ]);

    // A WORN event per item, linked to the created log.
    final events = verify(() => eventRepo.logEvent(captureAny()))
        .captured
        .cast<ItemEvent>();
    expect(events.length, 2);
    expect(events.every((e) => e.eventType == EventType.worn), isTrue);
    expect(events.every((e) => e.outfitLogId == 'log1'), isTrue);

    // wear_count bumped per item; last_worn set to today (non-null).
    verify(() => itemRepo.updateWearStats(
          itemId: 'top',
          wearCount: 2,
          skipCount: any(named: 'skipCount'),
          wearCountUnknown: false,
          lastWornUnknown: false,
          lastWornDate: any(named: 'lastWornDate', that: isNotNull),
        )).called(1);
    verify(() => itemRepo.updateWearStats(
          itemId: 'bottom',
          wearCount: 5,
          skipCount: any(named: 'skipCount'),
          wearCountUnknown: false,
          lastWornUnknown: false,
          lastWornDate: any(named: 'lastWornDate', that: isNotNull),
        )).called(1);
  });
}
