import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/data/models/item_event.dart';
import 'package:rewear/data/repositories/item_event_repository.dart';
import 'package:rewear/data/repositories/item_repository.dart';
import 'package:rewear/providers/insights_providers.dart';
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

  ProviderContainer makeContainer({
    required List items,
    List<ItemEvent> events = const [],
  }) {
    when(() => itemRepo.getWardrobeItems(any()))
        .thenAnswer((_) async => items.cast());
    when(() => eventRepo.getEventsInRange(
          userId: any(named: 'userId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        )).thenAnswer((_) async => events);

    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('u'),
      itemRepositoryProvider.overrideWithValue(itemRepo),
      itemEventRepositoryProvider.overrideWithValue(eventRepo),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('insightsProvider', () {
    test('populates never-worn and long-unused attention lists', () async {
      final now = DateTime.now();
      final neverWorn = makeItem(
        id: 'a',
        wearCount: 0,
        dateAdded: now.subtract(const Duration(days: 30)),
      );
      final longUnused = makeItem(
        id: 'b',
        wearCount: 5,
        lastWornDate: now.subtract(const Duration(days: 90)),
      );
      final active = makeItem(
        id: 'c',
        wearCount: 3,
        lastWornDate: now.subtract(const Duration(days: 5)),
      );

      final c = makeContainer(items: [neverWorn, longUnused, active]);
      c.listen(insightsProvider, (_, _) {});
      final data = await c.read(insightsProvider.future);

      expect(data, isNotNull);
      expect(data!.neverWornItems.map((i) => i.id), contains('a'));
      expect(data.longUnusedItems.map((i) => i.id), contains('b'));
      expect(data.longUnusedItems.map((i) => i.id), isNot(contains('a')));
    });

    test('utilisation pct reflects worn-in-last-30d count', () async {
      final now = DateTime.now();
      final itemA = makeItem(id: 'a', wearCount: 2);
      final itemB = makeItem(id: 'b', wearCount: 0);

      final wornEvent = ItemEvent(
        id: 'e1',
        userId: 'u',
        itemId: 'a',
        eventType: EventType.worn,
        source: ItemEventSource.dailyRotation,
        eventAt: now.subtract(const Duration(days: 5)),
      );

      final c = makeContainer(items: [itemA, itemB], events: [wornEvent]);
      c.listen(insightsProvider, (_, _) {});
      final data = await c.read(insightsProvider.future);

      // 1 of 2 items worn in last 30d → 50% utilisation
      expect(data!.utilisationPct, 50);
    });

    test('rotationPct = 100 when pre-owned item has corrected usage period',
        () async {
      final now = DateTime.now();
      // 25 wears across 730+8 days → wearRate ≈ 0.034, NOT overused
      final preOwned = makeItem(
        id: 'preowned',
        wearCount: 25,
        dateAdded: now.subtract(const Duration(days: 8)),
        initialUsageAgeDays: 730,
        status: ItemStatus.inWardrobe,
      );

      final c = makeContainer(items: [preOwned]);
      c.listen(insightsProvider, (_, _) {});
      final data = await c.read(insightsProvider.future);

      expect(data, isNotNull);
      expect(
        data!.rotationPct,
        100,
        reason: 'pre-owned item not overused after formula fix',
      );
      expect(data.overusedItems, isEmpty);
    });

    test('rotationPct < 100 when recent item has high wearRate', () async {
      final now = DateTime.now();
      // 25 wears in 8 days, no prior history → wearRate = 25/8 = 3.125, overused
      final recent = makeItem(
        id: 'recent',
        wearCount: 25,
        dateAdded: now.subtract(const Duration(days: 8)),
        initialUsageAgeDays: 0,
        status: ItemStatus.inWardrobe,
      );

      final c = makeContainer(items: [recent]);
      c.listen(insightsProvider, (_, _) {});
      final data = await c.read(insightsProvider.future);

      expect(data, isNotNull);
      expect(data!.rotationPct, 0,
          reason: 'single overused item drives rotation to 0%');
      expect(data.overusedItems.map((i) => i.id), contains('recent'));
    });

    test('skippedOften includes item with skipCount=3 wearCount=1 (ratio=0.75)',
        () async {
      // skip ratio = 3/(1+3) = 0.75, which is > 0.50 threshold
      final skipped = makeItem(
        id: 'skipped',
        wearCount: 1,
        skipCount: 3,
        status: ItemStatus.inWardrobe,
      );
      // this item has skip ratio = 1/(5+1)=0.167 — below threshold, should not appear
      final notSkipped = makeItem(
        id: 'not_skipped',
        wearCount: 5,
        skipCount: 1,
        status: ItemStatus.inWardrobe,
      );

      final c = makeContainer(items: [skipped, notSkipped]);
      c.listen(insightsProvider, (_, _) {});
      final data = await c.read(insightsProvider.future);

      expect(data, isNotNull);
      expect(data!.skippedOftenItems.map((i) => i.id), contains('skipped'));
      expect(data.skippedOftenItems.map((i) => i.id),
          isNot(contains('not_skipped')));
    });

    test('returns null when no user is logged in', () async {
      final c = ProviderContainer(overrides: [
        currentUserIdProvider.overrideWithValue(null),
        itemRepositoryProvider.overrideWithValue(itemRepo),
        itemEventRepositoryProvider.overrideWithValue(eventRepo),
      ]);
      addTearDown(c.dispose);
      when(() => itemRepo.getWardrobeItems(any()))
          .thenAnswer((_) async => []);
      c.listen(insightsProvider, (_, _) {});
      final data = await c.read(insightsProvider.future);
      expect(data, isNull);
    });
  });
}
