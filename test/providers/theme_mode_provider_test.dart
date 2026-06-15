import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rewear/providers/theme_mode_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to ThemeMode.system when no pref stored', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(themeModeProvider.future), ThemeMode.system);
  });

  test('reads persisted light mode on init', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(themeModeProvider.future), ThemeMode.light);
  });

  test('reads persisted dark mode on init', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(themeModeProvider.future), ThemeMode.dark);
  });

  test('unknown stored value defaults to system', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'invalid'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(themeModeProvider.future), ThemeMode.system);
  });

  test('setMode(light) updates state immediately', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(themeModeProvider.future);
    await container.read(themeModeProvider.notifier).setMode(ThemeMode.light);
    expect(container.read(themeModeProvider).asData?.value, ThemeMode.light);
  });

  test('setMode(dark) updates state immediately', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(themeModeProvider.future);
    await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    expect(container.read(themeModeProvider).asData?.value, ThemeMode.dark);
  });

  test('setMode(system) updates state immediately', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(themeModeProvider.future);
    await container.read(themeModeProvider.notifier).setMode(ThemeMode.system);
    expect(container.read(themeModeProvider).asData?.value, ThemeMode.system);
  });

  test('setMode writes to SharedPreferences so a new container reads it back',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(themeModeProvider.future);
    await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    container.dispose();

    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    expect(await container2.read(themeModeProvider.future), ThemeMode.dark);
  });
}
