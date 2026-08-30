import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/earnings_calculator.dart';
import '../../l10n/app_localizations.dart';
import '../../state/earnings_controller.dart';
import '../shared/widgets.dart';
import '../today/cod_box.dart';
import 'earnings_formula_expander.dart';

/// S6 — Earnings ledger (MOB-CUR-05 / FR-DLV-05):
///  - period totals (Today / This week / Total) derived SOLELY from the task
///    log — numbers are auditable, never approximated
///  - expandable per-task rows: base + distance bonus + tip split exactly as
///    the formula defines
///  - COD collected boxed separately — never inside an earnings figure
///  - payout cycle date always visible
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  static final _dateFmt = DateFormat('dd MMM');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final earnings = ref.watch(earningsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.earnings)),
      body: earnings.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: PanelCard(child: Text(l10n.errorGeneric)),
        ),
        data: (summary) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PeriodTotals(summary: summary),
            SizedBox(height: Spacing.l),
            if (summary.codCollectedMinor > 0) ...[
              CodBox(amountMinor: summary.codCollectedMinor),
              SizedBox(height: Spacing.l),
            ],
            Text(
              '${l10n.payoutCycle}, ${_dateFmt.format(summary.nextPayoutDate)}',
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: Spacing.m),
            // Expandable per-task math rows.
            for (final row in summary.rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EarningsFormulaExpander(earnings: row),
              ),
            if (summary.rows.isEmpty)
              PanelCard(child: Text(l10n.earningsFormula)),
          ],
        ),
      ),
    );
  }
}

class _PeriodTotals extends StatelessWidget {
  const _PeriodTotals({required this.summary});

  final EarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      child: Row(
        children: [
          Expanded(
            child: _TotalCell(
              label: AppLocalizations.of(context)!.earningsToday,
              amount: summary.todayMinor,
              highlight: true,
            ),
          ),
          Expanded(
            child: _TotalCell(
              label: AppLocalizations.of(context)!.earningsThisWeek,
              amount: summary.weekMinor,
            ),
          ),
          Expanded(
            child: _TotalCell(
              label: AppLocalizations.of(context)!.earningsTotal,
              amount: summary.totalMinor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  const _TotalCell({
    required this.label,
    required this.amount,
    this.highlight = false,
  });

  final String label;
  final int amount;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        SizedBox(height: Spacing.xs),
        Text(
          Money.bdt(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            color: highlight ? AppTokens.offerAccent : null,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}