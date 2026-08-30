import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/location_service.dart';
import '../core/theme/tokens.dart';
import '../core/utils/geo.dart';
import '../data/models/active_task.dart';
import '../data/models/offer.dart';
import 'active_task_controller.dart';
import 'app_providers.dart';

/// Motion gating state (MOB-C-*, design §10): above ~7 km/h interactive
/// cards collapse to inert breathing-outline strips and actions raise the
/// "Pull over to continue" sheet — guidance, never a hard block.
class MotionState {
  const MotionState({
    this.isMoving = false,
    this.latest,
    this.activeTask,
  });

  final bool isMoving;
  final LocationFix? latest;
  final ActiveTask? activeTask;

  /// True when the courier is within the dropoff/pickup geofence with a
  /// trustworthy fix — flips the AddressBlock border blue ("near the gate").
  bool isNearTarget() {
    final task = activeTask;
    final fix = latest;
    if (task == null || fix == null) return false;
    final (lat, lng) = switch (task.stage) {
      TripStage.toPickup => (task.pickupLat, task.pickupLng),
      _ => (task.dropoffLat, task.dropoffLng),
    };
    return LocationService.isNearGeofence(fix, lat, lng);
  }
}

class MotionController extends Notifier<MotionState> {
  @override
  MotionState build() {
    ref.listen(locationFixStreamProvider, (_, next) {
      next.whenData((fix) {
        state = MotionState(
          isMoving: fix.isMoving,
          latest: fix,
          activeTask: state.activeTask,
        );
      });
    });
    ref.listen(activeTaskProvider, (_, task) {
      state = MotionState(
        isMoving: state.isMoving,
        latest: state.latest,
        activeTask: task,
      );
    });
    return const MotionState();
  }

  bool get showPullOverGate => state.isMoving;
}

final motionProvider =
    NotifierProvider<MotionController, MotionState>(MotionController.new);

/// Distance chips for the active task, recomputed from the latest fix.
(double pickupM, double dropoffM)? distancesOf(LocationFix? fix, ActiveTask? task) {
  if (fix == null || task == null) return null;
  return (
    Geo.haversineM(fix.lat, fix.lng, task.pickupLat, task.pickupLng),
    Geo.haversineM(fix.lat, fix.lng, task.dropoffLat, task.dropoffLng),
  );
}

double motionSpeedKmh(LocationFix? fix) {
  if (fix == null || fix.speedMps < 0) return 0;
  return fix.speedMps * 3.6;
}

/// Convenience: is motion gating active for the current user context?
bool isMotionGated(MotionState state) =>
    state.isMoving && state.activeTask != null;

const motionThresholdKmh = AppTokens.motionSpeedThresholdMps * 3.6;
