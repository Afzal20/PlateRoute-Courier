import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/queue/offline_queue.dart';
import 'active_task_controller.dart';
import 'app_providers.dart';
import 'settings_controller.dart';

/// Ping ingestion loop (MOB-CUR-06). Batches fixes on the settings interval
/// and either sends or queues them (30-day server retention per NFR-13).
/// Opt-in: only runs when the courier goes online AND tracking != off.
class PingSync {
  PingSync(this._ref);

  final Ref _ref;
  Timer? _timer;
  StreamSubscription<dynamic>? _sub;
  final List<Map<String, Object?>> _batch = [];

  void start() {
    stop(keepFlush: true);
    final preset = _ref.read(settingsProvider).pingInterval;
    final duration = preset.duration;
    if (duration == null) return; // explicit opt-out — battery honesty

    _sub = _ref.read(locationServiceProvider).stream.listen((fix) {
      final task = _ref.read(activeTaskProvider);
      _batch.add({
        'lat': fix.lat,
        'lng': fix.lng,
        if (fix.speedMps >= 0) 'speed': fix.speedMps.round(),
        if (fix.headingDeg != null) 'heading': fix.headingDeg!.round(),
        if (task != null) 'task': task.taskUuid,
      });
      if (_batch.length >= 10) unawaited(flush());
    });

    _timer = Timer.periodic(duration, (_) => unawaited(flush()));
  }

  Future<void> flush() async {
    if (_batch.isEmpty) return;
    final pings = List<Map<String, Object?>>.of(_batch);
    _batch.clear();
    try {
      await _ref.read(apiClientProvider).send<void>(
            (dio) => dio.post('delivery/pings/', data: {'pings': pings}),
          );
    } on Object {
      await _ref.read(offlineQueueProvider).enqueue(QueueItem(
            id: 'pings_${DateTime.now().millisecondsSinceEpoch}',
            type: QueueActionType.pingBatch,
            payload: {'pings': pings},
            createdAt: DateTime.now(),
          ));
    }
  }

  void stop({bool keepFlush = false}) {
    _timer?.cancel();
    _timer = null;
    _sub?.cancel();
    _sub = null;
    if (keepFlush) unawaited(flush());
  }
}

/// Offline queue depth for the banner (MOB-CUR-07): "N actions saved, will
/// send". Drives manual retry and measures flush lag (p95 instrumentation).
class OfflineQueueController extends Notifier<int> {
  @override
  int build() {
    _init();
    return 0;
  }

  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    final queue = ref.read(offlineQueueProvider);
    await queue.init(connectivity: ref.read(connectivityRawProvider));
    state = await queue.pendingDepth();
    queue.pendingCount.listen((depth) => state = depth);
  }

  Future<void> flushNow() async {
    final depthBefore = state;
    if (depthBefore == 0) return;
    final startedAt = DateTime.now();
    final flushed = await ref.read(offlineQueueProvider).flush();
    final lagMs = DateTime.now().difference(startedAt).inMilliseconds;
    state = await ref.read(offlineQueueProvider).pendingDepth();
    ref
        .read(analyticsProvider)
        .offlineQueueFlushLag(lagMs: lagMs, depth: depthBefore);
    await ref.read(offlineQueueProvider).compact();
    assert(flushed >= 0);
  }
}

final offlineQueueDepthProvider =
    NotifierProvider<OfflineQueueController, int>(OfflineQueueController.new);

final pingSyncProvider = Provider<PingSync>((ref) {
  final sync = PingSync(ref);
  ref.onDispose(() => sync.stop(keepFlush: true));
  return sync;
});
