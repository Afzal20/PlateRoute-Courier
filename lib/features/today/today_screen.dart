import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// S2 — Today (bottom tab 1). Full implementation lands with the offer feed,
/// active task tri-panel and shift pill; this stub wires the shell.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.today),
        actions: [
          TextButton(
            onPressed: () => context.go('/history'),
            child: Text(l10n.history),
          ),
        ],
      ),
      body: const Center(child: Text('Today — offer feed lands next')),
    );
  }
}
