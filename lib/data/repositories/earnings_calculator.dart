import '../../core/network/api_client.dart';
import '../models/task_record.dart';

/// FR-DLV-05 earnings formula, driven by runtime config (`/v1/config/`) so
/// the platform can tune incentives without an app release.
///
///   earnings(task) = base_fee
///                  + distance_bonus(max(0, km - free_km) * per_km_minor)
///                  + tip * courier_share_pct
///
/// COD collections are NEVER part of earnings — they are displayed in their
/// own box (double-count confusion guard) and audited separately.
class EarningsConfig {
  const EarningsConfig({
    this.distanceBonusMinorPerKm = 1200,
    this.distanceBonusFreeKm = 2.0,
    this.tipCourierSharePct = 100,
    this.payoutCycleWeekday = 7, // 1=Mon .. 7=Sun
  });

  final int distanceBonusMinorPerKm;
  final double distanceBonusFreeKm;
  final int tipCourierSharePct;
  final int payoutCycleWeekday;

  factory EarningsConfig.fromRuntime(Map<String, Object?> raw) {
    int? asInt(String k) => int.tryParse('${raw[k] ?? ''}');
    double? asDouble(String k) => double.tryParse('${raw[k] ?? ''}');
    return EarningsConfig(
      distanceBonusMinorPerKm: asInt('delivery.distance_bonus_minor_per_km') ?? 1200,
      distanceBonusFreeKm: asDouble('delivery.distance_bonus_free_km') ?? 2.0,
      tipCourierSharePct: asInt('delivery.tip_courier_share_pct') ?? 100,
      payoutCycleWeekday: asInt('courier.payout_cycle_weekday') ?? 7,
    );
  }
}

/// Expandable per-task math row (EarningsFormulaExpander backing model).
class TaskEarnings {
  const TaskEarnings({
    required this.taskUuid,
    required this.orderUuid,
    required this.baseMinor,
    required this.distanceBonusMinor,
    required this.tipShareMinor,
    required this.codMinor,
    required this.claimedAt,
    required this.droppedAt,
  });

  final String taskUuid;
  final String orderUuid;
  final int baseMinor;
  final int distanceBonusMinor;
  final int tipShareMinor;
  final int codMinor; // displayed separately, excluded from total
  final DateTime claimedAt;
  final DateTime? droppedAt;

  int get totalMinor => baseMinor + distanceBonusMinor + tipShareMinor;
}

class EarningsSummary {
  const EarningsSummary({
    required this.rows,
    required this.todayMinor,
    required this.weekMinor,
    required this.totalMinor,
    required this.codCollectedMinor,
    required this.nextPayoutDate,
    required this.config,
  });

  final List<TaskEarnings> rows;
  final int todayMinor;
  final int weekMinor;
  final int totalMinor;
  final int codCollectedMinor;
  final DateTime nextPayoutDate;
  final EarningsConfig config;
}

/// Pure derivation from the local task log + config — unit-testable without
/// network or widgets, and auditable against ledger_entries once the backend
/// exposes a courier ledger endpoint.
class EarningsCalculator {
  const EarningsCalculator();

  TaskEarnings derive(TaskRecord record, EarningsConfig config) {
    final km = ((record.dropoffDistanceM ?? 0) + (record.pickupDistanceM ?? 0)) / 1000.0;
    final bonusKm = (km - config.distanceBonusFreeKm).clamp(0.0, double.infinity);
    final bonus = (bonusKm * config.distanceBonusMinorPerKm).round();
    final tipShare = record.tipMinor * config.tipCourierSharePct ~/ 100;
    return TaskEarnings(
      taskUuid: record.taskUuid,
      orderUuid: record.orderUuid,
      baseMinor: record.feeMinor,
      distanceBonusMinor: bonus,
      tipShareMinor: tipShare,
      codMinor: record.codMinor,
      claimedAt: record.claimedAt,
      droppedAt: record.droppedAt,
    );
  }

  EarningsSummary summarize(List<TaskRecord> records, EarningsConfig config,
      {DateTime? now}) {
    final at = now ?? DateTime.now();
    final delivered =
        records.where((r) => r.isDelivered).toList(growable: false);
    final rows = delivered
        .map((r) => derive(r, config))
        .toList()
      ..sort((a, b) => b.claimedAt.compareTo(a.claimedAt));

    final today = DateTime(at.year, at.month, at.day);
    final weekStart = today.subtract(Duration(days: at.weekday - 1));
    int todayMinor = 0, weekMinor = 0, totalMinor = 0, codMinor = 0;
    for (final row in rows) {
      final at2 = row.droppedAt ?? row.claimedAt;
      totalMinor += row.totalMinor;
      codMinor += row.codMinor;
      if (!at2.isBefore(weekStart)) weekMinor += row.totalMinor;
      if (!at2.isBefore(today)) todayMinor += row.totalMinor;
    }
    return EarningsSummary(
      rows: rows,
      todayMinor: todayMinor,
      weekMinor: weekMinor,
      totalMinor: totalMinor,
      codCollectedMinor: codMinor,
      nextPayoutDate: _nextPayout(at, config.payoutCycleWeekday),
      config: config,
    );
  }

  DateTime _nextPayout(DateTime now, int weekday) {
    var daysAhead = (weekday - now.weekday) % 7;
    if (daysAhead == 0 && now.hour >= 23) daysAhead = 7;
    return DateTime(now.year, now.month, now.day + daysAhead);
  }

  /// Fetch live config; falls back to defaults offline (queue-friendly).
  static Future<EarningsConfig> loadConfig(ApiClient api) async {
    try {
      final data = await api.send<Map<String, Object?>>((dio) => dio
          .get('config/', queryParameters: {
        'key': [
          'delivery.distance_bonus_minor_per_km',
          'delivery.distance_bonus_free_km',
          'delivery.tip_courier_share_pct',
          'courier.payout_cycle_weekday',
        ]
      }));
      return EarningsConfig.fromRuntime(data);
    } on Object {
      return const EarningsConfig();
    }
  }
}
