import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/money.dart';
import '../../l10n/app_localizations.dart';

/// COD collected-later box — always its own container, never rendered inside
/// earnings figures (double-count confusion guard, design §6 Flow B).
class CodBox extends StatelessWidget {
  const CodBox({super.key, required this.amountMinor});

  final int amountMinor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (amountMinor <= 0) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Spacing.m),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTokens.warning, width: AppTokens.borderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.codAmount(Money.bdt(amountMinor)),
            style:
                theme.textTheme.titleMedium?.copyWith(color: AppTokens.warning),
          ),
          SizedBox(height: Spacing.xs),
          Text(l10n.codSeparate, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
