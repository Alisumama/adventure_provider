/// Geographic point (latitude, longitude). Backend GeoJSON uses [lng, lat]; we convert in [fromJson]/[toJson].
class LatLng {
  const LatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class TrackFlag {
  const TrackFlag({
    this.id,
    this.type,
    required this.title,
    this.description,
    this.photo,
    this.images = const [],
    required this.lat,
    required this.lng,
  });

  final String? id;
  /// Flag category (`rest_area`, `water_stream`, …); may be absent on legacy data.
  final String? type;
  final String title;
  final String? description;
  final String? photo;
  /// Image URLs or relative paths from the API.
  final List<String> images;
  final double lat;
  final double lng;

  factory TrackFlag.fromJson(Map<String, dynamic> json) {
    LatLng? fromLoc;
    final loc = json['location'];
    if (loc is Map<String, dynamic>) {
      fromLoc = _geoJsonPointToLatLng(loc);
    }
    final lat = fromLoc != null
        ? fromLoc.latitude
        : (json['lat'] as num?)?.toDouble() ?? 0;
    final lng = fromLoc != null
        ? fromLoc.longitude
        : (json['lng'] as num?)?.toDouble() ?? 0;

    final imagesJson = json['images'] as List<dynamic>?;
    final imagesList = imagesJson != null
        ? imagesJson.map((e) => e.toString()).toList()
        : const <String>[];

    return TrackFlag(
      id: json['_id']?.toString(),
      type: json['type'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      photo: json['photo'] as String?,
      images: imagesList,
      lat: lat,
      lng: lng,
    );
  }

  /// Matches backend embedded flag shape (`location` is GeoJSON Point).
  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        if (type != null) 'type': type,
        'title': title,
        if (description != null) 'description': description,
        if (photo != null) 'photo': photo,
        if (images.isNotEmpty) 'images': images,
        'location': {
          'type': 'Point',
          'coordinates': [lng, lat],
        },
      };
}

/// Flag placed during live recording (optimistic UI + socket `add_flag`).
class LiveTrackFlag {
  const LiveTrackFlag({
    this.id,
    required this.type,
    this.description,
    this.images = const [],
    required this.lat,
    required this.lng,
  });

  final String? id;
  final String type;
  final String? description;
  final List<String> images;
  final double lat;
  final double lng;
}

class TrackModel {
  const TrackModel({
    this.id,
    this.userId,
    required this.title,
    this.description,
    required this.type,
    required this.difficulty,
    this.distance = 0,
    this.duration = 0,
    this.steps = 0,
    this.calories = 0,
    this.isPublic = true,
    this.coverImage,
    this.geoPath = const [],
    this.startPoint,
    this.endPoint,
    this.flags = const [],
    this.photos = const [],
    this.likesCount = 0,
    this.savesCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.createdAt,
  });

  final String? id;
  final String? userId;
  final String title;
  final String? description;
  final String type;
  final String difficulty;
  final double distance;
  final int duration;
  final int steps;
  final int calories;
  final bool isPublic;
  final String? coverImage;
  final List<LatLng> geoPath;
  final LatLng? startPoint;
  final LatLng? endPoint;
  final List<TrackFlag> flags;
  final List<String> photos;
  final int likesCount;
  final int savesCount;
  final bool isLiked;
  final bool isSaved;
  final DateTime? createdAt;

  /// Kilometres, one decimal place (e.g. `"12.3"`).
  String get distanceKm => (distance / 1000).toStringAsFixed(1);

  /// Total [duration] in seconds as `HH:MM` (hours may exceed 23).
  String get durationFormatted {
    final safe = duration < 0 ? 0 : duration;
    final h = safe ~/ 3600;
    final m = (safe % 3600) ~/ 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  factory TrackModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final likes = json['likes'] as List<dynamic>? ?? const [];
    final saves = json['saves'] as List<dynamic>? ?? const [];
    final likeIds = likes.map((e) => e.toString()).toList();
    final saveIds = saves.map((e) => e.toString()).toList();

    final likesCount =
        (json['likesCount'] as num?)?.toInt() ?? likeIds.length;
    final savesCount =
        (json['savesCount'] as num?)?.toInt() ?? saveIds.length;

    final uid = currentUserId;
    final isLiked = (json['isLiked'] as bool?) ??
        (uid != null && likeIds.contains(uid));
    final isSaved = (json['isSaved'] as bool?) ??
        (uid != null && saveIds.contains(uid));

    final flagsJson = json['flags'] as List<dynamic>? ?? const [];
    final photosJson = json['photos'] as List<dynamic>? ?? const [];

    return TrackModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      userId: _parseUserId(json['userId']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      type: json['type'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      steps: (json['steps'] as num?)?.toInt() ?? 0,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      isPublic: json['isPublic'] as bool? ?? true,
      coverImage: json['coverImage'] as String?,
      geoPath: _lineStringToLatLngList(json['geoPath']),
      startPoint: _geoJsonPointToLatLng(json['startPoint']),
      endPoint: _geoJsonPointToLatLng(json['endPoint']),
      flags: flagsJson
          .map((e) => TrackFlag.fromJson(e as Map<String, dynamic>))
          .toList(),
      photos: photosJson.map((e) => e.toString()).toList(),
      likesCount: likesCount,
      savesCount: savesCount,
      isLiked: isLiked,
      isSaved: isSaved,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        if (userId != null) 'userId': userId,
        'title': title,
        if (description != null) 'description': description,
        'type': type,
        'difficulty': difficulty,
        'distance': distance,
        'duration': duration,
        'steps': steps,
        'calories': calories,
        'isPublic': isPublic,
        if (coverImage != null) 'coverImage': coverImage,
        'geoPath': _latLngListToLineStringMap(geoPath),
        if (startPoint != null)
          'startPoint': _latLngToPointMap(startPoint!),
        if (endPoint != null) 'endPoint': _latLngToPointMap(endPoint!),
        'flags': flags.map((f) => f.toJson()).toList(),
        'photos': photos,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}

String? _parseUserId(dynamic raw) {
  if (raw == null) return null;
  if (raw is String) return raw;
  if (raw is Map<String, dynamic>) {
    return raw['_id']?.toString();
  }
  return raw.toString();
}

LatLng? _geoJsonPointToLatLng(dynamic raw) {
  if (raw is! Map<String, dynamic>) return null;
  final coords = raw['coordinates'];
  if (coords is! List || coords.length < 2) return null;
  final lng = (coords[0] as num).toDouble();
  final lat = (coords[1] as num).toDouble();
  return LatLng(lat, lng);
}

List<LatLng> _lineStringToLatLngList(dynamic raw) {
  if (raw is! Map<String, dynamic>) return [];
  final coords = raw['coordinates'];
  if (coords is! List<dynamic>) return [];
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

Map<String, dynamic> _latLngToPointMap(LatLng p) => {
      'type': 'Point',
      'coordinates': [p.longitude, p.latitude],
    };

Map<String, dynamic> _latLngListToLineStringMap(List<LatLng> path) => {
      'type': 'LineString',
      'coordinates':
          path.map((p) => [p.longitude, p.latitude]).toList(growable: false),
    };
