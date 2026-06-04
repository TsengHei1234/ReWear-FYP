/// Supabase connection config.
///
/// Values are injected at build time via --dart-define so keys are not
/// committed to source. Provide them when running, e.g.:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// Phase 1 fills these in once the Supabase project exists. The anon key is a
/// public client key (safe on-device); RLS is what protects data.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
