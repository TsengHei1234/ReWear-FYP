import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/data/models/item.dart';
import 'package:rewear/data/models/item_event.dart';
import 'package:rewear/data/models/profile.dart';
import 'package:rewear/data/repositories/item_event_repository.dart';
import 'package:rewear/data/repositories/item_repository.dart';
import 'package:rewear/data/repositories/profile_repository.dart';
import 'package:rewear/providers/auth_providers.dart';
import 'package:rewear/providers/outfit_generator_provider.dart';
import 'package:rewear/providers/profile_providers.dart';
import 'package:rewear/providers/wardrobe_providers.dart';

import '../engine/support/item_factory.dart';

class MockItemRepository extends Mock implements ItemRepository {}

class MockItemEventRepository extends Mock implements ItemEventRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

final _dummyEvent = ItemEvent(
  id: 'evt',
  userId: 'user-1',
  itemId: 'item',
  eventType: EventType.skipped,
  source: ItemEventSource.outfitGenerator,
  eventAt: DateTime(2026, 1, 1),
);

Item _top(String id, {int daysAgo = 10}) => makeItem(
      id: id,
      category: ItemCategory.top,
      type: 'T_SHIRT',
      formalityLevel: 2,
      colorTags: const ['white'],
      occasionTags: const [Occasion.casual],
      condition: 4,
      isNewItem: false,
      wearCount: 3,
      lastWornDate: DateTime(2026, 6, 1).subtract(Duration(days: daysAgo)),
      dateAdded: DateTime(2026, 6, 1).subtract(const Duration(days: 100)),
    );

Item _bottom(String id, {int daysAgo = 10}) => makeItem(
      id: id,
      category: ItemCategory.bottom,
      type: 'JEANS',
      formalityLevel: 2,
      colorTags: const ['navy'],
      occasionTags: const [Occasion.casual],
      condition: 4,
      isNewItem: false,
      wearCount: 3,
      lastWornDate: DateTime(2026, 6, 1).subtract(Duration(days: daysAgo)),
      dateAdded: DateTime(2026, 6, 1).subtract(const Duration(days: 100)),
    );

void main() {
  setUpAll(() => registerFallbackValue(_dummyEvent));

  late MockItemRepository itemRepo;
  late MockItemEventRepository eventRepo;
  late MockProfileRepository profileRepo;

  final wardrobe = [
    _top('t1', daysAgo: 30),
    _top('t2', daysAgo: 20),
    _top('t3', daysAgo: 10),
    _bottom('b1', daysAgo: 30),
    _bottom('b2', daysAgo: 20),
    _bottom('b3', daysAgo: 10),
  ];

  Future<ProviderContainer> makeContainer() async {
    when(() => itemRepo.getWardrobeItems(any()))
        .thenAnswer((_) async => wardrobe);
    when(() => itemRepo.getLaundryItems(any())).thenAnswer((_) async => []);
    when(() => profileRepo.getProfile(any())).thenAnswer(
        (_) async => const Profile(id: 'user-1'));
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

    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      itemRepositoryProvider.overrideWithValue(itemRepo),
      itemEventRepositoryProvider.overrideWithValue(eventRepo),
      profileRepositoryProvider.overrideWithValue(profileRepo),
    ]);
    addTearDown(c.dispose);
    // Warm the watched providers so the generator builds against settled data.
    await c.read(wardrobeProvider.future);
    await c.read(profileProvider.future);
    return c;
  }

  setUp(() {
    itemRepo = MockItemRepository();
    eventRepo = MockItemEventRepository();
    profileRepo = MockProfileRepository();
  });

  test('generate() produces outfits and marks the session generated', () async {
    final c = await makeContainer();
    final notifier = c.read(outfitGeneratorProvider.notifier);

    notifier.setOccasion(Occasion.casual);
    notifier.generate();

    final state = c.read(outfitGeneratorProvider);
    expect(state.hasGenerated, isTrue);
    expect(state.outfits, isNotEmpty);
  });

  test('a real wardrobe mutation resets the session AND clears the pin (G1)',
      () async {
    final c = await makeContainer();
    final notifier = c.read(outfitGeneratorProvider.notifier);
    final topItem = wardrobe.firstWhere((i) => i.category == ItemCategory.top);
    notifier.setOccasion(Occasion.casual);
    notifier.setPinnedItem(topItem);
    notifier.generate();
    expect(c.read(outfitGeneratorProvider).hasGenerated, isTrue);
    expect(c.read(outfitGeneratorProvider).pinnedItem, isNotNull);

    // Someone logs a wear elsewhere → wardrobe invalidates → reset + clear pin.
    await c.read(wardrobeProvider.notifier).logWorn(wardrobe.first);
    await c.read(wardrobeProvider.future);

    final state = c.read(outfitGeneratorProvider);
    expect(state.hasGenerated, isFalse);
    expect(state.outfits, isEmpty);
    expect(state.pinnedItem, isNull);
  });

  test('the generator\'s own skip preserves the session and the pin (G1)',
      () async {
    final c = await makeContainer();
    final notifier = c.read(outfitGeneratorProvider.notifier);
    final topItem = wardrobe.firstWhere((i) => i.category == ItemCategory.top);
    notifier.setOccasion(Occasion.casual);
    notifier.setPinnedItem(topItem);
    notifier.generate();
    expect(c.read(outfitGeneratorProvider).hasGenerated, isTrue);

    // Skip a shown (non-pinned) bottom → skip_count synced, session+pin kept.
    final skipped = c.read(outfitGeneratorProvider).outfits.first.outfit.bottom;
    await notifier.skip([skipped]);
    await c.read(wardrobeProvider.future);

    final state = c.read(outfitGeneratorProvider);
    expect(state.hasGenerated, isTrue, reason: 'session must survive a skip');
    expect(state.outfits, isNotEmpty);
    expect(state.pinnedItem, isNotNull, reason: 'pin must survive a skip');
    expect(
      state.outfits.any((o) => o.outfit.itemIds.contains(skipped.id)),
      isFalse,
    );
  });

  test('changing occasion does NOT reset the session — staged until regenerate '
      '(G1)', () async {
    final c = await makeContainer();
    final notifier = c.read(outfitGeneratorProvider.notifier);
    notifier.setOccasion(Occasion.casual);
    notifier.generate();
    final before = c.read(outfitGeneratorProvider).outfits;
    expect(before, isNotEmpty);

    notifier.setOccasion(Occasion.work);
    final state = c.read(outfitGeneratorProvider);
    expect(state.hasGenerated, isTrue, reason: 'outfits stay until Regenerate');
    expect(state.outfits, same(before));
    expect(state.occasion, Occasion.work);
  });

  test('staged occasion: cards keep generatedOccasion until Regenerate (G1)',
      () async {
    final c = await makeContainer();
    final notifier = c.read(outfitGeneratorProvider.notifier);
    final topItem = wardrobe.firstWhere((i) => i.category == ItemCategory.top);
    notifier.setOccasion(Occasion.casual);
    notifier.setPinnedItem(topItem);
    notifier.generate();
    final before = c.read(outfitGeneratorProvider).outfits;
    expect(c.read(outfitGeneratorProvider).generatedOccasion, Occasion.casual);

    // Stage a new occasion → the chip selection updates but the shown cards
    // (their generatedOccasion + contents) stay put.
    notifier.setOccasion(Occasion.work);
    final staged = c.read(outfitGeneratorProvider);
    expect(staged.occasion, Occasion.work);
    expect(staged.generatedOccasion, Occasion.casual,
        reason: 'cards must not relabel until Regenerate');
    expect(staged.outfits, same(before));

    // Regenerate applies the staged occasion to the generated set.
    notifier.regenerate();
    expect(c.read(outfitGeneratorProvider).generatedOccasion, Occasion.work);
  });

  test('regenerate keeps the pin and produces a fresh result (G1)', () async {
    final c = await makeContainer();
    final notifier = c.read(outfitGeneratorProvider.notifier);
    final topItem = wardrobe.firstWhere((i) => i.category == ItemCategory.top);
    notifier.setOccasion(Occasion.casual);
    notifier.setPinnedItem(topItem);
    notifier.generate();
    expect(c.read(outfitGeneratorProvider).hasGenerated, isTrue);

    notifier.regenerate();
    final state = c.read(outfitGeneratorProvider);
    expect(state.hasGenerated, isTrue);
    expect(state.outfits, isNotEmpty);
    expect(state.pinnedItem, topItem, reason: 'regenerate keeps the pin');
  });

  test('clearing the pin resets the session (G1)', () async {
    final c = await makeContainer();
    final notifier = c.read(outfitGeneratorProvider.notifier);
    final topItem = wardrobe.firstWhere((i) => i.category == ItemCategory.top);
    notifier.setOccasion(Occasion.casual);
    notifier.setPinnedItem(topItem);
    notifier.generate();
    expect(c.read(outfitGeneratorProvider).hasGenerated, isTrue);

    notifier.clearPin();
    final state = c.read(outfitGeneratorProvider);
    expect(state.hasGenerated, isFalse);
    expect(state.outfits, isEmpty);
    expect(state.pinnedItem, isNull);
  });

  test('setPinnedItem constrains occasion to the pin and locks its layer (G1)',
      () async {
    final c = await makeContainer();
    final notifier = c.read(outfitGeneratorProvider.notifier);
    notifier.setOccasion(Occasion.casual);

    // Jacket supports only WORK → occasion must snap to work; its own layer on.
    final jacket = makeItem(
      id: 'jacket',
      category: ItemCategory.outerwear,
      type: 'JACKET',
      occasionTags: const [Occasion.work],
    );
    notifier.setPinnedItem(jacket);

    final state = c.read(outfitGeneratorProvider);
    expect(state.occasion, Occasion.work);
    expect(state.requireOuterwear, isTrue);
    expect(state.pinnedItem, jacket);
  });

  test('clearGenerated clears results, keeps filters, does NOT regenerate (G1)',
      () async {
    final c = await makeContainer();
    final notifier = c.read(outfitGeneratorProvider.notifier);
    notifier.setOccasion(Occasion.work);
    notifier.generate();
    expect(c.read(outfitGeneratorProvider).hasGenerated, isTrue);

    notifier.clearGenerated();
    final state = c.read(outfitGeneratorProvider);
    expect(state.hasGenerated, isFalse);
    expect(state.outfits, isEmpty);
    expect(state.occasion, Occasion.work, reason: 'filter is kept');
  });
}
