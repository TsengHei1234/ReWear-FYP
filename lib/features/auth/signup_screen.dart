import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_icon_tile.dart';
import '../../core/widgets/app_text_field.dart';
import '../../providers/auth_providers.dart';
import '../../routing/app_router.dart';
import 'auth_form_helpers.dart';

/// Sign Up screen (Frontend §10).
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
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
    setState(() => _loading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      final res = await auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        displayName: _name.text.trim(),
      );

      // If email confirmation is disabled, a session exists immediately and we
      // can write display_name + continue to onboarding.
      if (res.session != null && res.user != null) {
        await ref
            .read(profileRepositoryProvider)
            .updateDisplayName(res.user!.id, _name.text.trim());
        if (mounted) context.go(Routes.onboarding);
      } else {
        // Email confirmation is ON — tell the user to confirm, send back to login.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check your email to confirm your account.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go(Routes.login);
        }
      }
    } catch (e) {
      if (mounted) showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Center(child: AppIconTile(icon: Icons.checkroom)),
                const SizedBox(height: 16),
                Text('Create account',
                    style: AppText.titleL.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text('Start managing your wardrobe',
                    style: AppText.bodyS.copyWith(color: context.colors.textTertiary)),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Display name',
                  controller: _name,
                  hintText: 'Enter your name',
                  textInputAction: TextInputAction.next,
                  validator: validateRequired('Display name'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Email address',
                  controller: _email,
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: validateEmail,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Password',
                  controller: _password,
                  hintText: 'Create a password',
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: validatePassword,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Confirm password',
                  controller: _confirm,
                  hintText: 'Repeat your password',
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      v != _password.text ? 'Passwords do not match' : null,
                  onFieldSubmitted: (_) => _createAccount(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _createAccount,
                    child: _loading
                        ? const ButtonSpinner()
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account? ',
                        style: AppText.bodyS
                            .copyWith(color: context.colors.textTertiary)),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text('Sign In',
                          style: AppText.bodyS.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
