import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/earnings_calculator.dart';
import 'app_providers.dart';

/// S6 — Earnings ledger state (MOB-CUR-05). Derives totals + per-task math
/// from the local task log via the FR-DLV-05 formula.
///
/// Strategic note: the backend does not yet expose a courier
/// `ledger_entries` endpoint. Until it does, numbers derive from the task log
/// (recorded at claim/stage time) so MOB-CUR-05 still ships; when the ledger
/// endpoint lands, this controller swaps to it without UI churn. COD is
/// excluded from every earnings figure and totaled separately.
class EarningsController extends AsyncNotifier<EarningsSummary> {
  @override
  Future<EarningsSummary> build() async {
    final records = await ref.read(taskLogRepositoryProvider).load();
    final delivered = records.where((r) => r.isDelivered).toList();
    final config =
        await EarningsCalculator.loadConfig(ref.read(apiClientProvider));
    return ref.read(earningsCalculatorProvider).summarize(delivered, config);
  }

  Future<void> refresh() => future.then((_) {});
}

final earningsProvider =
    AsyncNotifierProvider<EarningsController, EarningsSummary>(
        EarningsController.new);