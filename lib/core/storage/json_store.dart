import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Tiny atomic JSON document store — the backing store for the offline action
/// queue (MOB-C-06), the local task log, and non-secret settings.
///
/// Write strategy: temp file + rename, so a battery pull mid-write can never
/// corrupt the only copy of a queued action. Swap-in for Hive per the plan;
/// the repository API stays identical.
class JsonStore {
  JsonStore(this._fileName);

  final String _fileName;
  File? _cacheFile;
  Map<String, Object?> _cache = const {};
  Future<void>? _pending;

  Future<File> get _file async {
    if (_cacheFile != null) return _cacheFile!;
    final dir = await getApplicationDocumentsDirectory();
    _cacheFile = File('${dir.path}/$_fileName.json');
    return _cacheFile!;
  }

  Future<Map<String, Object?>> readAll() async {
    final f = await _file;
    if (!await f.exists()) return {};
    try {
      final raw = await f.readAsString();
      final decoded = jsonDecode(raw);
      _cache = decoded is Map<String, Object?> ? decoded : const {};
    } on FormatException {
      _cache = const {};
    }
    return _cache;
  }

  /// Serializes writes so concurrent queue appends never lose rows.
  Future<void> update(
      FutureOr<Map<String, Object?>> Function(Map<String, Object?>) mutate) {
    if (_pending != null) {
      _pending = _pending!.then((_) => _doUpdate(mutate));
    } else {
      _pending = _doUpdate(mutate);
    }
    return _pending!;
  }

  Future<void> _doUpdate(
      FutureOr<Map<String, Object?>> Function(Map<String, Object?>) mutate) async {
    try {
      final current = await readAll();
      final next = await mutate(Map<String, Object?>.of(current));
      _cache = next;
      final f = await _file;
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(jsonEncode(next), flush: true);
      await tmp.rename(f.path);
    } finally {
      _pending = null;
    }
  }
}
