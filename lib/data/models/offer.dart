/// A live, unexpired task offer from `GET /delivery/offers/`.
class Offer {
  const Offer({
    required this.id,
    required this.taskUuid,
    required this.feeMinor,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.promisedEtaMinutes,
    required this.expiresAt,
  });

  final int id;
  final String taskUuid;
  final int feeMinor;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final int promisedEtaMinutes;
  final DateTime expiresAt;

  factory Offer.fromJson(Map<String, Object?> json) {
    final pickup = (json['pickup'] as List).cast<num>();
    final dropoff = (json['dropoff'] as List).cast<num>();
    return Offer(
      id: (json['id'] as num).toInt(),
      taskUuid: json['task'] as String,
      feeMinor: (json['fee_minor'] as num).toInt(),
      pickupLat: pickup[0].toDouble(),
      pickupLng: pickup[1].toDouble(),
      dropoffLat: dropoff[0].toDouble(),
      dropoffLng: dropoff[1].toDouble(),
      promisedEtaMinutes: (json['promised_eta_minutes'] as num?)?.toInt() ?? 45,
      expiresAt: DateTime.parse(json['expires_at'] as String).toUtc(),
    );
  }

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
}

/// Client-side trip stages (MOB-CUR-03). Maps onto DeliveryTask.State +
/// `trip/` actions: claimed->at_vendor->picked(+out)->arrived->dropped.
enum TripStage { toPickup, atVendor, picked, out, atDropoff, delivered }

extension TripStageX on TripStage {
  /// The `trip/` action that leaves this stage, null when terminal.
  String? get nextAction => switch (this) {
        TripStage.toPickup => 'at_vendor',
        TripStage.atVendor => 'picked',
        TripStage.picked => 'arrived', // server collapses picked+out
        TripStage.out => 'arrived',
        TripStage.atDropoff => 'dropped',
        TripStage.delivered => null,
      };

  /// Server `DeliveryTask.State` value for this client stage.
  static TripStage fromServerState(String state) => switch (state) {
        'claimed' => TripStage.toPickup,
        'at_vendor' => TripStage.atVendor,
        'picked' || 'out' => TripStage.out,
        'arrived' => TripStage.atDropoff,
        'dropped' => TripStage.delivered,
        _ => TripStage.toPickup,
      };

  bool get isDropoffSide =>
      this == TripStage.picked ||
      this == TripStage.out ||
      this == TripStage.atDropoff;
}
