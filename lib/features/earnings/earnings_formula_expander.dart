import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/earnings_calculator.dart';
import '../../l10n/app_localizations.dart';

/// Expandable per-task math row (component #8, FR-DLV-05). Tapping opens the
/// exact base + distance bonus + tip split so a rider can audit any drop
/// against their own trip numbers. Progressive disclosure never hides money
/// terms — the total is always visible at rest.
class EarningsFormulaExpander extends StatefulWidget {
  const EarningsFormulaExpander({super.key, required this.earnings});

  final TaskEarnings earnings;

  @override
  State<EarningsFormulaExpander> createState() => _EarningsFormulaExpanderState();
}

class _EarningsFormulaExpanderState extends State<EarningsFormulaExpander> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final e = widget.earnings;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outline, width: AppTokens.borderStroke),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: EdgeInsets.all(Spacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _shortOrderId(e.orderUuid.isNotEmpty
                          ? e.orderUuid
                          : e.taskUuid),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    Money.bdt(e.totalMinor),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTokens.offerAccent,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      color: theme.textTheme.bodySmall?.color),
                ],
              ),
              if (_open) ...[
                SizedBox(height: Spacing.m),
                _formulaRow(l10n.earningsBase, e.baseMinor),
                const Divider(height: 16),
                _formulaRow(l10n.earningsDistanceBonus, e.distanceBonusMinor),
                const Divider(height: 16),
                _formulaRow(l10n.earningsTip, e.tipShareMinor),
                const Divider(height: 24),
                _formulaRow(l10n.earningsTotal, e.totalMinor,
                    bold: true, accent: true),
                if (e.codMinor > 0) ...[
                  SizedBox(height: Spacing.s),
                  Text(
                    '${l10n.codBoxLabel}: ${Money.bdt(e.codMinor)} '
                    '(${l10n.earningsCodNote})',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTokens.warning),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _shortOrderId(String raw) =>
      raw.length > 8 ? '…${raw.substring(raw.length - 8)}' : raw;

  Widget _formulaRow(String label, int amount,
      {bool bold = false, bool accent = false}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          Money.bdt(amount),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: accent ? AppTokens.offerAccent : null,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}