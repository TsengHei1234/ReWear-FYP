import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_eligibility.dart';

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsNotifier, NotificationToggles>(
  NotificationSettingsNotifier.new,
);

class NotificationSettingsNotifier
    extends AsyncNotifier<NotificationToggles> {
  static const _n1 = 'notif_n1';
  static const _n2 = 'notif_n2';
  static const _n3 = 'notif_n3';
  static const _n4 = 'notif_n4';
  static const _n5 = 'notif_n5';
  static const _n6 = 'notif_n6';

  @override
  Future<NotificationToggles> build() async {
    final prefs = await SharedPreferences.getInstance();
    return _fromPrefs(prefs);
  }

  Future<void> setN1(bool v) => _set(_n1, v, (t) => t.copyWith(n1: v));
  Future<void> setN2(bool v) => _set(_n2, v, (t) => t.copyWith(n2: v));
  Future<void> setN3(bool v) => _set(_n3, v, (t) => t.copyWith(n3: v));
  Future<void> setN4(bool v) => _set(_n4, v, (t) => t.copyWith(n4: v));
  Future<void> setN5(bool v) => _set(_n5, v, (t) => t.copyWith(n5: v));
  Future<void> setN6(bool v) => _set(_n6, v, (t) => t.copyWith(n6: v));

  Future<void> _set(
    String key,
    bool value,
    NotificationToggles Function(NotificationToggles) update,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    state = AsyncData(update(state.requireValue));
  }

  static NotificationToggles _fromPrefs(SharedPreferences p) =>
      NotificationToggles(
        n1: p.getBool(_n1) ?? true,
        n2: p.getBool(_n2) ?? true,
        n3: p.getBool(_n3) ?? true,
        n4: p.getBool(_n4) ?? false,
        n5: p.getBool(_n5) ?? true,
        n6: p.getBool(_n6) ?? false,
      );
}
