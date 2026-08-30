import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/tokens.dart';
import 'app_providers.dart';

/// Ping interval presets — battery honesty (NFR-16): every preset discloses
/// its estimated %/hour cost so riders choose with open eyes.
enum PingIntervalPreset {
  high(5, 'pingCostHigh'),
  balanced(10, 'pingCostBalanced'),
  saver(30, 'pingCostSaver'),
  off(0, 'pingCostOff');

  const PingIntervalPreset(this.seconds, this.costKey);

  final int seconds; // 0 = tracking opt-out
  final String costKey;

  Duration? get duration =>
      seconds == 0 ? null : Duration(seconds: seconds);
}

/// Non-secret app settings. Dark theme is the default flavor flag (design §3).
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.locale = const Locale('en'),
    this.glovesMode = false,
    this.pingInterval = PingIntervalPreset.balanced,
    this.blockedCustomers = const [],
  });

  final ThemeMode themeMode;
  final Locale locale;
  final bool glovesMode;
  final PingIntervalPreset pingInterval;
  final List<String> blockedCustomers;

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? glovesMode,
    PingIntervalPreset? pingInterval,
    List<String>? blockedCustomers,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        glovesMode: glovesMode ?? this.glovesMode,
        pingInterval: pingInterval ?? this.pingInterval,
        blockedCustomers: blockedCustomers ?? this.blockedCustomers,
      );

  Map<String, Object?> toJson() => {
        'theme': themeMode.name,
        'locale': locale.languageCode,
        'gloves': glovesMode,
        'ping': pingInterval.name,
        'blocked': blockedCustomers,
      };

  static AppSettings fromJson(Map<String, Object?> json) => AppSettings(
        themeMode: ThemeMode.values.firstWhere(
          (m) => m.name == json['theme'],
          orElse: () => ThemeMode.dark,
        ),
        locale: Locale((json['locale'] as String?) ?? 'en'),
        glovesMode: json['gloves'] == true,
        pingInterval: PingIntervalPreset.values.firstWhere(
          (p) => p.name == json['ping'],
          orElse: () => PingIntervalPreset.balanced,
        ),
        blockedCustomers:
            ((json['blocked'] as List?) ?? []).cast<String>(),
      );
}

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _hydrate();
    return const AppSettings();
  }

  bool _hydrated = false;

  Future<void> _hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    final store = ref.read(settingsStoreProvider);
    final all = await store.readAll();
    final raw = all['settings'];
    if (raw is Map) {
      state = AppSettings.fromJson(raw.cast<String, Object?>());
      ref.read(analyticsProvider)
          .screenThemeUsage(dark: state.themeMode == ThemeMode.dark);
    }
  }

  Future<void> _persist() => ref
      .read(settingsStoreProvider)
      .update((all) => all..['settings'] = state.toJson());

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    ref.read(analyticsProvider).screenThemeUsage(dark: mode == ThemeMode.dark);
    await _persist();
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _persist();
  }

  Future<void> setGlovesMode(bool enabled) async {
    state = state.copyWith(glovesMode: enabled);
    Spacing.multiplier = enabled ? 1.25 : 1.0;
    await _persist();
  }

  Future<void> setPingInterval(PingIntervalPreset preset) async {
    state = state.copyWith(pingInterval: preset);
    await _persist();
  }

  Future<void> blockCustomer(String phone) async {
    if (state.blockedCustomers.contains(phone)) return;
    state = state.copyWith(blockedCustomers: [...state.blockedCustomers, phone]);
    await _persist();
  }

  Future<void> unblockCustomer(String phone) async {
    state = state.copyWith(
        blockedCustomers:
            state.blockedCustomers.where((c) => c != phone).toList());
    await _persist();
  }
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
