import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/supabase/supabase_client.dart';
import 'routing/app_router.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // No-op until Supabase config is provided via --dart-define (Phase 1).
  await SupabaseService.initialize();

  // Notification tap routing by payload prefix:
  //   'wardrobe'   → N1, N2 (logging reminders)
  //   'donate'     → N4 (donation candidates)
  //   'item:<uuid>'→ N6 (condition drop — specific item)
  //   null / other → N3, N5 → Insights
  await NotificationService.instance.initialize(
    onTap: (payload) {
      if (payload == 'wardrobe') {
        appRouter.go(Routes.shellWardrobe);
      } else if (payload == 'donate') {
        appRouter.go(Routes.shellDonate);
      } else if (payload != null && payload.startsWith('item:')) {
        final itemId = payload.substring(5);
        appRouter.go('${Routes.itemDetailById}/$itemId');
      } else {
        appRouter.go(Routes.shellInsights);
      }
    },
  );

  runApp(const ProviderScope(child: ReWearApp()));
}
