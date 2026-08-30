import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../core/queue/offline_queue.dart';
import '../core/services/haptics_service.dart';
import '../core/storage/json_store.dart';
import '../data/models/active_task.dart';
import '../data/models/offer.dart';
import 'app_providers.dart';
import 'earnings_controller.dart';

/// The claimed task (MOB-CUR-03/04): stage transitions, offline tolerance,
/// and persistence so an app kill mid-trip never loses the shift.
class ActiveTaskController extends Notifier<ActiveTask?> {
  static const _storeKey = 'active_task';

  @override
  ActiveTask? build() {
    _hydrate();
    return null;
  }

  bool _hydrated = false;

  Future<void> _hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    final all = await ref.read(_taskStore).readAll();
    final raw = all[_storeKey];
    if (raw is String) {
      final task = ActiveTask.decode(raw);
      state = task.stage == TripStage.delivered ? null : task;
    }
  }

  Future<void> setFromClaim(ActiveTask task) async {
    state = task;
    await _persist();
    await ref.read(taskLogRepositoryProvider).recordClaim(task);
  }

  /// Advance one stage via `trip/`. Online: server arbitration, family D
  /// haptic on unlock. Offline: optimistic stage + queued action (MOB-CUR-07).
  Future<StageResult> advanceStage() async {
    final task = state;
    if (task == null) return StageResult.failed;
    final action = task.stage.nextAction;
    if (action == null) return StageResult.failed;
    try {
      final updated =
          await ref.read(courierRepositoryProvider).tripAction(task, action);
      state = updated;
      await _persist();
      ref.read(hapticsProvider).play(HapticFamily.stageUnlock);
      await ref
          .read(taskLogRepositoryProvider)
          .recordStage(task.taskUuid, updated.stage);
      ref.invalidate(earningsProvider);
      return StageResult.advanced;
    } on ApiException catch (e) {
      if (e.isNetwork) {
        // Optimistic local stage + queue for the honest Local-saved chip.
        final optimistic = task.withStage(_nextStage(task.stage));
        state = optimistic;
        await _persist();
        await ref.read(taskLogRepositoryProvider).recordStage(task.taskUuid, optimistic.stage);
        await ref.read(offlineQueueProvider).enqueue(QueueItem(
              id: 'trip_${task.taskUuid}_${DateTime.now().millisecondsSinceEpoch}',
              type: QueueActionType.tripAction,
              payload: {'task': task.taskUuid, 'action': action},
              createdAt: DateTime.now(),
            ));
        return StageResult.queued;
      }
      rethrow;
    }
  }

  String? podPath;

  Future<void> attachPod(String path) async {
    podPath = path;
    final task = state;
    if (task != null) {
      await ref.read(taskLogRepositoryProvider).attachPod(task.taskUuid, path);
    }
  }

  Future<void> markDelivered() async {
    final task = state;
    if (task == null) return;
    state = task.withStage(TripStage.delivered);
    await _persist();
  }

  /// Called after the "Delivered. Well done today." moment is acknowledged.
  Future<void> clearDelivered() async {
    if (state?.stage == TripStage.delivered) {
      state = null;
      podPath = null;
      await ref.read(_taskStore).update((all) {
        all.remove(_storeKey);
        return all;
      });
    }
  }

  TripStage _nextStage(TripStage stage) => switch (stage) {
        TripStage.toPickup => TripStage.atVendor,
        TripStage.atVendor => TripStage.out,
        TripStage.picked || TripStage.out => TripStage.atDropoff,
        TripStage.atDropoff => TripStage.delivered,
        TripStage.delivered => TripStage.delivered,
      };

  Future<void> _persist() async {
    final task = state;
    await ref.read(_taskStore).update((all) {
      if (task == null || task.stage == TripStage.delivered) {
        all.remove(_storeKey);
      } else {
        all[_storeKey] = task.encode();
      }
      return all;
    });
  }
}

enum StageResult { advanced, queued, failed }

final _taskStore = Provider<JsonStore>((ref) => JsonStore('active_task'));

final activeTaskProvider =
    NotifierProvider<ActiveTaskController, ActiveTask?>(ActiveTaskController.new);
