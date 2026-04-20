import 'track_model.dart';

/// Single deviation sample while following a track (backend stores GeoJSON-style coordinates).
class DeviationPoint {
  const DeviationPoint({
    required this.lat,
    required this.lng,
    required this.timestamp,
    required this.distanceFromTrack,
  });

  final double lat;
  final double lng;
  final DateTime timestamp;
  final double distanceFromTrack;

  factory DeviationPoint.fromJson(Map<String, dynamic> json) {
    double lat;
    double lng;
    final coords = json['coordinates'];
    if (coords is List && coords.length >= 2) {
      lng = (coords[0] as num).toDouble();
      lat = (coords[1] as num).toDouble();
    } else {
      lat = (json['lat'] as num?)?.toDouble() ?? 0;
      lng = (json['lng'] as num?)?.toDouble() ?? 0;
    }

    final ts = json['timestamp'];
    DateTime timestamp;
    if (ts is String) {
      timestamp = DateTime.tryParse(ts) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else if (ts is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(ts);
    } else {
      timestamp = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DeviationPoint(
      lat: lat,
      lng: lng,
      timestamp: timestamp,
      distanceFromTrack: (json['distanceFromTrack'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'coordinates': [lng, lat],
        'timestamp': timestamp.toIso8601String(),
        'distanceFromTrack': distanceFromTrack,
      };
}

/// Server-side record of a user following a published track (`TrackFollow` / `/api/follow`).
class TrackFollowModel {
  const TrackFollowModel({
    this.id,
    this.trackId,
    this.userId,
    this.startedAt,
    this.completedAt,
    this.isCompleted = false,
    this.totalDistance = 0,
    this.duration = 0,
    this.steps = 0,
    this.calories = 0,
    this.maxDeviation,
    this.deviationCount = 0,
    this.completionPercentage = 0,
    this.followPath = const [],
    this.deviationPoints = const [],
  });

  final String? id;
  final String? trackId;
  final String? userId;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final bool isCompleted;

  /// Meters (aligns with backend / sync payloads).
  final double totalDistance;

  /// Elapsed time in **seconds** (used by [durationFormatted]).
  final int duration;
  final int steps;
  final int calories;

  final double? maxDeviation;
  final int deviationCount;

  final double completionPercentage;

  final List<LatLng> followPath;
  final List<DeviationPoint> deviationPoints;

  /// [totalDistance] in meters → kilometers, rounded to one decimal place.
  double get distanceKm =>
      double.parse((totalDistance / 1000).toStringAsFixed(1));

  /// [duration] is treated as seconds → `HH:MM` (hours may exceed 99).
  String get durationFormatted {
    if (duration <= 0) {
      return '00:00';
    }
    final h = duration ~/ 3600;
    final m = (duration % 3600) ~/ 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Live session hint: active follow with at least one recorded deviation.
  bool get isOffTrack => !isCompleted && deviationCount > 0;

  factory TrackFollowModel.fromJson(Map<String, dynamic> json) {
    final deviationJson = json['deviationPoints'] as List<dynamic>?;
    final deviations = deviationJson != null
        ? deviationJson
            .map((e) => DeviationPoint.fromJson(e as Map<String, dynamic>))
            .toList()
        : const <DeviationPoint>[];

    return TrackFollowModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      trackId: _objectIdString(json['trackId']),
      userId: _objectIdString(json['userId']),
      startedAt: _parseDate(json['startedAt']),
      completedAt: _parseDate(json['completedAt']),
      isCompleted: json['isCompleted'] as bool? ?? false,
      totalDistance: (json['totalDistance'] as num?)?.toDouble() ?? 0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      maxDeviation: (json['maxDeviation'] as num?)?.toDouble(),
      deviationCount: (json['deviationCount'] as num?)?.toInt() ?? 0,
      completionPercentage: (json['completionPercentage'] as num?)?.toDouble() ?? 0,
      followPath: _parseFollowPath(json['followPath']),
      deviationPoints: deviations,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        if (trackId != null) 'trackId': trackId,
        if (userId != null) 'userId': userId,
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        'isCompleted': isCompleted,
        'totalDistance': totalDistance,
        'duration': duration,
        'steps': steps,
        'calories': calories,
        if (maxDeviation != null) 'maxDeviation': maxDeviation,
        'deviationCount': deviationCount,
        'completionPercentage': completionPercentage,
        'followPath': _followPathToJson(followPath),
        'deviationPoints': deviationPoints.map((e) => e.toJson()).toList(),
      };
}

String? _objectIdString(dynamic raw) {
  if (raw == null) {
    return null;
  }
  if (raw is String) {
    return raw;
  }
  if (raw is Map<String, dynamic>) {
    return raw['_id']?.toString();
  }
  return raw.toString();
}

DateTime? _parseDate(dynamic raw) {
  if (raw == null) {
    return null;
  }
  if (raw is String) {
    return DateTime.tryParse(raw);
  }
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }
  return null;
}

List<LatLng> _parseFollowPath(dynamic raw) {
  if (raw is! Map<String, dynamic>) {
    return const [];
  }
  final coords = raw['coordinates'];
  if (coords is! List<dynamic>) {
    return const [];
  }
  final out = <LatLng>[];
  for (final pair in coords) {
    if (pair is List && pair.length >= 2) {
      final lng = (pair[0] as num).toDouble();
      final lat = (pair[1] as num).toDouble();
      out.add(LatLng(lat, lng));
    }
  }
  return out;
}

Map<String, dynamic> _followPathToJson(List<LatLng> path) => {
      'type': 'LineString',
      'coordinates':
          path.map((p) => [p.longitude, p.latitude]).toList(growable: false),
    };
