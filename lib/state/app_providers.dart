import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../core/network/api_client.dart';
import '../core/queue/offline_queue.dart';
import '../core/services/analytics_service.dart';
import '../core/services/haptics_service.dart';
import '../core/services/location_service.dart';
import '../core/storage/json_store.dart';
import '../core/storage/secure_token_store.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/courier_repository.dart';
import '../data/repositories/earnings_calculator.dart';
import '../data/repositories/task_log_repository.dart';

// ---- Singletons (kept simple and injectable for tests) ----

final secureTokenStoreProvider =
    Provider<SecureTokenStore>((ref) => SecureTokenStore());

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(tokens: ref.watch(secureTokenStoreProvider));
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(
      api: ref.watch(apiClientProvider),
      tokens: ref.watch(secureTokenStoreProvider),
    ));

final courierRepositoryProvider =
    Provider<CourierRepository>((ref) => CourierRepository(api: ref.watch(apiClientProvider)));

final hapticsProvider = Provider<Haptics>((ref) => Haptics());

final analyticsProvider = Provider<Analytics>((ref) => Analytics());

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(service.dispose);
  return service;
});

final offlineQueueStoreProvider =
    Provider<JsonStore>((ref) => JsonStore('offline_queue'));
final taskLogStoreProvider =
    Provider<JsonStore>((ref) => JsonStore('task_log'));
final settingsStoreProvider =
    Provider<JsonStore>((ref) => JsonStore('settings'));
final activeTaskStoreProvider =
    Provider<JsonStore>((ref) => JsonStore('active_task'));

final offlineQueueProvider = Provider<OfflineQueue>((ref) {
  final queue = OfflineQueue(
    store: ref.watch(offlineQueueStoreProvider),
    api: ref.watch(apiClientProvider),
  );
  ref.onDispose(queue.dispose);
  return queue;
});

final taskLogRepositoryProvider = Provider<TaskLogRepository>(
    (ref) => TaskLogRepository(store: ref.watch(taskLogStoreProvider)));

final ticketRepositoryProvider =
    Provider<TicketRepository>((ref) => TicketRepository(api: ref.watch(apiClientProvider)));

final earningsCalculatorProvider =
    Provider<EarningsCalculator>((ref) => const EarningsCalculator());

final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>(
    (ref) => Connectivity().onConnectivityChanged);

/// Raw stream (for services that need to subscribe, not rebuild).
final connectivityRawProvider = Provider<Stream<List<ConnectivityResult>>>(
    (ref) => Connectivity().onConnectivityChanged);

/// Raw location fixes shared by motion gating, geofence hints and pings.
final locationFixStreamProvider =
    StreamProvider<LocationFix>((ref) => ref.watch(locationServiceProvider).stream);
