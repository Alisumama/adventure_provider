import 'package:latlong2/latlong.dart' as ll;

class MemberSession {
  const MemberSession({
    required this.userId,
    this.name = '',
    this.profileImage,
    this.shortName = '',
    this.lastLatitude,
    this.lastLongitude,
    this.lastSeenAt,
    this.isOnline = false,
    this.locationPath = const [],
    this.totalDistance = 0,
  });

  final String userId;
  final String name;
  final String? profileImage;
  final String shortName;
  final double? lastLatitude;
  final double? lastLongitude;
  final DateTime? lastSeenAt;
  final bool isOnline;
  final List<ll.LatLng> locationPath;
  final double totalDistance;

  factory MemberSession.fromJson(Map<String, dynamic> json) {
    final userIdRaw = json['userId'];
    String userId = '';
    String name = '';
    String? profileImage;

    if (userIdRaw is Map<String, dynamic>) {
      userId = userIdRaw['_id']?.toString() ??
          userIdRaw['id']?.toString() ??
          '';
      name = userIdRaw['name'] as String? ?? '';
      profileImage = userIdRaw['profileImage'] as String?;
    } else {
      userId = userIdRaw?.toString() ?? '';
      name = json['name'] as String? ?? '';
      profileImage = json['profileImage'] as String?;
    }

    final shortName = json['shortName'] as String? ??
        (name.isNotEmpty ? name.split(' ').first : '');

    // Parse lastLocation GeoJSON Point
    double? lastLatitude;
    double? lastLongitude;
    final lastLoc = json['lastLocation'] as Map<String, dynamic>?;
    if (lastLoc != null) {
      final coords = lastLoc['coordinates'] as List<dynamic>?;
      if (coords != null && coords.length >= 2) {
        lastLongitude = (coords[0] as num?)?.toDouble();
        lastLatitude = (coords[1] as num?)?.toDouble();
      }
    }
    // Also accept flat lat/lng (from socket events)
    lastLatitude ??= (json['lastLatitude'] as num?)?.toDouble();
    lastLongitude ??= (json['lastLongitude'] as num?)?.toDouble();

    // Parse locationPath — array of [lng, lat] pairs
    final pathRaw = json['locationPath'] as List<dynamic>?;
    final locationPath = <ll.LatLng>[];
    if (pathRaw != null) {
      for (final coord in pathRaw) {
        if (coord is List && coord.length >= 2) {
          final lng = (coord[0] as num?)?.toDouble();
          final lat = (coord[1] as num?)?.toDouble();
          if (lng != null && lat != null) {
            locationPath.add(ll.LatLng(lat, lng));
          }
        }
      }
    }

    return MemberSession(
      userId: userId,
      name: name,
      profileImage: profileImage,
      shortName: shortName,
      lastLatitude: lastLatitude,
      lastLongitude: lastLongitude,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'].toString())
          : null,
      isOnline: json['isOnline'] as bool? ?? false,
      locationPath: locationPath,
      totalDistance: (json['totalDistance'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        if (profileImage != null) 'profileImage': profileImage,
        'shortName': shortName,
        if (lastLatitude != null) 'lastLatitude': lastLatitude,
        if (lastLongitude != null) 'lastLongitude': lastLongitude,
        if (lastSeenAt != null) 'lastSeenAt': lastSeenAt!.toIso8601String(),
        'isOnline': isOnline,
        'locationPath': locationPath
            .map((p) => [p.longitude, p.latitude])
            .toList(),
        'totalDistance': totalDistance,
      };

  MemberSession copyWith({
    String? userId,
    String? name,
    String? profileImage,
    String? shortName,
    double? lastLatitude,
    double? lastLongitude,
    DateTime? lastSeenAt,
    bool? isOnline,
    List<ll.LatLng>? locationPath,
    double? totalDistance,
  }) {
    return MemberSession(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      shortName: shortName ?? this.shortName,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isOnline: isOnline ?? this.isOnline,
      locationPath: locationPath ?? this.locationPath,
      totalDistance: totalDistance ?? this.totalDistance,
    );
  }
}

class LiveSessionModel {
  const LiveSessionModel({
    required this.id,
    required this.groupId,
    required this.startedBy,
    this.startedAt,
    this.isActive = true,
    this.memberSessions = const [],
  });

  final String id;
  final String groupId;
  final String startedBy;
  final DateTime? startedAt;
  final bool isActive;
  final List<MemberSession> memberSessions;

  factory LiveSessionModel.fromJson(Map<String, dynamic> json) {
    final sessionsRaw = json['memberSessions'] as List<dynamic>?;
    final memberSessions = sessionsRaw
            ?.map((e) => MemberSession.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return LiveSessionModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      startedBy: json['startedBy']?.toString() ?? '',
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString())
          : null,
      isActive: json['isActive'] as bool? ?? true,
      memberSessions: memberSessions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'groupId': groupId,
        'startedBy': startedBy,
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        'isActive': isActive,
        'memberSessions': memberSessions.map((m) => m.toJson()).toList(),
      };

  LiveSessionModel copyWith({
    String? id,
    String? groupId,
    String? startedBy,
    DateTime? startedAt,
    bool? isActive,
    List<MemberSession>? memberSessions,
  }) {
    return LiveSessionModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      startedBy: startedBy ?? this.startedBy,
      startedAt: startedAt ?? this.startedAt,
      isActive: isActive ?? this.isActive,
      memberSessions: memberSessions ?? this.memberSessions,
    );
  }
}
