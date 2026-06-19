import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../routing/app_router.dart';

/// Set New Password screen — reached only via the password-recovery deep link
/// (rewear://reset-callback). The Supabase passwordRecovery session is already
/// established by the time the user arrives here.
class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;
  String? _serverError;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.every((r) => r == ConnectivityResult.none)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No internet connection. Check your connection and try again.'),
        duration: Duration(seconds: 3),
      ));
      return;
    }
    setState(() {
      _isSaving = true;
      _serverError = null;
    });

    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: _newController.text.trim()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated. Please sign in.')));
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      context.go(Routes.login);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _serverError = 'Failed to update password. The link may have expired.';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Set New Password',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Text(
              'Choose a new password for your account.',
              style: TextStyle(
                  fontSize: 13, color: c.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 28),
            AppTextField(
              label: 'New Password',
              controller: _newController,
              hintText: 'Enter new password',
              isPassword: true,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required.';
                if (v.trim().length < 6) {
                  return 'Password must be at least 6 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Confirm Password',
              controller: _confirmController,
              hintText: 'Confirm new password',
              isPassword: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required.';
                if (v.trim() != _newController.text.trim()) {
                  return 'Passwords do not match.';
                }
                return null;
              },
            ),
            if (_serverError != null) ...[
              const SizedBox(height: 12),
              Text(_serverError!,
                  style:
                      TextStyle(fontSize: 12, color: Colors.red.shade600)),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isSaving ? null : _save,
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
                  : const Text('Update Password',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
