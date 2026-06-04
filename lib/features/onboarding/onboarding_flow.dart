import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/enums.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_icon_tile.dart';
import '../../core/widgets/progress_dots.dart';
import '../../providers/auth_providers.dart';
import '../../routing/app_router.dart';
import '../auth/auth_form_helpers.dart';
import 'widgets/colour_preference_picker.dart';
import 'widgets/recommendation_mode_card.dart';

/// 4-page onboarding flow (Frontend §12–§15). Collects colour prefs +
/// recommendation mode, then writes them to `profiles` on finish.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _controller = PageController();
  bool _saving = false;

  final Set<String> _preferred = {};
  final Set<String> _disliked = {};
  RecommendationMode _mode = RecommendationMode.balanced;

  static const int _pageCount = 4;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  // Colour picker toggle logic (§42): max 3, mutual exclusion.
  void _togglePreferred(String c) {
    if (_disliked.contains(c)) return;
    setState(() {
      if (_preferred.contains(c)) {
        _preferred.remove(c);
      } else if (_preferred.length < 3) {
        _preferred.add(c);
      }
    });
  }

  void _toggleDisliked(String c) {
    if (_preferred.contains(c)) return;
    setState(() {
      if (_disliked.contains(c)) {
        _disliked.remove(c);
      } else if (_disliked.length < 3) {
        _disliked.add(c);
      }
    });
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
        await ref.read(profileRepositoryProvider).saveOnboarding(
              userId: user.id,
              preferredColours: _preferred.toList(),
              dislikedColours: _disliked.toList(),
              recommendationMode: _mode,
            );
      }
      if (mounted) context.go(Routes.shellHome);
    } catch (e) {
      if (mounted) {
        showAuthError(context, e);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _welcomePage(),
            _stylePage(),
            _modePage(),
            _notificationsPage(),
          ],
        ),
      ),
    );
  }

  // ── Page 1: Welcome (§12) ──────────────────────────────────────
  Widget _welcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const AppIconTile(icon: Icons.checkroom, size: 88, radius: 24),
          const SizedBox(height: 28),
          Text('Meet your smarter wardrobe',
              textAlign: TextAlign.center,
              style: AppText.display.copyWith(fontSize: 26, height: 1.2)),
          const SizedBox(height: 12),
          Text(
            "ReWear tracks what you wear and surfaces the clothes you've been "
            'forgetting — so you use everything you own.',
            textAlign: TextAlign.center,
            style: AppText.bodyM.copyWith(color: context.colors.textSecondary, height: 1.6),
          ),
          const Spacer(),
          const ProgressDots(count: _pageCount, activeIndex: 0),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _next, child: const Text('Get Started')),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Page 2: Style preferences (§13) ────────────────────────────
  Widget _stylePage() {
    return _SkippableScaffold(
      onSkip: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your colour style', style: AppText.titleL),
          const SizedBox(height: 6),
          Text(
            "We'll use this to personalise your recommendations. You can change "
            'this anytime.',
            style: AppText.bodyS.copyWith(color: context.colors.textTertiary, height: 1.5),
          ),
          const SizedBox(height: 20),
          ColourPreferencePicker(
            preferred: _preferred,
            disliked: _disliked,
            onTogglePreferred: _togglePreferred,
            onToggleDisliked: _toggleDisliked,
          ),
          const SizedBox(height: 24),
          const ProgressDots(count: _pageCount, activeIndex: 1),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _next, child: const Text('Next')),
          ),
        ],
      ),
    );
  }

  // ── Page 3: Recommendation mode (§14) ──────────────────────────
  Widget _modePage() {
    return _SkippableScaffold(
      onSkip: _next,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How should we recommend?', style: AppText.titleL),
          const SizedBox(height: 6),
          Text(
            'Choose how your daily rotation works. You can change this anytime '
            'in settings.',
            style: AppText.bodyS.copyWith(color: context.colors.textTertiary, height: 1.5),
          ),
          const SizedBox(height: 24),
          RecommendationModeCard(
            title: 'Balanced Rotation',
            description:
                'Factors in your colour preferences when recommending items. '
                'Best if you have strong style preferences.',
            recommended: true,
            selected: _mode == RecommendationMode.balanced,
            onTap: () => setState(() => _mode = RecommendationMode.balanced),
          ),
          const SizedBox(height: 10),
          RecommendationModeCard(
            title: 'Pure Rotation',
            description:
                'Recommends purely based on wear history. Every item gets a fair '
                'chance regardless of colour or preference.',
            recommended: false,
            selected: _mode == RecommendationMode.pureRotation,
            onTap: () => setState(() => _mode = RecommendationMode.pureRotation),
          ),
          const SizedBox(height: 28),
          const ProgressDots(count: _pageCount, activeIndex: 2),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _next, child: const Text('Next')),
          ),
        ],
      ),
    );
  }

  // ── Page 4: Notifications (§15) ────────────────────────────────
  Widget _notificationsPage() {
    return _SkippableScaffold(
      skipLabel: 'Not Now',
      onSkip: _saving ? null : _finish,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(
            icon: Icons.notifications_none,
            background: context.colors.primaryLight,
            iconColor: context.colors.primary,
          ),
          const SizedBox(height: 16),
          Text('Stay on top of your wardrobe', style: AppText.titleL),
          const SizedBox(height: 6),
          Text(
            'Allow notifications so we can remind you to log outfits and review '
            'neglected items.',
            style: AppText.bodyS.copyWith(color: context.colors.textTertiary, height: 1.5),
          ),
          const SizedBox(height: 20),
          _featureCard(),
          const SizedBox(height: 20),
          const ProgressDots(count: _pageCount, activeIndex: 3),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // Real OS permission request is wired in Phase 8.
              onPressed: _saving ? null : _finish,
              child: _saving
                  ? const ButtonSpinner()
                  : const Text('Allow Notifications'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard() {
    Widget row(IconData icon, String title, String sub) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: context.colors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 13, color: context.colors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppText.labelS.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w600)),
                    Text(sub, style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border, width: 0.5),
      ),
      child: Column(
        children: [
          row(Icons.schedule, 'Daily outfit reminders',
              'Keep your wear history up to date'),
          row(Icons.checkroom, 'Long-unworn alerts',
              "Items that haven't been worn recently"),
          row(Icons.bar_chart, 'Weekly summary',
              'Your wardrobe stats every week'),
        ],
      ),
    );
  }
}

/// Shared layout for onboarding pages 2–4 with a top-right Skip/Not Now button.
class _SkippableScaffold extends StatelessWidget {
  const _SkippableScaffold({
    required this.child,
    required this.onSkip,
    this.skipLabel = 'Skip',
  });

  final Widget child;
  final VoidCallback? onSkip;
  final String skipLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onSkip,
            child: Text(skipLabel,
                style: AppText.labelS.copyWith(
                    color: context.colors.textTertiary, fontWeight: FontWeight.w600)),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: child,
          ),
        ),
      ],
    );
  }
}
