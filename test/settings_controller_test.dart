import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:courier/state/settings_controller.dart';
import 'package:courier/state/app_providers.dart';
import 'package:courier/core/storage/json_store.dart';
import 'package:courier/core/services/analytics_service.dart';

class FakeJsonStore implements JsonStore {
  Map<String, dynamic> data = {};

  final String key;
  FakeJsonStore(this.key);

  @override
  Future<Map<String, dynamic>> readAll() async => data;

  @override
  Future<void> update(void Function(Map<String, dynamic> doc) mutation) async {
    mutation(data);
  }

  Future<void> clear() async {
    data.clear();
  }
}

class FakeAnalytics implements Analytics {
  bool? darkTheme;
  
  @override
  void screenThemeUsage({required bool dark}) {
    darkTheme = dark;
  }
  
  // Other methods would be here...
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('SettingsController toggles theme and persists', () async {
    final store = FakeJsonStore('settings');
    final analytics = FakeAnalytics();
    
    final container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        analyticsProvider.overrideWithValue(analytics),
      ],
    );
    
    final notifier = container.read(settingsProvider.notifier);
    
    // Initial is dark
    expect(container.read(settingsProvider).themeMode, ThemeMode.dark);
    
    await notifier.setThemeMode(ThemeMode.light);
    
    expect(container.read(settingsProvider).themeMode, ThemeMode.light);
    expect(analytics.darkTheme, false);
    
    final saved = await store.readAll();
    expect((saved['settings'] as Map)['theme'], 'light');
  });

  test('SettingsController toggles gloves mode', () async {
    final store = FakeJsonStore('settings');
    
    final container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        analyticsProvider.overrideWithValue(FakeAnalytics()),
      ],
    );
    
    final notifier = container.read(settingsProvider.notifier);
    
    await notifier.setGlovesMode(true);
    
    expect(container.read(settingsProvider).glovesMode, true);
    
    final saved = await store.readAll();
    expect((saved['settings'] as Map)['gloves'], true);
  });
}
