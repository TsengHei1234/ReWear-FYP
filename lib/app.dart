import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'providers/theme_mode_provider.dart';
import 'routing/app_router.dart';

/// Root application widget.
class ReWearApp extends ConsumerWidget {
  const ReWearApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system;
    return MaterialApp.router(
      title: 'ReWear',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
