import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/profile_repository.dart';

/// Singletons for the auth + profile repositories.
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => ProfileRepository());

/// Streams Supabase auth changes (sign-in / sign-out / token refresh).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).onAuthStateChange;
});

/// Convenience: is there an active session right now?
/// Reads the synchronous current session, falling back to the stream's value.
final isLoggedInProvider = Provider<bool>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  // Re-evaluate whenever auth state emits.
  ref.watch(authStateProvider);
  return repo.currentSession != null;
});
