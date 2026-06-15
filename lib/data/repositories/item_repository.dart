import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/enums.dart';
import '../../core/supabase/supabase_client.dart';
import '../models/item.dart';
import 'storage_repository.dart';

/// CRUD + photo upload for the `items` table (Database §4).
class ItemRepository {
  ItemRepository({StorageRepository? storage})
      : _storage = storage ?? StorageRepository();

  final StorageRepository _storage;
  SupabaseClient get _client => SupabaseService.client;

  // ── Read ──────────────────────────────────────────────────────

  /// All items for the current user that are visible in the wardrobe
  /// (IN_WARDROBE, LAUNDRY, LENT, STORED — not DONATED/DELETED).
  Future<List<Item>> getWardrobeItems(String userId) async {
    final rows = await _client
        .from('items')
        .select()
        .eq('user_id', userId)
        .inFilter('status', [
          ItemStatus.inWardrobe.value,
          ItemStatus.laundry.value,
          ItemStatus.lent.value,
          ItemStatus.stored.value,
        ])
        .order('created_at', ascending: false);
    return rows.map(Item.fromJson).toList();
  }

  /// Items matching [ids] (any status — used by Outfit History to resolve
  /// thumbnails, including donated/deleted items). Returns [] for empty input.
  Future<List<Item>> getItemsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final rows =
        await _client.from('items').select().inFilter('id', ids);
    return rows.map(Item.fromJson).toList();
  }

  /// Single item by id. Returns null if it doesn't exist or RLS denies it.
  Future<Item?> getItem(String itemId) async {
    final row = await _client
        .from('items')
        .select()
        .eq('id', itemId)
        .maybeSingle();
    return row == null ? null : Item.fromJson(row);
  }

  // ── Create ────────────────────────────────────────────────────

  /// Inserts a new item.  If [photo] is provided, uploads it afterwards and
  /// patches `image_path` on the freshly-created row.
  Future<Item> addItem({
    required String userId,
    required Item item,
    File? photo,
  }) async {
    final payload = {'user_id': userId, ...item.toInsertJson()};
    final row = await _client
        .from('items')
        .insert(payload)
        .select()
        .single();
    Item created = Item.fromJson(row);

    if (photo != null) {
      final path = AppConstants.itemImagePath(userId, created.id);
      await _storage.uploadItemPhoto(
          userId: userId, itemId: created.id, file: photo);
      await _client
          .from('items')
          .update({'image_path': path})
          .eq('id', created.id);
      created = created.copyWith(imagePath: path);
    }

    return created;
  }

  // ── Update ────────────────────────────────────────────────────

  /// Full update of an existing item.  Pass [photo] to replace the photo.
  Future<Item> updateItem({
    required Item item,
    File? photo,
  }) async {
    Item updated = item;

    if (photo != null) {
      final path = AppConstants.itemImagePath(item.userId, item.id);
      await _storage.uploadItemPhoto(
          userId: item.userId, itemId: item.id, file: photo);
      updated = item.copyWith(imagePath: path);
    }

    final row = await _client
        .from('items')
        .update(updated.toUpdateJson())
        .eq('id', item.id)
        .select()
        .single();
    return Item.fromJson(row);
  }

  /// Partial update: only the wear/skip counters + last_worn_date.
  /// Called by logWorn / logSkipped (Data Sync Strategy).
  Future<void> updateWearStats({
    required String itemId,
    required int wearCount,
    required int skipCount,
    required bool wearCountUnknown,
    required bool lastWornUnknown,
    DateTime? lastWornDate,
  }) async {
    await _client.from('items').update({
      'wear_count': wearCount,
      'skip_count': skipCount,
      'wear_count_unknown': wearCountUnknown,
      'last_worn_unknown': lastWornUnknown,
      if (lastWornDate != null)
        'last_worn_date':
            '${lastWornDate.year.toString().padLeft(4, '0')}-${lastWornDate.month.toString().padLeft(2, '0')}-${lastWornDate.day.toString().padLeft(2, '0')}',
    }).eq('id', itemId);
  }

  /// Update only `status` and optionally `laundry_started_at`.
  Future<void> updateStatus({
    required String itemId,
    required ItemStatus status,
    DateTime? laundryStartedAt,
  }) async {
    await _client.from('items').update({
      'status': status.value,
      if (laundryStartedAt != null)
        'laundry_started_at':
            '${laundryStartedAt.year.toString().padLeft(4, '0')}-${laundryStartedAt.month.toString().padLeft(2, '0')}-${laundryStartedAt.day.toString().padLeft(2, '0')}',
    }).eq('id', itemId);
  }

  /// Update `condition` and `condition_next_drop`.
  Future<void> updateCondition({
    required String itemId,
    required int condition,
    int? conditionNextDrop,
  }) async {
    await _client.from('items').update({
      'condition': condition,
      'condition_next_drop': conditionNextDrop,
    }).eq('id', itemId);
  }

  /// Set `kept_until` for a donation-kept item.
  Future<void> setKeptUntil({
    required String itemId,
    required DateTime keptUntil,
  }) async {
    await _client.from('items').update({
      'kept_until':
          '${keptUntil.year.toString().padLeft(4, '0')}-${keptUntil.month.toString().padLeft(2, '0')}-${keptUntil.day.toString().padLeft(2, '0')}',
    }).eq('id', itemId);
  }

  /// Clear `kept_until` (Undo Keep — returns item to donation candidates).
  Future<void> clearKeptUntil(String itemId) async {
    await _client.from('items').update({'kept_until': null}).eq('id', itemId);
  }

  /// Confirm donation: sets `status = DONATED` and `donated_at = today`.
  Future<void> confirmDonation(String itemId) async {
    final today = DateTime.now();
    await _client.from('items').update({
      'status': ItemStatus.donated.value,
      'donated_at':
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
    }).eq('id', itemId);
  }

  // ── Delete ────────────────────────────────────────────────────

  /// Soft-delete: sets `status = DELETED` (keeps the row for history).
  Future<void> deleteItem(String itemId) async {
    await _client.from('items').update({
      'status': ItemStatus.deleted.value,
    }).eq('id', itemId);
  }

  /// Returns an item from laundry: sets status to IN_WARDROBE and clears
  /// laundry_started_at in one update. Called by [LaundryReturnService].
  Future<void> returnFromLaundry(String itemId) async {
    await _client.from('items').update({
      'status': ItemStatus.inWardrobe.value,
      'laundry_started_at': null,
    }).eq('id', itemId);
  }

  /// Fetches items currently in LAUNDRY status for the given user.
  /// Used by laundry auto-return on app open.
  Future<List<Item>> getLaundryItems(String userId) async {
    final rows = await _client
        .from('items')
        .select()
        .eq('user_id', userId)
        .eq('status', ItemStatus.laundry.value);
    return rows.map(Item.fromJson).toList();
  }

  /// All DONATED items for the user, newest donation first.
  /// Used by Donation History page (FE §28).
  Future<List<Item>> getDonatedItems(String userId) async {
    final rows = await _client
        .from('items')
        .select()
        .eq('user_id', userId)
        .eq('status', ItemStatus.donated.value)
        .order('donated_at', ascending: false);
    return rows.map(Item.fromJson).toList();
  }

  /// Items currently deferred from donation (kept_until strictly after today).
  /// Used by Kept Items page (FE §27). Returns items in wardrobe statuses only.
  Future<List<Item>> getKeptItems(String userId) async {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final rows = await _client
        .from('items')
        .select()
        .eq('user_id', userId)
        .inFilter('status', [
          ItemStatus.inWardrobe.value,
          ItemStatus.laundry.value,
          ItemStatus.lent.value,
          ItemStatus.stored.value,
        ])
        .gt('kept_until', today);
    return rows.map(Item.fromJson).toList();
  }
}
