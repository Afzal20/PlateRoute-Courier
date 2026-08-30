import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../state/ping_sync.dart';

/// Offline queue banner (MOB-CUR-07): "3 actions saved, will send" under the
/// app bar whenever queue depth > 0; tap opens the manual retry sheet.
class OfflineQueueBanner extends ConsumerWidget {
  const OfflineQueueBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final depth = ref.watch(offlineQueueDepthProvider);
    if (depth <= 0) return const SizedBox.shrink();

    return Material(
      color: AppTokens.warning.withValues(alpha: 0.12),
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          builder: (_) => const OfflineRetrySheet(),
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              horizontal: Spacing.l, vertical: Spacing.s + 2),
          child: Row(
            children: [
              const Icon(Icons.cloud_upload_outlined,
                  size: 18, color: AppTokens.warning),
              SizedBox(width: Spacing.s),
              Expanded(
                child: Text(
                  l10n.offlineQueued(depth),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppTokens.warning),
                ),
              ),
              Text(
                l10n.offlineRetry,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: AppTokens.warning),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// S10 — retry sheet: queue contents at a glance + manual flush.
class OfflineRetrySheet extends ConsumerWidget {
  const OfflineRetrySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final depth = ref.watch(offlineQueueDepthProvider);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(Spacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.offlineQueueTitle, style: theme.textTheme.titleLarge),
            SizedBox(height: Spacing.s),
            Text(
              depth > 0 ? l10n.offlineQueued(depth) : l10n.offlineEmpty,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: Spacing.l),
            FilledButton(
              onPressed: depth > 0
                  ? () async {
                      await ref.read(offlineQueueDepthProvider.notifier).flushNow();
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  : null,
              child: Text(l10n.offlineRetry),
            ),
            SizedBox(height: Spacing.m),
          ],
        ),
      ),
    );
  }
}
