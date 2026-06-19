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

/// Login screen (Frontend §9).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
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
      await ref.read(authRepositoryProvider).signIn(
            email: _email.text.trim(),
            password: _password.text,
          );
      if (mounted) context.go(Routes.shellHome);
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
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Center(child: AppIconTile(icon: Icons.checkroom)),
                const SizedBox(height: 16),
                Text('Welcome back',
                    style: AppText.titleL.copyWith(fontSize: 24)),
                const SizedBox(height: 4),
                Text('Sign in to your account',
                    style: AppText.bodyS.copyWith(color: context.colors.textTertiary)),
                const SizedBox(height: 28),
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
                  hintText: 'Enter your password',
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: validateRequired('Password'),
                  onFieldSubmitted: (_) => _signIn(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(Routes.forgotPassword),
                    child: Text('Forgot Password?',
                        style: AppText.labelS.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signIn,
                    child: _loading
                        ? const ButtonSpinner()
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 12),
                _SignUpPrompt(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ",
            style: AppText.bodyS.copyWith(color: context.colors.textTertiary)),
        GestureDetector(
          onTap: () => context.push(Routes.signup),
          child: Text('Sign Up',
              style: AppText.bodyS.copyWith(
                  color: context.colors.primary, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
