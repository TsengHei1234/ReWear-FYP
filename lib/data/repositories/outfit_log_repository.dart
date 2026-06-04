import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/enums.dart';
import '../../core/supabase/supabase_client.dart';
import '../models/outfit_log.dart';
import '../models/outfit_log_item.dart';

/// Writes / reads `outfit_logs` and `outfit_log_items` (Database §5, §7).
class OutfitLogRepository {
  SupabaseClient get _client => SupabaseService.client;

  // ── Create ────────────────────────────────────────────────────

  /// Creates an outfit log + its item rows in one go. Returns the persisted log.
  Future<OutfitLog> logOutfit({
    required String userId,
    required OutfitLogSource source,
    required List<({String itemId, LayerType layerType})> items,
    Occasion? occasion,
    double? outfitScore,
  }) async {
    final logPayload = <String, dynamic>{
      'user_id': userId,
      'occasion': ?occasion?.value,
      'outfit_score': ?outfitScore,
      'source': source.value,
    };
    final logRow = await _client
        .from('outfit_logs')
        .insert(logPayload)
        .select()
        .single();
    final log = OutfitLog.fromJson(logRow);

    if (items.isNotEmpty) {
      final itemPayloads = items
          .map((e) => {
                'user_id': userId,
                'outfit_log_id': log.id,
                'item_id': e.itemId,
                'layer_type': e.layerType.value,
              })
          .toList();
      await _client.from('outfit_log_items').insert(itemPayloads);
    }

    return log;
  }

  // ── Read ──────────────────────────────────────────────────────

  /// Paginated outfit history for the current user.
  Future<List<OutfitLog>> getOutfitHistory({
    required String userId,
    int limit = 30,
    int offset = 0,
  }) async {
    final rows = await _client
        .from('outfit_logs')
        .select()
        .eq('user_id', userId)
        .order('logged_at', ascending: false)
        .range(offset, offset + limit - 1);
    return rows.map(OutfitLog.fromJson).toList();
  }

  /// Items for many outfit logs in one query (Outfit History). Returns [] for
  /// empty input. Caller groups by `outfitLogId`.
  Future<List<OutfitLogItem>> getOutfitItemsForLogs(List<String> logIds) async {
    if (logIds.isEmpty) return [];
    final rows = await _client
        .from('outfit_log_items')
        .select()
        .inFilter('outfit_log_id', logIds);
    return rows.map(OutfitLogItem.fromJson).toList();
  }

  /// Items belonging to a specific outfit log.
  Future<List<OutfitLogItem>> getOutfitItems(String outfitLogId) async {
    final rows = await _client
        .from('outfit_log_items')
        .select()
        .eq('outfit_log_id', outfitLogId);
    return rows.map(OutfitLogItem.fromJson).toList();
  }
}
