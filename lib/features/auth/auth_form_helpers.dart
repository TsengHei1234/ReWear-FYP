import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';

/// Email format validator for [TextFormField].
String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Email is required';
  final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!re.hasMatch(v)) return 'Enter a valid email';
  return null;
}

/// Non-empty validator factory. Usage: `validator: validateRequired('Password')`.
String? Function(String?) validateRequired(String field) =>
    (value) => (value == null || value.isEmpty) ? '$field is required' : null;

/// Minimum-length password validator (Supabase default min is 6).
String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Password is required';
  if (v.length < 6) return 'Use at least 6 characters';
  return null;
}

/// Shows a friendly error snackbar. Unwraps Supabase [AuthException] messages.
void showAuthError(BuildContext context, Object error) {
  final message = switch (error) {
    AuthException e => e.message,
    _ => 'Something went wrong. Check your connection and try again.',
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// White spinner sized for inside a primary button.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      );
}
