import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/widgets/main_page_header.dart';
import '../../providers/outfit_generator_provider.dart';
import '../../providers/profile_providers.dart';
import '../../routing/app_router.dart';
import 'build_outfit_action.dart';
import 'daily_rotation_tab.dart';
import 'outfit_generator_tab.dart';
import 'widgets/outfit_segmented_control.dart';

/// The shell "Outfit" destination. Holds the top bar + segmented control and
/// switches between the Daily Rotation tab (Step 2) and the Outfit Generator
/// tab (Step 3). Source: FE §22 / §23.
class OutfitPage extends ConsumerWidget {
  const OutfitPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final tabIndex = ref.watch(outfitTabIndexProvider);
    final profile = ref.watch(profileProvider).asData?.value;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            MainPageHeader(
              title: 'Outfit',
              action: Tooltip(
                message: 'Outfit history',
                child: GestureDetector(
                  onTap: () => context.push(Routes.outfitHistory),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Icon(Icons.history, size: 22, color: c.textSecondary),
                  ),
                ),
              ),
              avatarSource: profile?.displayName ?? profile?.email,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: OutfitSegmentedControl(
                selectedIndex: tabIndex,
                onChanged: (i) =>
                    ref.read(outfitTabIndexProvider.notifier).set(i),
              ),
            ),
            Expanded(
              child: tabIndex == 0
                  ? DailyRotationTab(
                      onBuildOutfit: (item) => openGeneratorWithPin(
                          context, ref, item,
                          navigate: false))
                  : const OutfitGeneratorTab(),
            ),
          ],
        ),
      ),
    );
  }
}

