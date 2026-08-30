import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/tokens.dart';
import '../utils/geo.dart';

/// One location fix feeding three consumers (NFR-16 battery honesty):
///  - ping ingestion (batched, interval from settings)
///  - motion gating (speed > ~7 km/h collapses interactive cards)
///  - geofence hint ("You are near the gate" via accuracy thresholds)
class LocationFix {
  const LocationFix({
    required this.lat,
    required this.lng,
    required this.speedMps,
    required this.headingDeg,
    required this.accuracyM,
    required this.recordedAt,
  });

  final double lat;
  final double lng;
  final double speedMps; // -1 when unknown
  final double? headingDeg;
  final double accuracyM;
  final DateTime recordedAt;

  bool get isMoving => speedMps > AppTokens.motionSpeedThresholdMps;
}

enum LocationPermissionState { notDetermined, denied, whileInUse, always }

class LocationService {
  LocationService();

  StreamSubscription<Position>? _sub;
  final _controller = StreamController<LocationFix>.broadcast();

  LocationFix? latest;
  LocationPermissionState permissionState = LocationPermissionState.notDetermined;

  Stream<LocationFix> get stream => _controller.stream;

  /// NFR-16 purpose-string pre-prompt: callers show the explanation dialog
  /// FIRST, then invoke this. `whileInUse` is the working permission; the
  /// foreground service keeps fixes alive while the shift runs.
  Future<LocationPermissionState> ensurePermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted || status.isLimited) {
      permissionState = LocationPermissionState.whileInUse;
    } else if (status.isPermanentlyDenied) {
      permissionState = LocationPermissionState.denied;
    } else {
      final result = await Permission.locationWhenInUse.request();
      permissionState =
          result.isGranted ? LocationPermissionState.whileInUse : LocationPermissionState.denied;
    }
    return permissionState;
  }

  Future<bool> start({Duration interval = const Duration(seconds: 10)}) async {
    if (permissionState != LocationPermissionState.whileInUse &&
        permissionState != LocationPermissionState.always) {
      final state = await ensurePermission();
      if (state != LocationPermissionState.whileInUse &&
          state != LocationPermissionState.always) {
        return false;
      }
    }
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    await _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        timeLimit: const Duration(minutes: 2),
      ),
    ).listen(
      (pos) {
        latest = LocationFix(
          lat: pos.latitude,
          lng: pos.longitude,
          speedMps: pos.speed >= 0 ? pos.speed : -1,
          headingDeg: pos.heading >= 0 ? pos.heading : null,
          accuracyM: pos.accuracy,
          recordedAt: pos.timestamp,
        );
        if (!_controller.isClosed) _controller.add(latest!);
      },
      onError: (Object _) {/* stream resumes; keep last fix */},
    );
    return true;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Accuracy-threshold gate for the blue "near the gate" border:
  /// within [radiusM] AND fix is trustworthy (accuracy better than 40m).
  static bool isNearGeofence(LocationFix? fix, double lat, double lng,
      {double radiusM = AppTokens.geofenceNearMeters}) {
    if (fix == null || fix.accuracyM > 40) return false;
    return Geo.haversineM(fix.lat, fix.lng, lat, lng) <= radiusM;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
