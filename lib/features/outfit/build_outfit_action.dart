import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/confirm_sheet.dart';
import '../../data/models/item.dart';
import '../../providers/outfit_generator_provider.dart';
import '../../routing/app_router.dart';

/// Pins [item] in the Outfit Generator and opens the Generator tab.
///
/// Confirms first ONLY when generated outfits are currently showing — starting a
/// new build replaces the pin and clears those outfits (DECISIONS G1). A lone pin
/// with nothing generated yet has no work to lose, so it's swapped silently. Pass
/// [navigate] = false when already on the Outfit page (Daily Rotation's Build
/// Outfit), so it only switches sub-tabs.
Future<void> openGeneratorWithPin(
  BuildContext context,
  WidgetRef ref,
  Item item, {
  bool navigate = true,
}) async {
  final gen = ref.read(outfitGeneratorProvider);
  if (gen.hasGenerated) {
    final ok = await showConfirmSheet(
      context,
      icon: Icons.auto_fix_high,
      title: 'Start a new outfit?',
      message: 'This clears your current generated outfits.',
      confirmLabel: 'Start New',
    );
    if (!ok) return;
  }
  ref.read(outfitGeneratorProvider.notifier).setPinnedItem(item);
  ref.read(outfitTabIndexProvider.notifier).set(1);
  if (navigate && context.mounted) context.go(Routes.shellOutfit);
}
