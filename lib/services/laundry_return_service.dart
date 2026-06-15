import '../data/repositories/item_repository.dart';

/// Checks items in LAUNDRY and returns any whose cycle has completed.
///
/// Call [run] on app open (triggered via [WardrobeNotifier.build]).
/// The pure [isDue] helper is separated for unit testing without I/O.
class LaundryReturnService {
  const LaundryReturnService(this._repo);

  final ItemRepository _repo;

  /// Returns true if [started] is non-null and at least [cycleDays] have
  /// elapsed since [now]. Uses whole-day difference (calendar days).
  static bool isDue(DateTime? started, int cycleDays, DateTime now) {
    if (started == null) return false;
    final startedDay = DateTime(started.year, started.month, started.day);
    final nowDay = DateTime(now.year, now.month, now.day);
    return nowDay.difference(startedDay).inDays >= cycleDays;
  }

  /// Checks all LAUNDRY items for [userId] and returns the ones whose cycle
  /// has completed to IN_WARDROBE. Returns the number of items returned.
  Future<int> run({
    required String userId,
    required int laundryCycleDays,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final laundryItems = await _repo.getLaundryItems(userId);
    final due = laundryItems
        .where((item) => isDue(item.laundryStartedAt, laundryCycleDays, today))
        .toList();
    for (final item in due) {
      await _repo.returnFromLaundry(item.id);
    }
    return due.length;
  }
}
