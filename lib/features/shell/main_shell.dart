import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../providers/wardrobe_providers.dart';

/// The persistent 5-tab scaffold that wraps all main-tab pages.
/// Source: FE §6.14 (bottom nav), FE §7 (navigation structure).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    // On resume, run a date-gated laundry check — skips same-day resumes
    // with zero DB calls; only invalidates wardrobe if items were returned.
    _lifecycleListener = AppLifecycleListener(
      onResume: () =>
          ref.read(wardrobeProvider.notifier).checkLaundryOnResume(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Prevent the keyboard from shrinking the shell body.
      // Pages inside the shell that need keyboard-aware layout (none yet) must
      // manage their own insets. Without this, typing in the wardrobe search bar
      // lifts the empty-state content and FAB.
      resizeToAvoidBottomInset: false,
      body: widget.navigationShell,
      bottomNavigationBar: _BottomNav(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_outlined, label: 'Home'),
    (icon: Icons.checkroom_outlined, label: 'Wardrobe'),
    (icon: Icons.auto_fix_high_outlined, label: 'Outfit'),
    (icon: Icons.favorite_outline, label: 'Donate'),
    (icon: Icons.bar_chart_outlined, label: 'Insights'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (int i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _items[i].icon,
                    label: _items[i].label,
                    active: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Active: pill container around icon
          if (active)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                color: c.primaryLight,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(icon, size: 22, color: c.primary),
            )
          else
            Icon(icon, size: 22, color: c.textTertiary),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight:
                  active ? FontWeight.w600 : FontWeight.w400,
              color: active ? c.primary : c.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
