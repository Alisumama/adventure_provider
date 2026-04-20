import 'package:hive/hive.dart';

import 'track_local_models.dart';

abstract final class _HiveBoxes {
  static const followPoints = 'follow_points';
  static const followSessions = 'follow_sessions';
}

/// Persists [TrackFollowPointLocal] and [TrackFollowSessionLocal] in Hive.
class LocalFollowRepository {
  LocalFollowRepository({Box<dynamic>? pointsBox, Box<dynamic>? sessionsBox})
      : _pointsBox = pointsBox ?? Hive.box<dynamic>(_HiveBoxes.followPoints),
        _sessionsBox = sessionsBox ?? Hive.box<dynamic>(_HiveBoxes.followSessions);

  final Box<dynamic> _pointsBox;
  final Box<dynamic> _sessionsBox;

  void saveFollowPoint(TrackFollowPointLocal point) {
    _pointsBox.put(point.id, point);
  }

  List<TrackFollowPointLocal> getUnsyncedPoints(String followSessionId) {
    final out = <TrackFollowPointLocal>[];
    for (final key in _pointsBox.keys) {
      final v = _pointsBox.get(key);
      if (v is TrackFollowPointLocal &&
          v.followSessionId == followSessionId &&
          !v.isSynced) {
        out.add(v);
      }
    }
    out.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return out;
  }

  void markPointsSynced(List<String> ids) {
    for (final id in ids) {
      final v = _pointsBox.get(id);
      if (v is TrackFollowPointLocal) {
        v.isSynced = true;
        _pointsBox.put(id, v);
      }
    }
  }

  void saveSession(TrackFollowSessionLocal session) {
    _sessionsBox.put(session.followSessionId, session);
  }

  TrackFollowSessionLocal? getSession(String followSessionId) {
    final v = _sessionsBox.get(followSessionId);
    return v is TrackFollowSessionLocal ? v : null;
  }

  void updateSession(TrackFollowSessionLocal session) {
    _sessionsBox.put(session.followSessionId, session);
  }

  /// Removes the session and all its follow points.
  void deleteSession(String followSessionId) {
    final keysToRemove = <dynamic>[];
    for (final key in _pointsBox.keys) {
      final v = _pointsBox.get(key);
      if (v is TrackFollowPointLocal && v.followSessionId == followSessionId) {
        keysToRemove.add(key);
      }
    }
    for (final k in keysToRemove) {
      _pointsBox.delete(k);
    }
    _sessionsBox.delete(followSessionId);
  }
}
