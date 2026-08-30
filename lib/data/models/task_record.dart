import 'offer.dart';

/// One historical trip stored locally (task log). The backend has no courier
/// history endpoint yet, so the client records the full status trail itself
/// and the Earnings screen derives FR-DLV-05 math from these rows.
class TaskRecord {
  const TaskRecord({
    required this.taskUuid,
    required this.orderUuid,
    required this.feeMinor,
    required this.claimedAt,
    this.tipMinor = 0,
    this.codMinor = 0,
    this.pickupDistanceM,
    this.dropoffDistanceM,
    this.droppedAt,
    this.podPath,
    this.ticketUuid,
    this.trail = const [],
  });

  final String taskUuid;
  final String orderUuid;
  final int feeMinor;
  final int tipMinor;
  final int codMinor;
  final double? pickupDistanceM;
  final double? dropoffDistanceM;
  final DateTime claimedAt;
  final DateTime? droppedAt;
  final String? podPath;
  final String? ticketUuid;

  /// Status trail mirrors order events: (stage, timestamp).
  final List<(TripStage, DateTime)> trail;

  bool get isDelivered => droppedAt != null;

  Map<String, Object?> toJson() => {
        'task_uuid': taskUuid,
        'order_uuid': orderUuid,
        'fee_minor': feeMinor,
        'tip_minor': tipMinor,
        'cod_minor': codMinor,
        'pickup_distance_m': pickupDistanceM,
        'dropoff_distance_m': dropoffDistanceM,
        'claimed_at': claimedAt.toIso8601String(),
        'dropped_at': droppedAt?.toIso8601String(),
        'pod_path': podPath,
        'ticket_uuid': ticketUuid,
        'trail': [
          for (final (stage, at) in trail)
            {'stage': stage.name, 'at': at.toIso8601String()}
        ],
      };

  static TaskRecord fromJson(Map<String, Object?> json) => TaskRecord(
        taskUuid: json['task_uuid'] as String,
        orderUuid: json['order_uuid'] as String,
        feeMinor: (json['fee_minor'] as num).toInt(),
        tipMinor: (json['tip_minor'] as num?)?.toInt() ?? 0,
        codMinor: (json['cod_minor'] as num?)?.toInt() ?? 0,
        pickupDistanceM: (json['pickup_distance_m'] as num?)?.toDouble(),
        dropoffDistanceM: (json['dropoff_distance_m'] as num?)?.toDouble(),
        claimedAt: DateTime.parse(json['claimed_at'] as String),
        droppedAt: json['dropped_at'] == null
            ? null
            : DateTime.parse(json['dropped_at'] as String),
        podPath: json['pod_path'] as String?,
        ticketUuid: json['ticket_uuid'] as String?,
        trail: [
          for (final e in ((json['trail'] as List?) ?? []))
            (
              TripStage.values.byName((e as Map)['stage'] as String),
              DateTime.parse(e['at'] as String),
            )
        ],
      );

  TaskRecord copyWith({
    int? tipMinor,
    int? codMinor,
    double? pickupDistanceM,
    double? dropoffDistanceM,
    DateTime? droppedAt,
    String? podPath,
    String? ticketUuid,
    List<(TripStage, DateTime)>? trail,
  }) =>
      TaskRecord(
        taskUuid: taskUuid,
        orderUuid: orderUuid,
        feeMinor: feeMinor,
        tipMinor: tipMinor ?? this.tipMinor,
        codMinor: codMinor ?? this.codMinor,
        pickupDistanceM: pickupDistanceM ?? this.pickupDistanceM,
        dropoffDistanceM: dropoffDistanceM ?? this.dropoffDistanceM,
        claimedAt: claimedAt,
        droppedAt: droppedAt ?? this.droppedAt,
        podPath: podPath ?? this.podPath,
        ticketUuid: ticketUuid ?? this.ticketUuid,
        trail: trail ?? this.trail,
      );
}
