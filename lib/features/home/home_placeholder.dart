import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_providers.dart';
import '../../routing/app_router.dart';

/// Temporary Home (Phase 6 builds the real one). Confirms a logged-in session
/// and provides Log Out so the auth loop is testable end-to-end.
class HomePlaceholder extends ConsumerWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Home', style: AppText.titleL),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'Signed in',
                style: AppText.bodyS.copyWith(color: context.colors.textTertiary),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go(Routes.login);
                },
                child: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
