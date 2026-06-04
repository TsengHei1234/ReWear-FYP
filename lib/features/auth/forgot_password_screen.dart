import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_icon_tile.dart';
import '../../core/widgets/app_text_field.dart';
import '../../providers/auth_providers.dart';
import 'auth_form_helpers.dart';

/// Forgot Password screen (Frontend §11). Uses Supabase's hosted reset flow.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) showAuthError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Forgot Password',
            style: AppText.titleS.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: _sent ? _buildSuccess(context) : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: AppIconTile(
              icon: Icons.lock_outline,
              background: context.colors.primaryLight,
              iconColor: context.colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text('Reset your password',
              style: AppText.titleM.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            "Enter the email you signed up with and we'll send you a reset link.",
            style: AppText.bodyS.copyWith(color: context.colors.textTertiary, height: 1.5),
          ),
          const SizedBox(height: 28),
          AppTextField(
            label: 'Email address',
            controller: _email,
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: validateEmail,
            onFieldSubmitted: (_) => _send(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _send,
              child: _loading
                  ? const ButtonSpinner()
                  : const Text('Send Reset Link'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: RichText(
                text: TextSpan(
                  style: AppText.bodyS.copyWith(color: context.colors.textTertiary),
                  children: [
                    const TextSpan(text: 'Remembered it? '),
                    TextSpan(
                      text: 'Back to Sign In',
                      style: AppText.bodyS.copyWith(
                          color: context.colors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Text('Check your email for a reset link.',
            textAlign: TextAlign.center,
            style: AppText.bodyM.copyWith(color: context.colors.textSecondary)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Back to Sign In'),
          ),
        ),
      ],
    );
  }
}
