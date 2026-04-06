import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CommunityMemberModel {
  const CommunityMemberModel({
    required this.userId,
    required this.name,
    this.profileImage,
    required this.role,
    required this.joinedAt,
    required this.totalTracks,
    required this.totalAdventures,
  });

  final String userId;
  final String name;
  final String? profileImage;
  final String role;
  final DateTime joinedAt;
  final int totalTracks;
  final int totalAdventures;

  bool get isAdmin => role == 'admin';

  bool get isModerator => role == 'moderator';

  String get roleLabel => role == 'admin'
      ? 'Admin'
      : role == 'moderator'
          ? 'Moderator'
          : 'Member';

  Color get roleColor => role == 'admin'
      ? AppColors.accent
      : role == 'moderator'
          ? AppColors.primaryLight
          : AppColors.textSecondary;

  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    final user = userRaw is Map
        ? Map<String, dynamic>.from(userRaw)
        : <String, dynamic>{};

    return CommunityMemberModel(
      userId: user['_id']?.toString() ?? user['id']?.toString() ?? '',
      name: user['name'] as String? ?? '',
      profileImage: user['profileImage'] as String?,
      role: json['role'] as String? ?? 'member',
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'].toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
      totalTracks: (user['totalTracks'] as num?)?.toInt() ?? 0,
      totalAdventures: (user['totalAdventures'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'user': {
          '_id': userId,
          'name': name,
          if (profileImage != null) 'profileImage': profileImage,
          'totalTracks': totalTracks,
          'totalAdventures': totalAdventures,
        },
        'role': role,
        'joinedAt': joinedAt.toIso8601String(),
      };

  CommunityMemberModel copyWith({
    String? userId,
    String? name,
    String? profileImage,
    String? role,
    DateTime? joinedAt,
    int? totalTracks,
    int? totalAdventures,
  }) {
    return CommunityMemberModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      totalTracks: totalTracks ?? this.totalTracks,
      totalAdventures: totalAdventures ?? this.totalAdventures,
    );
  }
}
