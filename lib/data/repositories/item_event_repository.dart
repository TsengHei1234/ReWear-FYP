import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';
import '../models/item_event.dart';

/// Writes / reads rows in `item_events` (Database §6).
class ItemEventRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Insert a single event and return the persisted row.
  Future<ItemEvent> logEvent(ItemEvent event) async {
    final payload = {'user_id': event.userId, ...event.toInsertJson()};
    final row = await _client
        .from('item_events')
        .insert(payload)
        .select()
        .single();
    return ItemEvent.fromJson(row);
  }

  /// All events for a specific item, ordered newest first.
  /// Used by Full Wear History screen (FE §21).
  Future<List<ItemEvent>> getEventsForItem(String itemId) async {
    final rows = await _client
        .from('item_events')
        .select()
        .eq('item_id', itemId)
        .order('event_at', ascending: false);
    return rows.map(ItemEvent.fromJson).toList();
  }

  /// All events for the current user in a date range (used by insights).
  Future<List<ItemEvent>> getEventsInRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _client
        .from('item_events')
        .select()
        .eq('user_id', userId)
        .gte('event_at', from.toIso8601String())
        .lte('event_at', to.toIso8601String())
        .order('event_at', ascending: false);
    return rows.map(ItemEvent.fromJson).toList();
  }
}
