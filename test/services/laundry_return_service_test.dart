import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rewear/data/models/item.dart';
import 'package:rewear/data/repositories/item_repository.dart';
import 'package:rewear/services/laundry_return_service.dart';

import '../engine/support/item_factory.dart';

class MockItemRepository extends Mock implements ItemRepository {}

void main() {
  // ── isDue — pure logic ──────────────────────────────────────────────────────

  group('LaundryReturnService.isDue', () {
    final now = DateTime(2026, 6, 14);

    test('null started → false', () {
      expect(LaundryReturnService.isDue(null, 3, now), isFalse);
    });

    test('started today (0 days elapsed), cycle 3 → false', () {
      expect(LaundryReturnService.isDue(now, 3, now), isFalse);
    });

    test('started 1 day ago, cycle 3 → false', () {
      final started = now.subtract(const Duration(days: 1));
      expect(LaundryReturnService.isDue(started, 3, now), isFalse);
    });

    test('started 2 days ago, cycle 3 → false', () {
      final started = now.subtract(const Duration(days: 2));
      expect(LaundryReturnService.isDue(started, 3, now), isFalse);
    });

    test('started exactly 3 days ago, cycle 3 → true (boundary)', () {
      final started = now.subtract(const Duration(days: 3));
      expect(LaundryReturnService.isDue(started, 3, now), isTrue);
    });

    test('started 5 days ago, cycle 3 → true', () {
      final started = now.subtract(const Duration(days: 5));
      expect(LaundryReturnService.isDue(started, 3, now), isTrue);
    });

    test('started 3 days ago, cycle 7 → false', () {
      final started = now.subtract(const Duration(days: 3));
      expect(LaundryReturnService.isDue(started, 7, now), isFalse);
    });

    test('started 7 days ago, cycle 7 → true (boundary)', () {
      final started = now.subtract(const Duration(days: 7));
      expect(LaundryReturnService.isDue(started, 7, now), isTrue);
    });

    test('time-of-day is ignored — same calendar day counts as 0 days', () {
      final startedEarly = DateTime(2026, 6, 11, 0, 0);
      final nowLate = DateTime(2026, 6, 14, 23, 59);
      // 3 days apart on calendar; cycle 3 → true
      expect(LaundryReturnService.isDue(startedEarly, 3, nowLate), isTrue);
    });
  });

  // ── run — integration with mocked repository ──────────────────────────────

  group('LaundryReturnService.run', () {
    late MockItemRepository repo;
    late LaundryReturnService service;
    final now = DateTime(2026, 6, 14);
    const userId = 'user-1';

    setUp(() {
      repo = MockItemRepository();
      service = LaundryReturnService(repo);
      when(() => repo.returnFromLaundry(any())).thenAnswer((_) async {});
    });

    Item laundryItem(String id, {DateTime? startedAt}) => makeItem(
          id: id,
          laundryStartedAt: startedAt,
        );

    test('no laundry items → returns 0, no returnFromLaundry calls', () async {
      when(() => repo.getLaundryItems(userId)).thenAnswer((_) async => []);
      final count = await service.run(
          userId: userId, laundryCycleDays: 3, now: now);
      expect(count, 0);
      verifyNever(() => repo.returnFromLaundry(any()));
    });

    test('item not yet due → returns 0', () async {
      final notDue = laundryItem('a',
          startedAt: now.subtract(const Duration(days: 1)));
      when(() => repo.getLaundryItems(userId))
          .thenAnswer((_) async => [notDue]);
      final count = await service.run(
          userId: userId, laundryCycleDays: 3, now: now);
      expect(count, 0);
      verifyNever(() => repo.returnFromLaundry(any()));
    });

    test('item exactly due (boundary) → returns 1, returnFromLaundry called',
        () async {
      final due = laundryItem('b',
          startedAt: now.subtract(const Duration(days: 3)));
      when(() => repo.getLaundryItems(userId)).thenAnswer((_) async => [due]);
      final count = await service.run(
          userId: userId, laundryCycleDays: 3, now: now);
      expect(count, 1);
      verify(() => repo.returnFromLaundry('b')).called(1);
    });

    test('2 items, 1 due → returns 1, only due item returned', () async {
      final due = laundryItem('c',
          startedAt: now.subtract(const Duration(days: 5)));
      final notDue = laundryItem('d',
          startedAt: now.subtract(const Duration(days: 1)));
      when(() => repo.getLaundryItems(userId))
          .thenAnswer((_) async => [due, notDue]);
      final count = await service.run(
          userId: userId, laundryCycleDays: 3, now: now);
      expect(count, 1);
      verify(() => repo.returnFromLaundry('c')).called(1);
      verifyNever(() => repo.returnFromLaundry('d'));
    });

    test('2 items both due → returns 2, both returned', () async {
      final due1 = laundryItem('e',
          startedAt: now.subtract(const Duration(days: 4)));
      final due2 = laundryItem('f',
          startedAt: now.subtract(const Duration(days: 7)));
      when(() => repo.getLaundryItems(userId))
          .thenAnswer((_) async => [due1, due2]);
      final count = await service.run(
          userId: userId, laundryCycleDays: 3, now: now);
      expect(count, 2);
      verify(() => repo.returnFromLaundry('e')).called(1);
      verify(() => repo.returnFromLaundry('f')).called(1);
    });

    test('item with null laundryStartedAt → not returned', () async {
      final noDate = laundryItem('g', startedAt: null);
      when(() => repo.getLaundryItems(userId))
          .thenAnswer((_) async => [noDate]);
      final count = await service.run(
          userId: userId, laundryCycleDays: 3, now: now);
      expect(count, 0);
      verifyNever(() => repo.returnFromLaundry(any()));
    });
  });
}
