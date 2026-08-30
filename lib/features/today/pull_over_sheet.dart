import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';

/// S12 — "Pull over to continue": guidance, never a hard block (design §10).
/// Shown by the motion gate before gated actions; emergency call paths are
/// exempt from gating upstream.
class PullOverSheet extends StatelessWidget {
  const PullOverSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(Spacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_parking_outlined,
              size: 40, color: AppTokens.warning),
          SizedBox(height: Spacing.m),
          Text(l10n.pullOverTitle, style: theme.textTheme.titleLarge),
          SizedBox(height: Spacing.s),
          Text(l10n.pullOverBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center),
          SizedBox(height: Spacing.l),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.pullOverAck),
          ),
          SizedBox(height: Spacing.m),
        ],
      ),
    );
  }
}
