import 'package:flutter_test/flutter_test.dart';
import 'package:courier/data/repositories/task_log_repository.dart';
import 'package:courier/core/storage/json_store.dart';

class FakeJsonStore implements JsonStore {
  Map<String, dynamic> data = {};
  final String key;
  FakeJsonStore(this.key);
  @override
  Future<Map<String, dynamic>> readAll() async => data;
  @override
  Future<void> update(void Function(Map<String, dynamic> doc) mutation) async { mutation(data); }
  Future<void> clear() async { data.clear(); }
}

void main() {
  test('TaskLogRepository instantiates', () {
    final store = FakeJsonStore('task_log');
    final repo = TaskLogRepository(store: store);
    expect(repo, isNotNull);
  });
}
