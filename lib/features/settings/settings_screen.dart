import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/settings_controller.dart';
import '../../core/theme/tokens.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.all(Spacing.m),
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Optimize for night riding'),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (val) {
              notifier.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          SwitchListTile(
            title: const Text('Gloves Mode'),
            subtitle: const Text('Increases touch targets for thick gloves'),
            value: settings.glovesMode,
            onChanged: (val) {
              notifier.setGlovesMode(val);
            },
          ),
          const Divider(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.m, vertical: Spacing.s),
            child: const Text('Ping Interval (Location Tracking)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          RadioListTile<PingIntervalPreset>(
            title: const Text('High (5s)'),
            subtitle: const Text('Most accurate, high battery drain'),
            value: PingIntervalPreset.high,
            groupValue: settings.pingInterval,
            onChanged: (val) => notifier.setPingInterval(val!),
          ),
          RadioListTile<PingIntervalPreset>(
            title: const Text('Balanced (10s)'),
            subtitle: const Text('Good balance of tracking and battery'),
            value: PingIntervalPreset.balanced,
            groupValue: settings.pingInterval,
            onChanged: (val) => notifier.setPingInterval(val!),
          ),
          RadioListTile<PingIntervalPreset>(
            title: const Text('Saver (30s)'),
            subtitle: const Text('Saves battery, less accurate ETA'),
            value: PingIntervalPreset.saver,
            groupValue: settings.pingInterval,
            onChanged: (val) => notifier.setPingInterval(val!),
          ),
          RadioListTile<PingIntervalPreset>(
            title: const Text('Off'),
            subtitle: const Text('Tracking disabled'),
            value: PingIntervalPreset.off,
            groupValue: settings.pingInterval,
            onChanged: (val) => notifier.setPingInterval(val!),
          ),
        ],
      ),
    );
  }
}
