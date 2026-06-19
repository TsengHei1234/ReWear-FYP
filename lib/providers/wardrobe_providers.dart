import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/enums.dart';
import '../data/models/item.dart';
import '../data/models/item_event.dart';
import '../data/repositories/item_event_repository.dart';
import '../data/repositories/item_repository.dart';
import '../data/repositories/outfit_log_repository.dart';
import '../data/repositories/storage_repository.dart';
import '../engine/condition/condition_engine.dart';
import '../engine/donation/donation_rules.dart' as donation;
import '../engine/insights/health_score.dart';
import '../services/laundry_return_service.dart';
import '../services/notification_eligibility.dart';
import '../services/notification_service.dart';
import 'auth_providers.dart';
import 'notification_settings_provider.dart';
import 'profile_providers.dart';

// ── Image URL provider ────────────────────────────────────────────────────────

/// Resolves a Supabase storage path → signed URL. Cached while in scope.
/// Returns null if [storagePath] is null (no photo uploaded yet).
///
/// ⚠️ EGRESS RULE — MUST follow in every widget that consumes this provider:
/// Supabase `createSignedUrl` produces a new URL on every call (different
/// token/signature even for the same file). Because this provider is
/// `autoDispose`, it regenerates on each rebuild after the widget tree leaves
/// scope (e.g. tab switch, navigation pop). If `CachedNetworkImage` uses the
/// URL as its cache key (the default), it will re-download the full image every
/// time. To prevent that, **always pass a versioned `cacheKey`**:
///   `item.imagePath != null ? '${item.imagePath}_v${item.updatedAt.ms}' : null`
/// Same key on URL regen → disk-cache hit, zero egress. New key after a photo
/// edit (`trg_items_updated_at` bumps `updated_at`) → cache miss → downloads
/// the new image exactly once. Applies to Phase 7 (Donate), Phase 8, and beyond.
const _itemImageUrlCacheTtl = Duration(hours: 1);

final itemImageUrlProvider = FutureProvider.autoDispose
    .family<String?, String?>((ref, storagePath) async {
      if (storagePath == null || storagePath.isEmpty) return null;

      final signedUrl = await ref
          .watch(storageRepositoryProvider)
          .getSignedUrl(storagePath);
      if (signedUrl.isEmpty) return signedUrl;

      final link = ref.keepAlive();
      Timer? cacheTimer;

      ref.onCancel(() {
        cacheTimer = Timer(_itemImageUrlCacheTtl, link.close);
      });
      ref.onResume(() {
        cacheTimer?.cancel();
        cacheTimer = null;
      });
      ref.onDispose(() {
        cacheTimer?.cancel();
      });

      return signedUrl;
    });

// ── Item events provider (wear/skip history) ──────────────────────────────────

/// All WORN/SKIPPED events for [itemId], newest first.
/// Re-fetches whenever the wardrobe is invalidated (e.g. after a Log Wear).
final itemEventsProvider = FutureProvider.autoDispose
    .family<List<ItemEvent>, String>((ref, itemId) async {
      ref.watch(wardrobeProvider); // refresh after a log/edit
      return ref.read(itemEventRepositoryProvider).getEventsForItem(itemId);
    });

// ── Repository providers ──────────────────────────────────────────────────────

final storageRepositoryProvider = Provider<StorageRepository>(
  (ref) => StorageRepository(),
);

final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => ItemRepository(storage: ref.watch(storageRepositoryProvider)),
);

final itemEventRepositoryProvider = Provider<ItemEventRepository>(
  (ref) => ItemEventRepository(),
);

final outfitLogRepositoryProvider = Provider<OutfitLogRepository>(
  (ref) => OutfitLogRepository(),
);

// ── Convenience: current user id ─────────────────────────────────────────────

/// The currently signed-in user's UUID, or null when logged out.
/// Re-evaluates whenever auth state changes.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider); // rebuild on auth change
  return ref.watch(authRepositoryProvider).currentUser?.id;
});

// ── Wardrobe provider ─────────────────────────────────────────────────────────

/// Loads all visible wardrobe items for the signed-in user and holds them in
/// memory. Stays cached across navigation; re-fetches only after mutations.
///
/// Invalidation rules (Rule Engine "Data Sync Strategy"):
///   addItem / editItem / deleteItem / updateItemStatus / logWorn / logSkipped
///   → invalidate WardrobeProvider (self) + InsightsProvider + DonationProvider
///     + OutfitGeneratorProvider.
///   confirmDonation / setKeptUntil → same set minus OutfitGeneratorProvider.
///
/// Note: InsightsProvider, DonationProvider, OutfitGeneratorProvider are
/// defined in their own files (Phases 5–7). This notifier calls
/// ref.invalidateSelf() and callers are responsible for invalidating the other
/// providers after each mutation (see Phase 4 feature controllers).
final wardrobeProvider = AsyncNotifierProvider<WardrobeNotifier, List<Item>>(
  WardrobeNotifier.new,
);

class WardrobeNotifier extends AsyncNotifier<List<Item>> {
  /// Guard: app-open notification check fires only once per notifier lifetime
  /// (i.e., once per app session). Subsequent [build] calls from invalidateSelf
  /// after mutations skip the check to avoid repeat notifications.
  bool _sessionChecked = false;

  /// The calendar date (time stripped) of the most recent laundry check.
  /// Set by [build] on cold start and by [checkLaundryOnResume] on resume.
  /// Same-day resumes compare against this to skip redundant DB calls.
  DateTime? _lastLaundryCheckDate;

  @override
  Future<List<Item>> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return [];

    // Auto-return any LAUNDRY items whose cycle has completed before loading.
    final profile = await ref.read(profileProvider.future);
    final cycleDays = profile?.laundryCycleDays ?? 3;
    await LaundryReturnService(ref.read(itemRepositoryProvider))
        .run(userId: userId, laundryCycleDays: cycleDays);

    // Record today so on-resume checks can skip same-day re-runs.
    final buildNow = DateTime.now();
    _lastLaundryCheckDate =
        DateTime(buildNow.year, buildNow.month, buildNow.day);

    final items =
        await ref.read(itemRepositoryProvider).getWardrobeItems(userId);

    if (!_sessionChecked) {
      _sessionChecked = true;
      await _checkNotificationsOnOpen(items);
    }

    return items;
  }

  /// Called on app resume ([AppLifecycleListener.onResume] in [MainShell]).
  /// Only runs the laundry check if the calendar date has changed since the
  /// last check — same-day resumes return immediately with zero DB calls.
  /// Invalidates only if items were actually returned from laundry.
  Future<void> checkLaundryOnResume() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    if (_lastLaundryCheckDate == todayDate) return;

    final profile = await ref.read(profileProvider.future);
    final cycleDays = profile?.laundryCycleDays ?? 3;
    final returned =
        await LaundryReturnService(ref.read(itemRepositoryProvider))
            .run(userId: userId, laundryCycleDays: cycleDays);

    _lastLaundryCheckDate = todayDate;

    if (returned > 0) ref.invalidateSelf();
  }

  Future<void> _checkNotificationsOnOpen(List<Item> items) async {
    final ns = NotificationService.instance;
    // Skip in test environments where initialize() was never called.
    if (!ns.isInitialized) return;
    final now = DateTime.now();

    // daysSinceLastLog: whole calendar days since most-recent known worn date.
    final todayDate = DateTime(now.year, now.month, now.day);
    DateTime? latestWorn;
    for (final item in items) {
      if (item.lastWornDate != null && !item.lastWornUnknown) {
        if (latestWorn == null || item.lastWornDate!.isAfter(latestWorn)) {
          latestWorn = item.lastWornDate;
        }
      }
    }
    final daysSinceLastLog = latestWorn == null
        ? 0
        : todayDate
            .difference(DateTime(
                latestWorn.year, latestWorn.month, latestWorn.day))
            .inDays;

    final longUnwornCount = items.where((i) => isLongUnused(i, now: now)).length;
    final donationCandidates =
        items.where((i) => donation.isDonationCandidate(i, now: now)).length;

    final toggles = await ref.read(notificationSettingsProvider.future);
    final lastN3 = await ns.getLastN3FiredAt();
    final lastN4 = await ns.getLastN4FiredAt();

    final result = NotificationEligibility.evaluate(
      daysSinceLastLog: daysSinceLastLog,
      longUnwornCount: longUnwornCount,
      donationCandidates: donationCandidates,
      conditionDropped: false,
      isAutoConditionMode: false,
      toggles: toggles,
      lastN3FiredAt: lastN3,
      lastN4FiredAt: lastN4,
      now: now,
    );

    if (result.n1) await ns.showN1();
    if (result.n2) await ns.showN2();
    if (result.n3) {
      await ns.showN3(longUnwornCount);
      await ns.recordN3Fired();
    }
    if (result.n4) {
      await ns.showN4(donationCandidates);
      await ns.recordN4Fired();
    }

    // N5: refresh the weekly scheduled summary with current stats.
    if (toggles.n5) {
      final active =
          items.where((i) => i.status == ItemStatus.inWardrobe).toList();
      final cutoff = now.subtract(const Duration(days: 30));
      final wornInLast30 = active
          .where((i) =>
              i.lastWornDate != null &&
              !i.lastWornUnknown &&
              i.lastWornDate!.isAfter(cutoff))
          .length;
      await ns.scheduleN5Weekly(
        wornInLast30: wornInLast30,
        dormant: active.length - wornInLast30,
        forDonationReview: donationCandidates,
        totalItems: active.length,
      );
    } else {
      await ns.cancelN5();
    }
  }

  // ── Mutations (wait for Supabase → confirm → update UI) ─────────────────

  /// Insert a new item. Invalidates self (+ caller must invalidate Insights,
  /// OutfitGenerator per spec).
  Future<Item> addItem({required Item item, File? photo}) async {
    final userId = ref.read(currentUserIdProvider)!;
    final repo = ref.read(itemRepositoryProvider);
    final created = await repo.addItem(
      userId: userId,
      item: item,
      photo: photo,
    );
    ref.invalidateSelf();
    return created;
  }

  /// Update an existing item. Replaces the item in local state with the
  /// DB-confirmed version (no full re-fetch). Image cache refresh is handled
  /// automatically by the versioned cacheKey in each widget
  /// (`imagePath_v{updatedAt.ms}`): the DB trigger updates `updated_at` on
  /// every save, so the new key is always a cache miss after a photo change.
  /// Caller must still invalidate Insights, Donation, OutfitGenerator.
  Future<Item> editItem({required Item item, File? photo}) async {
    final repo = ref.read(itemRepositoryProvider);
    final updated = await repo.updateItem(item: item, photo: photo);
    final currentItems = state.asData?.value;
    if (currentItems != null) {
      state = AsyncData([
        for (final existing in currentItems)
          existing.id == updated.id ? updated : existing,
      ]);
    }
    return updated;
  }

  /// Quick "Log Wear": records a WORN event, bumps wear_count + last_worn_date,
  /// clears the unknown flags, and applies AUTO condition drop if the threshold
  /// is crossed. Source defaults to ITEM_DETAIL (the card/detail quick action).
  /// Phase 6 reuses this for the Daily Rotation / Generator log flows.
  Future<void> logWorn(
    Item item, {
    Occasion? occasion,
    ItemEventSource source = ItemEventSource.itemDetail,
  }) async {
    final userId = ref.read(currentUserIdProvider)!;
    final eventRepo = ref.read(itemEventRepositoryProvider);
    final itemRepo = ref.read(itemRepositoryProvider);
    final today = DateTime.now();

    // 1. Log the WORN event.
    await eventRepo.logEvent(
      ItemEvent(
        id: '',
        userId: userId,
        itemId: item.id,
        eventType: EventType.worn,
        source: source,
        occasion: occasion,
        eventAt: today,
      ),
    );

    // 2. Update wear stats (a real wear clears the "unknown" estimates).
    final newWearCount = item.wearCount + 1;
    await itemRepo.updateWearStats(
      itemId: item.id,
      wearCount: newWearCount,
      skipCount: item.skipCount,
      wearCountUnknown: false,
      lastWornUnknown: false,
      lastWornDate: today,
    );

    // 3. AUTO condition drop if the new wear_count crosses condition_next_drop.
    final probe = item.copyWith(
      wearCount: newWearCount,
      lastWornDate: today,
      wearCountUnknown: false,
      lastWornUnknown: false,
    );
    final dropped = checkAutoConditionDrop(probe);
    final conditionChanged = dropped.condition != item.condition ||
        dropped.conditionNextDrop != item.conditionNextDrop;
    if (conditionChanged) {
      await itemRepo.updateCondition(
        itemId: item.id,
        condition: dropped.condition,
        conditionNextDrop: dropped.conditionNextDrop,
      );
    }

    // N6: notify if condition dropped in AUTO mode, toggle enabled, and plugin
    // initialized (guard skips this in test environments).
    if (conditionChanged &&
        dropped.condition < item.condition &&
        NotificationService.instance.isInitialized) {
      final toggles = await ref.read(notificationSettingsProvider.future);
      if (toggles.n6 &&
          item.conditionReviewMode == ConditionReviewMode.auto) {
        await NotificationService.instance.showN6(
          item.id,
          item.name,
          conditionLabel(dropped.condition),
        );
      }
    }

    ref.invalidateSelf();
  }

  /// Quick "Skip": records a SKIPPED event and bumps skip_count only
  /// (RE "Daily Rotation — Actions": skip_count += 1, insert item_events row).
  /// Unlike [logWorn] it does NOT touch last_worn_date, the unknown flags, or
  /// condition. Source defaults to DAILY_ROTATION (the rotation card action).
  ///
  /// Per the Data Sync Strategy, a Daily-Rotation skip clears the generator
  /// session (default invalidation). The Outfit Generator's own skip uses
  /// [logSkippedItems] so its session is preserved (see OutfitGeneratorNotifier).
  Future<void> logSkipped(
    Item item, {
    Occasion? occasion,
    ItemEventSource source = ItemEventSource.dailyRotation,
  }) async {
    await _writeSkip(item, occasion: occasion, source: source);
    ref.invalidateSelf();
  }

  /// Batch skip used by the Outfit Generator (skip item = 1, skip outfit = N).
  /// Writes every SKIPPED event + skip_count bump, then invalidates ONCE so the
  /// generator session sees a single wardrobe refresh (and can preserve itself).
  Future<void> logSkippedItems(
    List<Item> items, {
    Occasion? occasion,
    ItemEventSource source = ItemEventSource.outfitGenerator,
  }) async {
    for (final item in items) {
      await _writeSkip(item, occasion: occasion, source: source);
    }
    ref.invalidateSelf();
  }

  /// Persist a single SKIPPED event + skip_count bump. Does NOT invalidate
  /// (callers decide when to refresh — once per user action).
  Future<void> _writeSkip(
    Item item, {
    Occasion? occasion,
    required ItemEventSource source,
  }) async {
    final userId = ref.read(currentUserIdProvider)!;
    await ref
        .read(itemEventRepositoryProvider)
        .logEvent(
          ItemEvent(
            id: '',
            userId: userId,
            itemId: item.id,
            eventType: EventType.skipped,
            source: source,
            occasion: occasion,
            eventAt: DateTime.now(),
          ),
        );
    await ref
        .read(itemRepositoryProvider)
        .updateWearStats(
          itemId: item.id,
          wearCount: item.wearCount,
          skipCount: item.skipCount + 1,
          wearCountUnknown: item.wearCountUnknown,
          lastWornUnknown: item.lastWornUnknown,
          lastWornDate: null, // a skip never updates recency
        );
  }

  /// Log a whole outfit as worn (Outfit Detail "Log Outfit"). Writes one
  /// `outfit_logs` row + its `outfit_log_items`, then a WORN `item_events` row
  /// per item (linked via outfit_log_id) + the same wear-stat / AUTO-condition
  /// updates as [logWorn]. Invalidates ONCE. Per G2, the worn items drop out of
  /// today's recommendations. [pieces] pairs each item with its outfit slot.
  Future<void> logOutfitWorn({
    required List<({Item item, LayerType layer})> pieces,
    Occasion? occasion,
    double? outfitScore,
  }) async {
    final userId = ref.read(currentUserIdProvider)!;
    final outfitLogRepo = ref.read(outfitLogRepositoryProvider);
    final eventRepo = ref.read(itemEventRepositoryProvider);
    final itemRepo = ref.read(itemRepositoryProvider);
    final today = DateTime.now();

    // 1. Outfit log + its item rows (one round-trip).
    final log = await outfitLogRepo.logOutfit(
      userId: userId,
      source: OutfitLogSource.outfitGenerator,
      items: [for (final p in pieces) (itemId: p.item.id, layerType: p.layer)],
      occasion: occasion,
      outfitScore: outfitScore,
    );

    // 2. Per item: linked WORN event + wear stats + AUTO condition drop.
    for (final p in pieces) {
      final item = p.item;
      await eventRepo.logEvent(
        ItemEvent(
          id: '',
          userId: userId,
          itemId: item.id,
          eventType: EventType.worn,
          source: ItemEventSource.outfitGenerator,
          occasion: occasion,
          outfitLogId: log.id,
          eventAt: today,
        ),
      );

      final newWearCount = item.wearCount + 1;
      await itemRepo.updateWearStats(
        itemId: item.id,
        wearCount: newWearCount,
        skipCount: item.skipCount,
        wearCountUnknown: false,
        lastWornUnknown: false,
        lastWornDate: today,
      );

      final probe = item.copyWith(
        wearCount: newWearCount,
        lastWornDate: today,
        wearCountUnknown: false,
        lastWornUnknown: false,
      );
      final dropped = checkAutoConditionDrop(probe);
      final conditionChanged = dropped.condition != item.condition ||
          dropped.conditionNextDrop != item.conditionNextDrop;
      if (conditionChanged) {
        await itemRepo.updateCondition(
          itemId: item.id,
          condition: dropped.condition,
          conditionNextDrop: dropped.conditionNextDrop,
        );
      }

      // N6: notify if condition dropped in AUTO mode (same guard as logWorn).
      if (conditionChanged &&
          dropped.condition < item.condition &&
          NotificationService.instance.isInitialized) {
        final toggles = await ref.read(notificationSettingsProvider.future);
        if (toggles.n6 &&
            item.conditionReviewMode == ConditionReviewMode.auto) {
          await NotificationService.instance.showN6(
            item.id,
            item.name,
            conditionLabel(dropped.condition),
          );
        }
      }
    }

    ref.invalidateSelf();
  }

  /// Soft-delete an item (status = DELETED).  Invalidates self (+ caller:
  /// Insights, Donation, OutfitGenerator).
  Future<void> deleteItem(String itemId) async {
    await ref.read(itemRepositoryProvider).deleteItem(itemId);
    ref.invalidateSelf();
  }

  /// Change item status (e.g. LAUNDRY, LENT, STORED, IN_WARDROBE).
  /// Automatically sets laundry_started_at = now when status == LAUNDRY,
  /// and clears it to null for all other statuses. Invalidates self.
  Future<void> updateItemStatus({
    required String itemId,
    required ItemStatus status,
  }) async {
    await ref
        .read(itemRepositoryProvider)
        .updateStatus(
          itemId: itemId,
          status: status,
          laundryStartedAt:
              status == ItemStatus.laundry ? DateTime.now() : null,
        );
    ref.invalidateSelf();
  }

  /// Confirm donation (status = DONATED, donated_at = today).
  /// Invalidates self (+ caller: Insights, Donation, OutfitGenerator).
  Future<void> confirmDonation(String itemId) async {
    await ref.read(itemRepositoryProvider).confirmDonation(itemId);
    ref.invalidateSelf();
  }

  /// Keep item until [keptUntil] (donation deferred).
  /// Invalidates self (+ caller: Insights, Donation).
  Future<void> setKeptUntil({
    required String itemId,
    required DateTime keptUntil,
  }) async {
    await ref
        .read(itemRepositoryProvider)
        .setKeptUntil(itemId: itemId, keptUntil: keptUntil);
    ref.invalidateSelf();
  }

  /// Undo Keep — clears [kept_until] and returns the item to donation candidates.
  /// Invalidates self (+ caller: Insights, Donation).
  Future<void> clearKeptUntil(String itemId) async {
    await ref.read(itemRepositoryProvider).clearKeptUntil(itemId);
    ref.invalidateSelf();
  }

  /// Force a fresh fetch from Supabase (e.g. after laundry auto-return).
  void invalidate() => ref.invalidateSelf();
}
