import 'package:hive/hive.dart';

part 'track_local_models.g.dart';

/// Single GPS sample for offline / pending sync during a recording session.
///
/// [id] should be unique (e.g. UUID or `DateTime.now().millisecondsSinceEpoch.toString()`).
@HiveType(typeId: 0)
class TrackPointLocal extends HiveObject {
  TrackPointLocal({
    required this.id,
    required this.trackSessionId,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.timestamp,
    this.isSynced = false,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String trackSessionId;

  @HiveField(2)
  double latitude;

  @HiveField(3)
  double longitude;

  @HiveField(4)
  double altitude;

  @HiveField(5)
  double speed;

  @HiveField(6)
  DateTime timestamp;

  @HiveField(7, defaultValue: false)
  bool isSynced;
}

/// Metadata for one local recording session (before or after server sync).
@HiveType(typeId: 1)
class TrackSessionLocal extends HiveObject {
  TrackSessionLocal({
    required this.sessionId,
    required this.startedAt,
    this.lastSyncedAt,
    this.isCompleted = false,
    this.isSynced = false,
    this.totalPoints = 0,
    this.distance = 0,
    this.steps = 0,
    this.calories = 0,
    this.duration = 0,
    this.serverTrackId = '',
  });

  @HiveField(0)
  String sessionId;

  @HiveField(1)
  DateTime startedAt;

  @HiveField(2)
  DateTime? lastSyncedAt;

  @HiveField(3, defaultValue: false)
  bool isCompleted;

  @HiveField(4, defaultValue: false)
  bool isSynced;

  @HiveField(5, defaultValue: 0)
  int totalPoints;

  @HiveField(6, defaultValue: 0)
  double distance;

  @HiveField(7, defaultValue: 0)
  int steps;

  @HiveField(8, defaultValue: 0)
  int calories;

  /// Total duration in seconds.
  @HiveField(9, defaultValue: 0)
  int duration;

  /// Server Mongo id from POST /tracks (or empty until online / retry).
  @HiveField(10, defaultValue: '')
  String serverTrackId;
}
