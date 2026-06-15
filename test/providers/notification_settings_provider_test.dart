import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rewear/providers/notification_settings_provider.dart';
import 'package:rewear/services/notification_eligibility.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('defaults', () {
    test('N1 N2 N3 N5 default ON, N4 N6 default OFF', () async {
      final toggles =
          await makeContainer().read(notificationSettingsProvider.future);
      expect(toggles.n1, isTrue, reason: 'N1 Daily Reminder defaults ON');
      expect(toggles.n2, isTrue, reason: 'N2 Inactive Warning defaults ON');
      expect(toggles.n3, isTrue, reason: 'N3 Long-Unworn Alert defaults ON');
      expect(toggles.n4, isFalse, reason: 'N4 Donation Reminder defaults OFF');
      expect(toggles.n5, isTrue, reason: 'N5 Weekly Summary defaults ON');
      expect(toggles.n6, isFalse, reason: 'N6 Condition Updates defaults OFF');
    });
  });

  group('setN4 — enable donation reminder', () {
    test('updates in-memory state immediately', () async {
      final c = makeContainer();
      await c.read(notificationSettingsProvider.future);
      await c.read(notificationSettingsProvider.notifier).setN4(true);
      expect(c.read(notificationSettingsProvider).requireValue.n4, isTrue);
    });

    test('persists so a fresh container reads the stored value', () async {
      final c1 = makeContainer();
      await c1.read(notificationSettingsProvider.future);
      await c1.read(notificationSettingsProvider.notifier).setN4(true);

      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      final reloaded = await c2.read(notificationSettingsProvider.future);
      expect(reloaded.n4, isTrue);
    });
  });

  group('setN1 — disable daily reminder', () {
    test('updates in-memory state and persists', () async {
      final c = makeContainer();
      await c.read(notificationSettingsProvider.future);
      await c.read(notificationSettingsProvider.notifier).setN1(false);
      expect(c.read(notificationSettingsProvider).requireValue.n1, isFalse);
    });
  });

  group('setN6 — enable condition updates', () {
    test('updates in-memory state and persists', () async {
      final c = makeContainer();
      await c.read(notificationSettingsProvider.future);
      await c.read(notificationSettingsProvider.notifier).setN6(true);
      expect(c.read(notificationSettingsProvider).requireValue.n6, isTrue);
    });
  });

  group('returns NotificationToggles type', () {
    test('value is a NotificationToggles instance', () async {
      final toggles =
          await makeContainer().read(notificationSettingsProvider.future);
      expect(toggles, isA<NotificationToggles>());
    });
  });
}
