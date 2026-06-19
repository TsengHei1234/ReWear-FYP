import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Wraps a Supabase write action with:
///   1. Connectivity pre-check — bail early if offline.
///   2. Blocking full-screen loading overlay on the ROOT navigator so it is
///      never affected by nested-tab rebuilds triggered by Riverpod state
///      changes (e.g. wardrobeProvider cascade).
///   3. 65-second timeout (Supabase client ceiling is 60 s; this fires after).
///   4. Success SnackBar ([successMessage]) or generic error SnackBar on fail.
///
/// Root-navigator + pre-captured references strategy:
///   NavigatorState and ScaffoldMessengerState are captured BEFORE the async
///   action. Both live for the entire app lifetime, so dismissal and SnackBars
///   work correctly even if the calling widget's BuildContext becomes unmounted
///   during the action (e.g. when a list reorders after a mutation).
///
/// [successMessage] is optional — pass null to suppress the success SnackBar
/// (e.g. when the caller pops the page immediately on success).
Future<void> runMutation(
  BuildContext context, {
  required Future<void> Function() action,
  String? successMessage,
}) async {
  // ── 1. Connectivity pre-check ──────────────────────────────────────────────
  final results = await Connectivity().checkConnectivity();
  final isOffline = results.every((r) => r == ConnectivityResult.none);

  if (isOffline) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'No internet connection. Check your connection and try again.'),
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }

  // ── 2. Capture stable root-level references before any await ───────────────
  if (!context.mounted) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);

  // ── 3. Show blocking overlay on the root navigator ─────────────────────────
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black45,
    useRootNavigator: true,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  // ── 4. Run action with 65-second timeout ───────────────────────────────────
  try {
    await action().timeout(const Duration(seconds: 65));
    navigator.pop(); // dismiss overlay
    if (successMessage != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(successMessage),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (_) {
    navigator.pop(); // dismiss overlay
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to confirm the action. Check your connection and refresh before trying again.',
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }
}
