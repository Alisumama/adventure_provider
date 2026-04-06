class CommunityCreatorModel {
  const CommunityCreatorModel({
    required this.id,
    required this.name,
    this.profileImage,
  });

  final String id;
  final String name;
  final String? profileImage;

  factory CommunityCreatorModel.fromJson(Map<String, dynamic> json) {
    return CommunityCreatorModel(
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

  CommunityCreatorModel copyWith({
    String? id,
    String? name,
    String? profileImage,
  }) {
    return CommunityCreatorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

class CommunityModel {
  const CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.visibility,
    required this.category,
    this.image,
    this.coverImage,
    this.membersCount = 0,
    this.totalPosts = 0,
    required this.createdBy,
    this.isMember = false,
    this.userRole,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String visibility;
  final String category;
  final String? image;
  final String? coverImage;
  final int membersCount;
  final int totalPosts;
  final CommunityCreatorModel createdBy;
  final bool isMember;
  final String? userRole;
  final DateTime createdAt;

  bool get isAdmin => userRole == 'admin';

  bool get isModerator => userRole == 'moderator';

  bool get isPublic => visibility == 'public';

  String get categoryLabel => category == 'hiking'
      ? '🥾 Hiking'
      : category == 'offroading'
          ? '🚙 Off-Road'
          : '🏔️ All Adventure';

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    final createdByRaw = json['createdBy'];
    return CommunityModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      visibility: json['visibility'] as String? ?? '',
      category: json['category'] as String? ?? '',
      image: json['image'] as String?,
      coverImage: json['coverImage'] as String?,
      membersCount: (json['membersCount'] as num?)?.toInt() ?? 0,
      totalPosts: (json['totalPosts'] as num?)?.toInt() ?? 0,
      createdBy: createdByRaw is Map<String, dynamic>
          ? CommunityCreatorModel.fromJson(createdByRaw)
          : const CommunityCreatorModel(id: '', name: ''),
      isMember: json['isMember'] as bool? ?? false,
      userRole: json['userRole'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'visibility': visibility,
        'category': category,
        if (image != null) 'image': image,
        if (coverImage != null) 'coverImage': coverImage,
        'membersCount': membersCount,
        'totalPosts': totalPosts,
        'createdBy': createdBy.toJson(),
        'isMember': isMember,
        if (userRole != null) 'userRole': userRole,
        'createdAt': createdAt.toIso8601String(),
      };

  CommunityModel copyWith({
    String? id,
    String? name,
    String? description,
    String? visibility,
    String? category,
    String? image,
    String? coverImage,
    int? membersCount,
    int? totalPosts,
    CommunityCreatorModel? createdBy,
    bool? isMember,
    String? userRole,
    DateTime? createdAt,
  }) {
    return CommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      category: category ?? this.category,
      image: image ?? this.image,
      coverImage: coverImage ?? this.coverImage,
      membersCount: membersCount ?? this.membersCount,
      totalPosts: totalPosts ?? this.totalPosts,
      createdBy: createdBy ?? this.createdBy,
      isMember: isMember ?? this.isMember,
      userRole: userRole ?? this.userRole,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
