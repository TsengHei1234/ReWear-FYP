import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/enums.dart';
import '../../core/supabase/supabase_client.dart';
import '../models/profile.dart';

/// Reads/writes the current user's `profiles` row.
class ProfileRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Fetch a profile by id. Returns null if the row doesn't exist yet.
  Future<Profile?> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return data == null ? null : Profile.fromJson(data);
  }

  Future<void> updateDisplayName(String userId, String displayName) async {
    await _client
        .from('profiles')
        .update({'display_name': displayName}).eq('id', userId);
  }

  /// Writes the onboarding selections in one update.
  Future<void> saveOnboarding({
    required String userId,
    required List<String> preferredColours,
    required List<String> dislikedColours,
    required RecommendationMode recommendationMode,
  }) async {
    await _client.from('profiles').update({
      'style_preferences': {
        'preferred_colours': preferredColours,
        'disliked_colours': dislikedColours,
      },
      'recommendation_mode': recommendationMode.value,
    }).eq('id', userId);
  }

  Future<void> updateProfile(Profile profile) async {
    await _client
        .from('profiles')
        .update(profile.toUpdateJson())
        .eq('id', profile.id);
  }
}
