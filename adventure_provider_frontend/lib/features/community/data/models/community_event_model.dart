import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class EventMeetingPointModel {
  const EventMeetingPointModel({
    required this.address,
    this.lat,
    this.lng,
  });

  final String address;
  final double? lat;
  final double? lng;

  factory EventMeetingPointModel.fromJson(Map<String, dynamic> json) {
    return EventMeetingPointModel(
      address: json['address'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'lat': lat,
        'lng': lng,
      };

  EventMeetingPointModel copyWith({
    String? address,
    double? lat,
    double? lng,
  }) {
    return EventMeetingPointModel(
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}

class EventCreatorModel {
  const EventCreatorModel({
    required this.id,
    required this.name,
    this.profileImage,
  });

  final String id;
  final String name;
  final String? profileImage;

  factory EventCreatorModel.fromJson(Map<String, dynamic> json) {
    return EventCreatorModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      profileImage: json['profileImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (profileImage != null) 'profileImage': profileImage,
      };

  EventCreatorModel copyWith({
    String? id,
    String? name,
    String? profileImage,
  }) {
    return EventCreatorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

class CommunityEventModel {
  const CommunityEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.eventDate,
    required this.meetingPoint,
    required this.maxParticipants,
    required this.participantsCount,
    this.isJoined = false,
    this.isActive = true,
    required this.createdAt,
    required this.createdBy,
  });

  final String id;
  final String title;
  final String description;
  final String type;
  final String difficulty;
  final DateTime eventDate;
  final EventMeetingPointModel meetingPoint;
  final int maxParticipants;
  final int participantsCount;
  final bool isJoined;
  final bool isActive;
  final DateTime createdAt;
  final EventCreatorModel createdBy;

  factory CommunityEventModel.fromJson(Map<String, dynamic> json) {
    final mpRaw = json['meetingPoint'];
    final mpMap = mpRaw is Map<String, dynamic>
        ? mpRaw
        : (mpRaw is Map ? Map<String, dynamic>.from(mpRaw) : null);

    final createdByRaw = json['createdBy'];
    final createdByMap = createdByRaw is Map<String, dynamic>
        ? createdByRaw
        : (createdByRaw is Map ? Map<String, dynamic>.from(createdByRaw) : null);

    DateTime parseDate(dynamic raw) {
      if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.tryParse(raw.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    return CommunityEventModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'moderate',
      eventDate: parseDate(json['eventDate']),
      meetingPoint: mpMap != null ? EventMeetingPointModel.fromJson(mpMap) : const EventMeetingPointModel(address: ''),
      maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 0,
      participantsCount: (json['participantsCount'] as num?)?.toInt() ?? 0,
      isJoined: json['isJoined'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parseDate(json['createdAt']),
      createdBy: createdByMap != null ? EventCreatorModel.fromJson(createdByMap) : const EventCreatorModel(id: '', name: ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type,
        'difficulty': difficulty,
        'eventDate': eventDate.toIso8601String(),
        'meetingPoint': meetingPoint.toJson(),
        'maxParticipants': maxParticipants,
        'participantsCount': participantsCount,
        'isJoined': isJoined,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy.toJson(),
      };

  CommunityEventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    String? difficulty,
    DateTime? eventDate,
    EventMeetingPointModel? meetingPoint,
    int? maxParticipants,
    int? participantsCount,
    bool? isJoined,
    bool? isActive,
    DateTime? createdAt,
    EventCreatorModel? createdBy,
  }) {
    return CommunityEventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      eventDate: eventDate ?? this.eventDate,
      meetingPoint: meetingPoint ?? this.meetingPoint,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participantsCount: participantsCount ?? this.participantsCount,
      isJoined: isJoined ?? this.isJoined,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  bool get isFull => participantsCount >= maxParticipants;

  bool get isPast => eventDate.isBefore(DateTime.now());

  String get spotsLeft => '${maxParticipants - participantsCount} spots left';

  String get formattedDate {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final w = weekdays[(eventDate.weekday - 1).clamp(0, 6)];
    final m = months[(eventDate.month - 1).clamp(0, 11)];
    final day = eventDate.day;

    final hour24 = eventDate.hour;
    final minute = eventDate.minute.toString().padLeft(2, '0');
    final ampm = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = (hour24 % 12 == 0) ? 12 : (hour24 % 12);

    return '$w, $day $m · $hour12:$minute $ampm';
  }

  String get typeLabel {
    switch (type) {
      case 'hiking':
        return '🥾 Hiking';
      case 'offroading':
        return '🚙 Off-Road';
      case 'both':
        return '🏔️ Both';
      default:
        return '🏔️ Both';
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case 'easy':
        return AppColors.success;
      case 'hard':
        return AppColors.danger;
      case 'moderate':
      default:
        return AppColors.warning;
    }
  }
}

