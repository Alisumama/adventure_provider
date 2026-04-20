import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../../features/track/data/local/local_track_repository.dart';
import '../../features/track/data/repositories/track_repository.dart';

/// Periodically pushes unsynced [TrackPointLocal] rows to the server for a recording session.
///
/// All uploads use [LocalTrackRepository.getUnsyncedPoints] only; after each successful POST,
/// [LocalTrackRepository.markPointsSynced] updates local state. Use [syncAllUnsyncedSessions]
/// after connectivity returns to flush every session that still has unsynced rows.
class TrackSyncService extends GetxService {
  TrackSyncService({required LocalTrackRepository localTrackRepository, required TrackRepository trackRepository, required Connectivity connectivity}) : _local = localTrackRepository, _trackRepository = trackRepository, _connectivity = connectivity;

  final LocalTrackRepository _local;
  final TrackRepository _trackRepository;
  final Connectivity _connectivity;

  Timer? _syncTimer;
  String? _activeSessionId;

  /// Serialize sync work so timer / forceSync / reconnect flush never run in parallel.
  Future<void> _mutex = Future<void>.value();

  /// Avoid huge POST bodies / timeouts and MongoDB update limits on a single request.
  static const int _maxPointsPerRequest = 50;

  /// Server track id (same as local session / draft id) for the active recording.
  String? get activeSessionId => _activeSessionId;

  Future<T> _runLocked<T>(Future<T> Function() fn) async {
    final prev = _mutex;
    final done = Completer<void>();
    _mutex = done.future;
    await prev;
    try {
      return await fn();
    } finally {
      done.complete();
    }
  }

  void startSync(String sessionId) {
    _syncTimer?.cancel();
    _activeSessionId = sessionId;
    unawaited(_runLocked(() => _syncSessionPointsFromLocalDb(sessionId)));
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final sid = _activeSessionId;
      if (sid == null) return;
      unawaited(_runLocked(() => _syncSessionPointsFromLocalDb(sid)));
    });
  }

  /// Reads unsynced rows from Hive only; marks each chunk synced after a successful POST.
  Future<void> _syncSessionPointsFromLocalDb(String sid) async {
    final results = await _connectivity.checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!online) {
      return;
    }

    final session = _local.getSession(sid);
    if (session == null) {
      return;
    }
    final serverId = session.serverTrackId;
    if (serverId.isEmpty) {
      return;
    }

    while (true) {
      final unsynced = _local.getUnsyncedPoints(sid);
      if (unsynced.isEmpty) {
        return;
      }

      final chunk = unsynced.length > _maxPointsPerRequest ? unsynced.sublist(0, _maxPointsPerRequest) : unsynced;

      try {
        await _trackRepository.syncTrackPoints(serverId, chunk);
        final ids = chunk.map((p) => p.id).toList(growable: false);
        _local.markPointsSynced(ids);
        session.lastSyncedAt = DateTime.now();
        _local.updateSession(session);
      } catch (_) {
        return;
      }
    }
  }

  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _activeSessionId = null;
  }

  Future<void> forceSync(String sessionId) async {
    await _runLocked(() => _syncSessionPointsFromLocalDb(sessionId));
  }

  /// Flushes every session that still has unsynced points (e.g. after internet returns).
  Future<void> syncAllUnsyncedSessions() async {
    final ids = _local.getSessionIdsWithUnsyncedPoints().toList();
    for (final sid in ids) {
      await _runLocked(() => _syncSessionPointsFromLocalDb(sid));
    }
  }

  @override
  void onClose() {
    _syncTimer?.cancel();
    super.onClose();
  }
}
