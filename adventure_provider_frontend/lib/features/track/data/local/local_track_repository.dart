import 'package:hive/hive.dart';

import 'track_local_models.dart';

/// Hive box names — must match [main.dart] (`track_points`, `track_sessions`).
abstract final class _HiveBoxes {
  static const trackPoints = 'track_points';
  static const trackSessions = 'track_sessions';
}

/// Persists [TrackPointLocal] and [TrackSessionLocal] in local Hive boxes.
class LocalTrackRepository {
  LocalTrackRepository({
    Box<dynamic>? pointsBox,
    Box<dynamic>? sessionsBox,
  })  : _pointsBox = pointsBox ?? Hive.box<dynamic>(_HiveBoxes.trackPoints),
        _sessionsBox = sessionsBox ?? Hive.box<dynamic>(_HiveBoxes.trackSessions);

  final Box<dynamic> _pointsBox;
  final Box<dynamic> _sessionsBox;

  /// Saves a single GPS point; key is [TrackPointLocal.id].
  void saveTrackPoint(TrackPointLocal point) {
    _pointsBox.put(point.id, point);
  }

  /// Distinct [TrackPointLocal.trackSessionId] values that have at least one unsynced point.
  Set<String> getSessionIdsWithUnsyncedPoints() {
    final ids = <String>{};
    for (final key in _pointsBox.keys) {
      final v = _pointsBox.get(key);
      if (v is TrackPointLocal && !v.isSynced) {
        ids.add(v.trackSessionId);
      }
    }
    return ids;
  }

  /// All points for [sessionId] with [TrackPointLocal.isSynced] == false.
  List<TrackPointLocal> getUnsyncedPoints(String sessionId) {
    final out = <TrackPointLocal>[];
    for (final key in _pointsBox.keys) {
      final v = _pointsBox.get(key);
      if (v is TrackPointLocal &&
          v.trackSessionId == sessionId &&
          !v.isSynced) {
        out.add(v);
      }
    }
    out.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return out;
  }

  /// Sets [TrackPointLocal.isSynced] to true for each existing point id.
  void markPointsSynced(List<String> ids) {
    for (final id in ids) {
      final v = _pointsBox.get(id);
      if (v is TrackPointLocal) {
        v.isSynced = true;
        _pointsBox.put(id, v);
      }
    }
  }

  /// All points for [sessionId], synced or not.
  List<TrackPointLocal> getSessionPoints(String sessionId) {
    final out = <TrackPointLocal>[];
    for (final key in _pointsBox.keys) {
      final v = _pointsBox.get(key);
      if (v is TrackPointLocal && v.trackSessionId == sessionId) {
        out.add(v);
      }
    }
    out.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return out;
  }

  /// Persists a session; key is [TrackSessionLocal.sessionId].
  void saveSession(TrackSessionLocal session) {
    _sessionsBox.put(session.sessionId, session);
  }

  TrackSessionLocal? getSession(String sessionId) {
    final v = _sessionsBox.get(sessionId);
    return v is TrackSessionLocal ? v : null;
  }

  /// Overwrites the session entry for [TrackSessionLocal.sessionId].
  void updateSession(TrackSessionLocal session) {
    _sessionsBox.put(session.sessionId, session);
  }

  /// Sessions that are not marked completed.
  List<TrackSessionLocal> getAllIncompleteSessions() {
    final out = <TrackSessionLocal>[];
    for (final key in _sessionsBox.keys) {
      final v = _sessionsBox.get(key);
      if (v is TrackSessionLocal && !v.isCompleted) {
        out.add(v);
      }
    }
    return out;
  }

  /// Removes the session and every point belonging to [sessionId].
  void deleteSession(String sessionId) {
    final keysToRemove = <dynamic>[];
    for (final key in _pointsBox.keys) {
      final v = _pointsBox.get(key);
      if (v is TrackPointLocal && v.trackSessionId == sessionId) {
        keysToRemove.add(key);
      }
    }
    for (final k in keysToRemove) {
      _pointsBox.delete(k);
    }
    _sessionsBox.delete(sessionId);
  }

  /// Deletes synced points for [sessionId] (post-sync cleanup).
  void clearSyncedPoints(String sessionId) {
    final keysToRemove = <dynamic>[];
    for (final key in _pointsBox.keys) {
      final v = _pointsBox.get(key);
      if (v is TrackPointLocal &&
          v.trackSessionId == sessionId &&
          v.isSynced) {
        keysToRemove.add(key);
      }
    }
    for (final k in keysToRemove) {
      _pointsBox.delete(k);
    }
  }
}
