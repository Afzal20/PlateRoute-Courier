import '../../core/network/api_client.dart';
import '../../core/storage/json_store.dart';
import '../models/active_task.dart';
import '../models/offer.dart';
import '../models/support.dart';
import '../models/task_record.dart';

/// Local task log: the courier's own trip history + POD attachments.
///
/// The backend does not yet expose courier task-history or ledger endpoints;
/// until it does, history (MOB-CUR-08) and earnings (MOB-CUR-05) derive from
/// this log, which records every stage event the app itself drove. Rows are
/// keyed by task uuid in a JsonStore document.
class TaskLogRepository {
  TaskLogRepository({required this._store});

  final JsonStore _store;
  static const _key = 'tasks';

  Future<List<TaskRecord>> load() async {
    final all = await _store.readAll();
    final raw = all[_key];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((m) => TaskRecord.fromJson(m.cast<String, Object?>())).toList();
  }

  Future<TaskRecord?> byTask(String taskUuid) async {
    for (final r in await load()) {
      if (r.taskUuid == taskUuid) return r;
    }
    return null;
  }

  /// Called at claim time — starts the trail.
  Future<void> recordClaim(ActiveTask task) async {
    await _store.update((all) {
      final raw = (all[_key] as List?) ?? [];
      if (raw.any((m) => (m as Map)['task_uuid'] == task.taskUuid)) return all;
      raw.add(TaskRecord(
        taskUuid: task.taskUuid,
        orderUuid: task.orderUuid,
        feeMinor: task.feeMinor,
        claimedAt: task.claimedAt ?? DateTime.now(),
        tipMinor: task.tipMinor,
        codMinor: task.codMinor,
        trail: [(task.stage, DateTime.now())],
      ).toJson());
      all[_key] = raw;
      return all;
    });
  }

  Future<void> recordStage(String taskUuid, TripStage stage) async {
    await _store.update((all) {
      final raw = (all[_key] as List?) ?? [];
      final idx = raw.indexWhere((m) => (m as Map)['task_uuid'] == taskUuid);
      if (idx < 0) return all;
      final record = TaskRecord.fromJson((raw[idx] as Map).cast<String, Object?>());
      raw[idx] = record
          .copyWith(
            trail: [...record.trail, (stage, DateTime.now())],
            droppedAt: stage == TripStage.delivered ? DateTime.now() : null,
          )
          .toJson();
      all[_key] = raw;
      return all;
    });
  }

  Future<void> attachPod(String taskUuid, String podPath) =>
      _patch(taskUuid, (r) => r.copyWith(podPath: podPath));

  Future<void> attachTicket(String taskUuid, String ticketUuid) =>
      _patch(taskUuid, (r) => r.copyWith(ticketUuid: ticketUuid));

  Future<void> _patch(
      String taskUuid, TaskRecord Function(TaskRecord) mutate) async {
    await _store.update((all) {
      final raw = (all[_key] as List?) ?? [];
      final idx = raw.indexWhere((m) => (m as Map)['task_uuid'] == taskUuid);
      if (idx < 0) return all;
      final record =
          TaskRecord.fromJson((raw[idx] as Map).cast<String, Object?>());
      raw[idx] = mutate(record).toJson();
      all[_key] = raw;
      return all;
    });
  }
}

/// Support tickets (list / open / thread / reply).
class TicketRepository {
  TicketRepository({required this._api});

  final ApiClient _api;

  Future<List<Ticket>> list() async {
    final data = await _api.send<List<Object?>>(
      (dio) => dio.get('support/tickets/'),
    );
    return [
      for (final row in data)
        Ticket.fromJson((row as Map).cast<String, Object?>())
    ];
  }

  Future<TicketThread> thread(String uuid) async {
    final data = await _api.send<Map<String, Object?>>(
      (dio) => dio.get('support/tickets/$uuid/'),
    );
    return TicketThread.fromJson(data);
  }

  Future<String> open({
    required String subject,
    required String message,
    String? orderUuid,
    String category = 'order_issue',
  }) async {
    final data = await _api.send<Map<String, Object?>>(
      (dio) => dio.post('support/tickets/', data: {
        'subject': subject,
        'message': message,
        'category': category,
        if (orderUuid != null && orderUuid.isNotEmpty) 'order': orderUuid,
      }),
    );
    return data['uuid'] as String;
  }

  Future<void> reply(String uuid, String message) async {
    await _api.send<void>(
      (dio) => dio.post('support/tickets/$uuid/',
          data: {'message': message}),
    );
  }
}
