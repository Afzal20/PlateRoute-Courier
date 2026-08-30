import 'dart:async';

import 'package:flutter/foundation.dart';

/// UX instrumentation events (COURIER_APP_UI.md §13). Client-side records are
/// kept in a bounded ring so `offer_response_ms` can be reconciled against the
/// server's `delivery_offer.response_ms` column.
class Analytics {
  Analytics();

  static const _maxEvents = 500;
  final List<Map<String, Object?>> _events = [];
  final _controller = StreamController<Map<String, Object?>>.broadcast();

  Stream<Map<String, Object?>> get stream => _controller.stream;
  List<Map<String, Object?>> get events => List.unmodifiable(_events);

  void log(String name, [Map<String, Object?> params = const {}]) {
    final event = {
      'name': name,
      'ts': DateTime.now().toUtc().toIso8601String(),
      ...params,
    };
    _events.add(event);
    if (_events.length > _maxEvents) _events.removeAt(0);
    debugPrint('[analytics] $name $params');
    if (!_controller.isClosed) _controller.add(event);
  }

  // ---- Named events from §13 ----

  void offerShown({required String task, required int feeMinor}) =>
      log('offer_shown', {'task': task, 'fee_minor': feeMinor});

  void offerResponseMs({required String task, required int responseMs}) =>
      log('offer_response_ms', {'task': task, 'response_ms': responseMs});

  void claimResult(
          {required String task,
          required bool success,
          required int ringSecond,
          required int responseMs}) =>
      log('claim_result', {
        'task': task,
        'success': success,
        'ring_second': ringSecond,
        'response_ms': responseMs,
      });

  void podCaptureSeconds({required String task, required int seconds}) =>
      log('pod_capture_seconds', {'task': task, 'seconds': seconds});

  void offlineQueueFlushLag({required int lagMs, required int depth}) =>
      log('offline_queue_flush_lag', {'lag_ms': lagMs, 'depth': depth});

  void screenThemeUsage({required bool dark}) =>
      log('screen_dark_mode_usage', {'dark': dark});
}
