import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';

/// Wraps Supabase Auth. All auth calls go through here.
class AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  /// Emits on sign-in / sign-out / token refresh.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Create an account. `displayName` is stored in user metadata; the
  /// display_name column on `profiles` is written separately after signup
  /// (the DB trigger only copies id + email).
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: displayName == null ? null : {'display_name': displayName},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Sends a password-reset email (Supabase default hosted flow for MVP).
  Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email);
}
