import 'dart:convert';

import 'offer.dart';

/// The courier's currently claimed task. Built from the claim response +
/// the original offer (address coords, fee) and enriched from tracking.
class ActiveTask {
  const ActiveTask({
    required this.taskUuid,
    required this.orderUuid,
    required this.stage,
    required this.feeMinor,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.promisedEtaMinutes,
    this.orderStatus,
    this.codMinor = 0,
    this.tipMinor = 0,
    this.claimedAt,
  });

  final String taskUuid;
  final String orderUuid;
  final TripStage stage;
  final int feeMinor;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final int promisedEtaMinutes;
  final String? orderStatus;

  /// COD is boxed separately everywhere (double-count confusion guard);
  /// server does not yet expose it, so it stays 0/hidden until present.
  final int codMinor;
  final int tipMinor;
  final DateTime? claimedAt;

  ActiveTask withStage(TripStage stage, {String? orderStatus}) => ActiveTask(
        taskUuid: taskUuid,
        orderUuid: orderUuid,
        stage: stage,
        feeMinor: feeMinor,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropoffLat: dropoffLat,
        dropoffLng: dropoffLng,
        promisedEtaMinutes: promisedEtaMinutes,
        orderStatus: orderStatus ?? this.orderStatus,
        codMinor: codMinor,
        tipMinor: tipMinor,
        claimedAt: claimedAt,
      );

  Map<String, Object?> toJson() => {
        'task_uuid': taskUuid,
        'order_uuid': orderUuid,
        'stage': stage.name,
        'fee_minor': feeMinor,
        'pickup': [pickupLat, pickupLng],
        'dropoff': [dropoffLat, dropoffLng],
        'promised_eta_minutes': promisedEtaMinutes,
        'order_status': orderStatus,
        'cod_minor': codMinor,
        'tip_minor': tipMinor,
        'claimed_at': claimedAt?.toIso8601String(),
      };

  static ActiveTask fromJson(Map<String, Object?> json) {
    final pickup = (json['pickup'] as List).cast<num>();
    final dropoff = (json['dropoff'] as List).cast<num>();
    return ActiveTask(
      taskUuid: json['task_uuid'] as String,
      orderUuid: json['order_uuid'] as String,
      stage: TripStage.values.byName(json['stage'] as String),
      feeMinor: (json['fee_minor'] as num).toInt(),
      pickupLat: pickup[0].toDouble(),
      pickupLng: pickup[1].toDouble(),
      dropoffLat: dropoff[0].toDouble(),
      dropoffLng: dropoff[1].toDouble(),
      promisedEtaMinutes: (json['promised_eta_minutes'] as num?)?.toInt() ?? 45,
      orderStatus: json['order_status'] as String?,
      codMinor: (json['cod_minor'] as num?)?.toInt() ?? 0,
      tipMinor: (json['tip_minor'] as num?)?.toInt() ?? 0,
      claimedAt: json['claimed_at'] == null
          ? null
          : DateTime.parse(json['claimed_at'] as String),
    );
  }

  String encode() => jsonEncode(toJson());

  static ActiveTask decode(String raw) =>
      ActiveTask.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
}
