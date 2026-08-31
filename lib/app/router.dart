import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/earnings/earnings_screen.dart';
import '../features/more/more_screen.dart';
import '../features/pod/pod_camera_screen.dart';
import '../features/today/today_screen.dart';
import '../features/history/history_screen.dart';
import '../features/history/ticket_detail_screen.dart';
import '../features/settings/settings_screen.dart';
import '../l10n/app_localizations.dart';
import '../state/auth_controller.dart';

/// Bottom tabs: exactly 3 — Today / Earnings / More. Offer + ActiveTask live
/// inside Today (claim must never teleport navigation, design §5).
final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Watching auth re-evaluates the redirect on login/logout.
  final auth = ref.watch(authProvider);
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/today',
    redirect: (context, state) {
      final loggedIn = auth.value != null;
      final loggingIn = state.matchedLocation == '/login';
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/today';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/today', builder: (_, _) => const TodayScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/earnings', builder: (_, _) => EarningsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/history',
        builder: (_, _) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/history/ticket/:uuid',
        builder: (_, state) =>
            TicketDetailScreen(uuid: state.pathParameters['uuid']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/pod/:taskUuid',
        builder: (_, state) =>
            PodCameraScreen(taskUuid: state.pathParameters['taskUuid']!),
      ),
    ],
  );
});

class _AppShell extends StatelessWidget {
  const _AppShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(
          i,
          initialLocation: i == shell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.today_outlined),
              selectedIcon: const Icon(Icons.today),
              label: l10n.today),
          NavigationDestination(
              icon: const Icon(Icons.payments_outlined),
              selectedIcon: const Icon(Icons.payments),
              label: l10n.earnings),
          NavigationDestination(
              icon: const Icon(Icons.more_horiz),
              selectedIcon: const Icon(Icons.more_horiz),
              label: l10n.more),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: Text('Coming next')),
      );
}
