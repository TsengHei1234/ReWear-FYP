import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/profile.dart';
import 'auth_providers.dart';
import 'wardrobe_providers.dart';

/// Loads the current user's profile row from `profiles`.
/// Re-fetches whenever the user ID changes (sign-in / sign-out).
final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile?>(
    ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return null;
    return ref.read(profileRepositoryProvider).getProfile(userId);
  }

  /// Persist updated profile and refresh the cached value.
  Future<void> updateProfile(Profile profile) async {
    await ref.read(profileRepositoryProvider).updateProfile(profile);
    ref.invalidateSelf();
  }
}
