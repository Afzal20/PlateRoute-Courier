import 'dart:async';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/active_task.dart';
import '../models/offer.dart';
import '../models/profile.dart';

/// Courier REST surface: profile/shift, offers, claim, trip, pings, tracking.
class CourierRepository {
  CourierRepository({required this._api});

  final ApiClient _api;

  // ---- MOB-CUR-01: shift console + vehicle snapshot ----

  Future<CourierProfile> fetchProfile() async {
    final data = await _api.send<Map<String, Object?>>(
      (dio) => dio.get('delivery/profile/'),
    );
    return CourierProfile.fromJson(data);
  }

  /// PUT /delivery/profile/ {vehicle?, plate?, license?, online?}.
  Future<({bool isOnline, VehicleType vehicle})> updateProfile({
    VehicleType? vehicle,
    String? plate,
    String? license,
    bool? online,
  }) async {
    final data = await _api.send<Map<String, Object?>>(
      (dio) => dio.put('delivery/profile/', data: {
        'vehicle': ?vehicle?.name,
        'plate': ?plate,
        'license': ?license,
        'online': ?online,
      }),
    );
    return (
      isOnline: data['is_online'] == true,
      vehicle: VehicleType.values.firstWhere(
        (v) => v.name == data['vehicle'],
        orElse: () => VehicleType.bike,
      ),
    );
  }

  // ---- MOB-CUR-02: offer feed + atomic claim ----

  Future<List<Offer>> fetchOffers() async {
    final data = await _api.send<List<Object?>>(
      (dio) => dio.get('delivery/offers/'),
    );
    return [
      for (final row in data) Offer.fromJson((row as Map).cast<String, Object?>())
    ];
  }

  /// Atomic claim (FR-DLV-03). Returns the claimed task on success.
  /// Throws [ApiException] with `isClaimLost` when another rider won.
  Future<ActiveTask> claim(Offer offer) async {
    final data = await _api.send<Map<String, Object?>>(
      (dio) => dio.post('delivery/offers/${offer.id}/claim/'),
    );
    final serverState = data['state'] as String? ?? 'claimed';
    return ActiveTask(
      taskUuid: data['task'] as String,
      orderUuid: '', // enriched by tracking fetch
      stage: TripStageX.fromServerState(serverState),
      feeMinor: offer.feeMinor,
      pickupLat: offer.pickupLat,
      pickupLng: offer.pickupLng,
      dropoffLat: offer.dropoffLat,
      dropoffLng: offer.dropoffLng,
      promisedEtaMinutes: offer.promisedEtaMinutes,
      claimedAt: DateTime.now(),
    );
  }

  Future<void> decline(Offer offer) async {
    await _api.send<void>(
      (dio) => dio.post('delivery/offers/${offer.id}/decline/'),
    );
  }

  // ---- MOB-CUR-03: stage transitions ----

  Future<ActiveTask> tripAction(ActiveTask task, String action) async {
    final data = await _api.send<Map<String, Object?>>(
      (dio) => dio.post('delivery/tasks/${task.taskUuid}/trip/', data: {'action': action}),
    );
    return task.withStage(
      TripStageX.fromServerState(data['state'] as String? ?? task.stage.name),
      orderStatus: data['order_status'] as String?,
    );
  }

  // ---- MOB-CUR-06: ping ingestion ----

  Future<void> sendPings(List<Map<String, Object?>> pings) async {
    if (pings.isEmpty) return;
    await _api.send<void>(
      (dio) => dio.post('delivery/pings/', data: {'pings': pings}),
    );
  }

  // ---- Tracking (enriches the active task) ----

  Future<ActiveTask?> fetchTracking(ActiveTask task) async {
    final uuid = task.orderUuid.isNotEmpty ? task.orderUuid : task.taskUuid;
    try {
      final data = await _api.send<Map<String, Object?>>(
        (dio) => dio.get('delivery/orders/$uuid/tracking/'),
      );
      final status = data['order_status'] as String?;
      return status == null
          ? task
          : task.withStage(task.stage, orderStatus: status);
    } on ApiException {
      return null;
    }
  }
}
