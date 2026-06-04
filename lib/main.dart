import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // No-op until Supabase config is provided via --dart-define (Phase 1).
  await SupabaseService.initialize();

  runApp(const ProviderScope(child: ReWearApp()));
}
