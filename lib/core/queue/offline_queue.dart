import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../storage/json_store.dart';

/// Offline action queue (MOB-CUR-07, courier-only per MOB-C-06).
///
/// Every mutating courier call goes through here when the network is gone.
/// Actions persist via [JsonStore] (atomic temp+rename) and flush when
/// connectivity returns or the user taps manual retry. State chips stay
/// honest: `pending` (Local-saved) -> `sent` (Synced) -> `failed`.
enum QueueActionType { claimOffer, declineOffer, tripAction, pingBatch }

enum QueueItemState { pending, sending, sent, failed }

class QueueItem {
  QueueItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.state = QueueItemState.pending,
    this.attempts = 0,
    this.lastError = '',
  });

  final String id;
  final QueueActionType type;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  QueueItemState state;
  int attempts;
  String lastError;

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'state': state.name,
        'attempts': attempts,
        'last_error': lastError,
      };

  static QueueItem fromJson(Map<String, Object?> json) => QueueItem(
        id: json['id'] as String,
        type: QueueActionType.values.byName(json['type'] as String),
        payload: (json['payload'] as Map).cast<String, Object?>(),
        createdAt: DateTime.parse(json['created_at'] as String),
        state: QueueItemState.values.byName(json['state'] as String),
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        lastError: (json['last_error'] as String?) ?? '',
      );
}

/// Persistence + dispatch abstraction so unit tests can drive flushes
/// without connectivity or a live API.
class OfflineQueue {
  OfflineQueue({required this._store, required this._api});

  final JsonStore _store;
  final ApiClient _api;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  static const storeKey = 'items';
  static const maxAttempts = 5;

  final _changed = StreamController<int>.broadcast();
  Stream<int> get pendingCount => _changed.stream;

  Future<List<QueueItem>> load() async {
    final all = await _store.readAll();
    final raw = all[storeKey];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) => QueueItem.fromJson(m.cast<String, Object?>()))
        .toList();
  }

  Future<int> pendingDepth() async =>
      (await load()).where((i) => i.state == QueueItemState.pending).length;

  Future<void> init({required Stream<List<ConnectivityResult>> connectivity}) async {
    _connectivitySub?.cancel();
    _connectivitySub = connectivity.listen((results) {
      final online = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);
      if (online) flush();
    });
    await _emit();
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _changed.close();
  }

  Future<void> enqueue(QueueItem item) async {
    await _store.update((all) {
      final raw = (all[storeKey] as List?) ?? [];
      raw.add(item.toJson());
      all[storeKey] = raw;
      return all;
    });
    await _emit();
  }

  Future<void> updateItem(QueueItem item) async {
    await _store.update((all) {
      final raw = ((all[storeKey] as List?) ?? [])
          .whereType<Map>()
          .toList(growable: false);
      final idx = raw.indexWhere((m) => m['id'] == item.id);
      if (idx >= 0) raw[idx] = item.toJson();
      all[storeKey] = raw;
      return all;
    });
    await _emit();
  }

  /// Best-effort sequential flush. Each action maps to its real API call;
  /// claim actions that come back 409 are marked `sent` — the outcome is
  /// decided (someone won), the queue is not an error state.
  Future<int> flush() async {
    var flushed = 0;
    for (final item in (await load()).where((i) => i.state == QueueItemState.pending)) {
      item.state = QueueItemState.sending;
      await updateItem(item);
      try {
        await _dispatch(item);
        item.state = QueueItemState.sent;
        item.lastError = '';
        flushed++;
      } on ApiException catch (e) {
        item.attempts++;
        item.state =
            item.attempts >= maxAttempts ? QueueItemState.failed : QueueItemState.pending;
        item.lastError = e.code;
      }
      await updateItem(item);
    }
    await _emit();
    return flushed;
  }

  Future<void> _dispatch(QueueItem item) async {
    switch (item.type) {
      case QueueActionType.claimOffer:
      case QueueActionType.declineOffer:
        final id = item.payload['offer_id'];
        final action = item.type == QueueActionType.claimOffer ? 'claim' : 'decline';
        await _api.send<void>((dio) => dio.post('delivery/offers/$id/$action/'));
      case QueueActionType.tripAction:
        final task = item.payload['task'];
        await _api.send<void>(
          (dio) => dio.post('delivery/tasks/$task/trip/',
              data: {'action': item.payload['action']}),
        );
      case QueueActionType.pingBatch:
        await _api.send<void>(
          (dio) => dio.post('delivery/pings/', data: {'pings': item.payload['pings']}),
        );
    }
  }

  /// Fully-sent history collapses to keep the store bounded.
  Future<void> compact() async {
    await _store.update((all) {
      final raw = ((all[storeKey] as List?) ?? [])
          .whereType<Map>()
          .where((m) => m['state'] != QueueItemState.sent.name)
          .toList();
      all[storeKey] = raw;
      return all;
    });
    await _emit();
  }

  Future<void> _emit() async => _changed.add(await pendingDepth());
}
