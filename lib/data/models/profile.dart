/// Courier domain models mapped 1:1 onto the PlateRoute REST payloads
/// (see `backend/delivery/views.py`). All money fields are minor units.
enum VehicleType { bike, bicycle, car }

extension VehicleTypeX on VehicleType {
  String get label => switch (this) {
        VehicleType.bike => 'Bike',
        VehicleType.bicycle => 'Bicycle',
        VehicleType.car => 'Car',
      };
}

class CourierProfile {
  const CourierProfile({
    this.vehicle = VehicleType.bike,
    this.plate = '',
    this.license = '',
    this.isOnline = false,
    this.lastOnlineAt,
  });

  final VehicleType vehicle;
  final String plate;
  final String license;
  final bool isOnline;
  final DateTime? lastOnlineAt;

  factory CourierProfile.fromJson(Map<String, Object?> json) => CourierProfile(
        vehicle: VehicleType.values.firstWhere(
          (v) => v.name == json['vehicle'],
          orElse: () => VehicleType.bike,
        ),
        plate: (json['plate'] as String?) ?? '',
        license: (json['license'] as String?) ?? '',
        isOnline: json['is_online'] == true,
        lastOnlineAt: json['last_online_at'] == null
            ? null
            : DateTime.tryParse(json['last_online_at'] as String),
      );
}
