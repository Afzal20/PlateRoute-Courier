import 'dart:math' as math;

/// Geo helpers mirroring `backend/common/geo.py` (haversine) so client-side
/// distance chips reconcile with dispatch math.
abstract final class Geo {
  static const earthRadiusM = 6371000.0;

  /// Great-circle distance in meters.
  static double haversineM(double lat1, double lng1, double lat2, double lng2) {
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadiusM * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180.0;

  /// "2.4 km" / "650 m" for glance-sized chips.
  static String humanDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  /// Coarse zone word derived from a lat/lng grid. The backend does not yet
  /// send named zones with offers, so we derive a stable, honest label from
  /// coordinates instead of inventing venue names.
  static String zoneWordOf(double lat, double lng) {
    final latBand = String.fromCharCode(65 + ((lat.abs() * 40).floor() % 26));
    final lngBand = ((lng.abs() * 40).floor() % 8) + 1;
    return 'Zone $latBand$lngBand';
  }
}
