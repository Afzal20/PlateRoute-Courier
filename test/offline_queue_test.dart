import 'package:flutter_test/flutter_test.dart';
import 'package:courier/core/queue/offline_queue.dart';
import 'package:courier/core/storage/json_store.dart';
import 'package:courier/core/network/api_client.dart';
import 'package:courier/core/storage/secure_token_store.dart';

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
  test('OfflineQueue enqueues items', () async {
    final store = FakeJsonStore('offline_queue');
    final api = ApiClient(tokens: SecureTokenStore());
    final queue = OfflineQueue(store: store, api: api);
    
    await queue.enqueue(QueueItem(id: '1', type: QueueActionType.pingBatch, payload: {}, createdAt: DateTime.now()));
    
    final all = await store.readAll();
    final items = all['items'] as List;
    expect(items.length, 1);
  });
}
