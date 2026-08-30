import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/queue/offline_queue.dart';
import '../data/models/profile.dart';
import 'app_providers.dart';
import 'auth_controller.dart';
import 'ping_sync.dart';

/// Shift console (MOB-CUR-01): courier profile + online/offline toggle.
/// Going online starts the location service + ping batching; going offline
/// stops them. Offline toggles queue locally and reconcile on flush.
class ShiftController extends AsyncNotifier<CourierProfile?> {
  @override
  Future<CourierProfile?> build() async {
    final user = ref.watch(authProvider).value;
    if (user == null) return null;
    final profile = await ref.read(courierRepositoryProvider).fetchProfile();
    if (profile.isOnline) await _startTracking();
    return profile;
  }

  Future<void> toggleOnline() async {
    final current = state.value;
    if (current == null) return;
    final next = !current.isOnline;
    try {
      final result =
          await ref.read(courierRepositoryProvider).updateProfile(online: next);
      state = AsyncData<CourierProfile?>(_replaced(current, isOnline: result.isOnline));
      if (result.isOnline) {
        await _startTracking();
      } else {
        await ref.read(locationServiceProvider).stop();
        ref.read(pingSyncProvider).stop();
      }
    } on Object {
      // Offline honesty: queue the shift change, reflect optimistically,
      // chip flips Local-saved -> Synced when the flush lands (MOB-CUR-07).
      await ref.read(offlineQueueProvider).enqueue(QueueItem(
            id: 'shift_${DateTime.now().millisecondsSinceEpoch}',
            type: QueueActionType.shiftToggle,
            payload: {'online': next},
            createdAt: DateTime.now(),
          ));
      state = AsyncData<CourierProfile?>(_replaced(current, isOnline: next));
      if (next) {
        await _startTracking();
      } else {
        await ref.read(locationServiceProvider).stop();
        ref.read(pingSyncProvider).stop();
      }
    }
  }

  Future<void> saveVehicle(
      VehicleType vehicle, String plate, String license) async {
    final current = state.value ?? const CourierProfile();
    try {
      await ref
          .read(courierRepositoryProvider)
          .updateProfile(vehicle: vehicle, plate: plate, license: license);
      state = AsyncData<CourierProfile?>(current.copyWith(
        vehicle: vehicle,
        plate: plate,
        license: license,
      ));
    } on Object {
      // Queue the profile save; optimistic local reflection.
      await ref.read(offlineQueueProvider).enqueue(QueueItem(
            id: 'vehicle_${DateTime.now().millisecondsSinceEpoch}',
            type: QueueActionType.profileUpdate,
            payload: {'vehicle': vehicle.name, 'plate': plate, 'license': license},
            createdAt: DateTime.now(),
          ));
      state = AsyncData<CourierProfile?>(current.copyWith(
        vehicle: vehicle,
        plate: plate,
        license: license,
      ));
    }
  }

  Future<void> _startTracking() async {
    await ref.read(locationServiceProvider).start();
    ref.read(pingSyncProvider).start();
  }

  CourierProfile _replaced(CourierProfile current, {required bool isOnline}) =>
      CourierProfile(
        vehicle: current.vehicle,
        plate: current.plate,
        license: current.license,
        isOnline: isOnline,
        lastOnlineAt: isOnline ? DateTime.now() : current.lastOnlineAt,
      );
}

final shiftProvider =
    AsyncNotifierProvider<ShiftController, CourierProfile?>(ShiftController.new);
