import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'features/shared/screen_border_flash.dart';
import 'l10n/app_localizations.dart';
import 'state/app_providers.dart';
import 'state/ping_sync.dart';
import 'state/settings_controller.dart';

/// Root widget: dark-first themes, en/bn localization, gloves-mode scope,
/// offline queue bootstrap and the screen-border flash overlay.
class CourierApp extends ConsumerWidget {
  const CourierApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    // Bootstrap the offline queue depth stream once.
    ref.watch(offlineQueueDepthProvider.notifier);

    return GlovesScope(
      enabled: settings.glovesMode,
      child: ScreenBorderFlash(
        flashes: ref.watch(hapticsProvider).borderFlash,
        child: MaterialApp.router(
          title: 'PlateRoute Courier',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          locale: settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  }
}
