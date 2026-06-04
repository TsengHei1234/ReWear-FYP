import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Thin wrapper around the Supabase singleton.
///
/// [initialize] is called once from `main()` before `runApp`. It is a no-op
/// when config is absent (e.g. during early Phase 0 builds), so the app can
/// still launch the foundation UI without a backend.
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || !SupabaseConfig.isConfigured) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    _initialized = true;
  }

  static bool get isReady => _initialized;

  /// The shared client. Throws if accessed before [initialize] succeeds.
  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser =>
      _initialized ? Supabase.instance.client.auth.currentUser : null;
}
