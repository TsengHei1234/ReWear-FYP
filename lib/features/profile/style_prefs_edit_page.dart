import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../providers/profile_providers.dart';
import '../onboarding/widgets/colour_preference_picker.dart';

/// Edit preferred and disliked colours — reuses [ColourPreferencePicker]
/// from onboarding (FE §33).
class StylePrefsEditPage extends ConsumerStatefulWidget {
  const StylePrefsEditPage({super.key});

  @override
  ConsumerState<StylePrefsEditPage> createState() =>
      _StylePrefsEditPageState();
}

class _StylePrefsEditPageState extends ConsumerState<StylePrefsEditPage> {
  late Set<String> _preferred;
  late Set<String> _disliked;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).asData?.value;
    _preferred = profile?.preferredColours.toSet() ?? {};
    _disliked = profile?.dislikedColours.toSet() ?? {};
  }

  bool _eq(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  void _togglePreferred(String colour) {
    setState(() {
      if (_preferred.contains(colour)) {
        _preferred.remove(colour);
      } else if (_preferred.length < AppConstants.maxColourSelections) {
        _preferred.add(colour);
        _disliked.remove(colour);
      }
    });
  }

  void _toggleDisliked(String colour) {
    setState(() {
      if (_disliked.contains(colour)) {
        _disliked.remove(colour);
      } else if (_disliked.length < AppConstants.maxColourSelections) {
        _disliked.add(colour);
        _preferred.remove(colour);
      }
    });
  }

  Future<void> _save() async {
    final profile = ref.read(profileProvider).asData?.value;
    if (profile == null) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(profileProvider.notifier).updateProfile(
            profile.copyWith(
              preferredColours: _preferred.toList(),
              dislikedColours: _disliked.toList(),
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Preferences saved')));
      setState(() => _isSaving = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to save — please try again.')));
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profile = ref.watch(profileProvider).asData?.value;
    final canSave = !_isSaving &&
        profile != null &&
        (!_eq(_preferred, profile.preferredColours.toSet()) ||
            !_eq(_disliked, profile.dislikedColours.toSet()));

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Style Preferences',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'COLOUR PREFERENCES',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
                letterSpacing: 1.1),
          ),
          const SizedBox(height: 4),
          Text(
            'Select up to 3 colours you love and up to 3 you dislike. '
            'These inform your outfit recommendations.',
            style: TextStyle(
                fontSize: 13, color: c.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          ColourPreferencePicker(
            preferred: _preferred,
            disliked: _disliked,
            onTogglePreferred: _togglePreferred,
            onToggleDisliked: _toggleDisliked,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: canSave ? _save : null,
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              disabledBackgroundColor: c.surface2,
              foregroundColor: Colors.white,
              disabledForegroundColor: c.textTertiary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Save Preferences',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }
}
