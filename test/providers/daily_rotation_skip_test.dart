import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rewear/core/constants/enums.dart';
import 'package:rewear/data/models/item.dart';
import 'package:rewear/data/models/item_event.dart';
import 'package:rewear/data/repositories/item_event_repository.dart';
import 'package:rewear/providers/daily_rotation_providers.dart';
import 'package:rewear/providers/wardrobe_providers.dart';

class MockItemEventRepository extends Mock implements ItemEventRepository {}

/// Stub wardrobe so the provider's `ref.watch(wardrobeProvider)` settles
/// without hitting Supabase / laundry / notification logic.
class _StubWardrobeNotifier extends WardrobeNotifier {
  @override
  Future<List<Item>> build() async => [];
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2020));
  });

  late MockItemEventRepository eventRepo;

  ProviderContainer makeContainer(List<ItemEvent> events) {
    when(() => eventRepo.getEventsInRange(
          userId: any(named: 'userId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        )).thenAnswer((_) async => events);

    final c = ProviderContainer(overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      itemEventRepositoryProvider.overrideWithValue(eventRepo),
      wardrobeProvider.overrideWith(_StubWardrobeNotifier.new),
    ]);
    addTearDown(c.dispose);
    // Keep the autoDispose provider alive while the test awaits its future
    // (an unlistened autoDispose provider is torn down mid-loading).
    c.listen(dailyRotationSkippedTodayProvider, (_, _) {});
    return c;
  }

  ItemEvent ev(
    String itemId, {
    required EventType type,
    required ItemEventSource source,
  }) =>
      ItemEvent(
        id: 'e-$itemId',
        userId: 'user-1',
        itemId: itemId,
        eventType: type,
        source: source,
        eventAt: DateTime.now(),
      );

  setUp(() => eventRepo = MockItemEventRepository());

  test('returns only today\'s SKIPPED / DAILY_ROTATION ids; excludes '
      'OUTFIT_GENERATOR skips and WORN events', () async {
    final c = makeContainer([
      ev('keep', type: EventType.skipped, source: ItemEventSource.dailyRotation),
      ev('gen', type: EventType.skipped, source: ItemEventSource.outfitGenerator),
      ev('worn', type: EventType.worn, source: ItemEventSource.dailyRotation),
    ]);

    final result = await c.read(dailyRotationSkippedTodayProvider.future);

    expect(result, {'keep'});
    expect(result, isNot(contains('gen'))); // generator skip excluded
    expect(result, isNot(contains('worn'))); // worn event excluded
  });

  test('queries item_events scoped to today (midnight → next midnight)',
      () async {
    final c = makeContainer(const []);
    await c.read(dailyRotationSkippedTodayProvider.future);

    final captured = verify(() => eventRepo.getEventsInRange(
          userId: 'user-1',
          from: captureAny(named: 'from'),
          to: captureAny(named: 'to'),
        )).captured;
    final from = captured[0] as DateTime;
    final to = captured[1] as DateTime;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    expect(from, todayStart);
    expect(to, todayStart.add(const Duration(days: 1)));
  });

  test('empty event list → empty set', () async {
    final c = makeContainer(const []);
    expect(await c.read(dailyRotationSkippedTodayProvider.future), isEmpty);
  });
}
