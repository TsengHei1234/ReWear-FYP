import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/data/repositories/item_event_repository.dart';
import 'package:rewear/data/repositories/item_repository.dart';
import 'package:rewear/providers/donation_providers.dart';
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

  ProviderContainer makeContainer(List items) {
    when(() => itemRepo.getWardrobeItems(any()))
        .thenAnswer((_) async => items.cast());
    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('u'),
      itemRepositoryProvider.overrideWithValue(itemRepo),
      itemEventRepositoryProvider.overrideWithValue(eventRepo),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  group('donationCandidatesProvider', () {
    test('returns D1 + D2 candidates, excludes kept item', () async {
      final now = DateTime.now();
      final d1Item = makeItem(
        id: 'a',
        wearCount: 5,
        lastWornDate: now.subtract(const Duration(days: 100)),
      );
      final d2Item = makeItem(
        id: 'b',
        wearCount: 0,
        dateAdded: now.subtract(const Duration(days: 100)),
        isNewItem: false,
      );
      final keptItem = makeItem(
        id: 'c',
        wearCount: 5,
        lastWornDate: now.subtract(const Duration(days: 100)),
        keptUntil: now.add(const Duration(days: 30)),
      );

      final c = makeContainer([d1Item, d2Item, keptItem]);
      c.listen(donationCandidatesProvider, (_, _) {});
      final candidates = await c.read(donationCandidatesProvider.future);

      expect(candidates.length, 2, reason: 'kept item suppressed');
      expect(candidates.every((e) => e.assessment.isCandidate), isTrue);
    });

    test('candidates sorted by DPS descending', () async {
      final now = DateTime.now();
      // Item with condition=1 (D4) and long unused → very high DPS
      final highDps = makeItem(
        id: 'high',
        wearCount: 1,
        condition: 1,
        lastWornDate: now.subtract(const Duration(days: 300)),
      );
      // Item with D2 only and recent add → lower DPS
      final lowDps = makeItem(
        id: 'low',
        wearCount: 0,
        dateAdded: now.subtract(const Duration(days: 100)),
        isNewItem: false,
        condition: 5,
      );

      final c = makeContainer([lowDps, highDps]);
      c.listen(donationCandidatesProvider, (_, _) {});
      final candidates = await c.read(donationCandidatesProvider.future);

      expect(candidates.first.item.id, 'high');
    });

    test('returns empty list when no items qualify', () async {
      // Recent item, never worn but added < 90 days ago → no D-rules fire.
      final recentItem = makeItem(
        id: 'x',
        wearCount: 0,
        dateAdded: DateTime.now().subtract(const Duration(days: 10)),
      );
      final c = makeContainer([recentItem]);
      c.listen(donationCandidatesProvider, (_, _) {});
      final candidates = await c.read(donationCandidatesProvider.future);
      expect(candidates, isEmpty);
    });
  });

  group('keptItemsProvider', () {
    test('returns only items with future kept_until', () async {
      final now = DateTime.now();
      final kept = makeItem(
          id: 'kept', keptUntil: now.add(const Duration(days: 30)));
      final expired = makeItem(
          id: 'exp', keptUntil: now.subtract(const Duration(days: 1)));
      final plain = makeItem(id: 'plain');

      final c = makeContainer([kept, expired, plain]);
      c.listen(keptItemsProvider, (_, _) {});
      final items = await c.read(keptItemsProvider.future);

      expect(items.map((i) => i.id).toList(), ['kept']);
    });
  });

  group('keptItemsPageProvider', () {
    test('returns kept items from repository sorted soonest first', () async {
      final now = DateTime.now();
      final soon =
          makeItem(id: 'soon', keptUntil: now.add(const Duration(days: 7)));
      final later =
          makeItem(id: 'later', keptUntil: now.add(const Duration(days: 90)));

      when(() => itemRepo.getKeptItems(any()))
          .thenAnswer((_) async => [later, soon]); // deliberately out of order

      final c = ProviderContainer(overrides: [
        currentUserIdProvider.overrideWithValue('u'),
        itemRepositoryProvider.overrideWithValue(itemRepo),
        itemEventRepositoryProvider.overrideWithValue(eventRepo),
      ]);
      addTearDown(c.dispose);
      // wardrobeProvider also calls getWardrobeItems, so stub it
      when(() => itemRepo.getWardrobeItems(any()))
          .thenAnswer((_) async => [soon, later]);
      c.listen(keptItemsPageProvider, (_, _) {});
      final items = await c.read(keptItemsPageProvider.future);

      expect(items.map((i) => i.id).toList(), ['soon', 'later'],
          reason: 'soonest-returning first');
    });

    test('returns empty list when no user logged in', () async {
      final c = ProviderContainer(overrides: [
        currentUserIdProvider.overrideWithValue(null),
        itemRepositoryProvider.overrideWithValue(itemRepo),
        itemEventRepositoryProvider.overrideWithValue(eventRepo),
      ]);
      addTearDown(c.dispose);
      when(() => itemRepo.getWardrobeItems(any()))
          .thenAnswer((_) async => []);
      c.listen(keptItemsPageProvider, (_, _) {});
      final items = await c.read(keptItemsPageProvider.future);
      expect(items, isEmpty);
    });
  });

  group('donationHistoryProvider', () {
    test('returns donated items from repository', () async {
      final donated = makeItem(
        id: 'donated',
        status: ItemStatus.donated,
        donatedAt: DateTime(2026, 5, 1),
      );
      when(() => itemRepo.getDonatedItems(any()))
          .thenAnswer((_) async => [donated]);
      // wardrobeProvider itself only returns non-donated items
      when(() => itemRepo.getWardrobeItems(any()))
          .thenAnswer((_) async => []);

      final c = ProviderContainer(overrides: [
        currentUserIdProvider.overrideWithValue('u'),
        itemRepositoryProvider.overrideWithValue(itemRepo),
        itemEventRepositoryProvider.overrideWithValue(eventRepo),
      ]);
      addTearDown(c.dispose);
      c.listen(donationHistoryProvider, (_, _) {});
      final history = await c.read(donationHistoryProvider.future);

      expect(history.length, 1);
      expect(history.first.id, 'donated');
    });
  });
}
