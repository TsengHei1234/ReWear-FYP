import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/utils/mutation_helper.dart';
import '../../providers/profile_providers.dart';
import '../../routing/app_router.dart';

/// Edit display name; email is read-only (FE §32).
class MyProfilePage extends ConsumerStatefulWidget {
  const MyProfilePage({super.key});

  @override
  ConsumerState<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends ConsumerState<MyProfilePage> {
  late final TextEditingController _controller;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final initial =
        ref.read(profileProvider).asData?.value?.displayName ?? '';
    _controller = TextEditingController(text: initial);
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final original =
        ref.read(profileProvider).asData?.value?.displayName?.trim() ?? '';
    final current = _controller.text.trim();
    final dirty = current.isNotEmpty && current != original;
    if (dirty != _isDirty) setState(() => _isDirty = dirty);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final profile = ref.read(profileProvider).asData?.value;
    if (profile == null || !_isDirty) return;
    bool succeeded = false;
    await runMutation(
      context,
      action: () async {
        await ref.read(profileProvider.notifier).updateProfile(
              profile.copyWith(displayName: _controller.text.trim()),
            );
        succeeded = true;
      },
      successMessage: 'Profile updated',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).unfocus();
    });
    if (mounted && succeeded) setState(() => _isDirty = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profile = ref.watch(profileProvider).asData?.value;
    final source = profile?.displayName ?? profile?.email;
    final email = profile?.email ?? '';

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
          'My Profile',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration:
                    BoxDecoration(color: c.primary, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  _initials(source),
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ),
          ),
          Text(
            'ACCOUNT DETAILS',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
                letterSpacing: 1.1),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border, width: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISPLAY NAME',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                      letterSpacing: 1.1),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _controller,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    hintStyle:
                        TextStyle(fontSize: 14, color: c.textTertiary),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: c.border)),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: c.primary, width: 1.5)),
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 18),
                Divider(height: 0.5, thickness: 0.5, color: c.border),
                const SizedBox(height: 16),
                Text(
                  'EMAIL',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                      letterSpacing: 1.1),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        email.isNotEmpty ? email : '—',
                        style:
                            TextStyle(fontSize: 14, color: c.textPrimary),
                      ),
                    ),
                    Icon(Icons.lock_outline_rounded,
                        size: 15, color: c.textTertiary),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(height: 0.5, thickness: 0.5, color: c.border),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => context.push(Routes.forgotPassword),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Reset Password',
                          style: TextStyle(
                              fontSize: 14, color: c.textPrimary),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: c.textTertiary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isDirty ? _save : null,
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              disabledBackgroundColor: c.surface2,
              foregroundColor: Colors.white,
              disabledForegroundColor: c.textTertiary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Save Changes',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String? source) {
    if (source == null || source.trim().isEmpty) return '?';
    final parts = source.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }
}
