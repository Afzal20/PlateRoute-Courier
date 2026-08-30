import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment contract loaded from `.env` (never commit real values).
///
/// `.env` ships dev defaults pointing at the local Django backend:
/// `API_BASE_URL=http://10.0.2.2:8000/api/v1/`.
class Env {
  Env._();

  static late String _root;

  /// e.g. `http://10.0.2.2:8000` — derived from API_BASE_URL.
  static String get apiRoot => _root;

  /// Versioned REST base: `{root}/api/v1/`.
  static String get apiV1 => '$apiRoot/api/v1/';

  /// Un-versioned auth base: `{root}/api/auth/`.
  static String get apiAuth => '$apiRoot/api/auth/';

  static String get wsUrl => dotenv.maybeGet('WS_BASE_URL') ?? '';
  static String get mapTileUrl =>
      dotenv.maybeGet('MAP_TILE_URL_TEMPLATE') ?? '';
  static String get osrmBaseUrl => dotenv.maybeGet('OSRM_BASE_URL') ?? '';
  static String get sentryDsn => dotenv.maybeGet('SENTRY_DSN') ?? '';

  /// Default ping cadence for the foreground service (NFR-16 battery honesty).
  static int get pingIntervalSeconds =>
      int.tryParse(dotenv.maybeGet('PING_INTERVAL_SECONDS') ?? '') ?? 10;

  static Future<void> load() async {
    await dotenv.load();
    final base = dotenv.maybeGet('API_BASE_URL') ?? 'http://10.0.2.2:8000/api/v1/';
    if (base.contains('/api/v1/')) {
      _root = base.substring(0, base.indexOf('/api/v1/'));
    } else {
      _root = base.replaceAll(RegExp(r'/+$'), '');
    }
  }
}
