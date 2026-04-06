class CommunityCreatorModel {
  const CommunityCreatorModel({
    this.id,
    this.name,
    this.profileImage,
  });

  final String? id;
  final String? name;
  final String? profileImage;

  factory CommunityCreatorModel.fromJson(Map<String, dynamic> json) {
    return CommunityCreatorModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      name: json['name'] as String?,
      profileImage: json['profileImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        if (name != null) 'name': name,
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
    this.id,
    this.name,
    this.description,
    this.visibility,
    this.category,
    this.image,
    this.coverImage,
    this.membersCount,
    this.totalPosts,
    required this.createdBy,
    this.isMember = false,
    this.userRole,
    this.createdAt,
  });

  final String? id;
  final String? name;
  final String? description;
  final String? visibility;
  final String? category;
  final String? image;
  final String? coverImage;
  final int? membersCount;
  final int? totalPosts;
  final CommunityCreatorModel createdBy;
  final bool isMember;
  final String? userRole;
  final DateTime? createdAt;

  bool get isAdmin => userRole == 'admin';
  bool get isPublic => visibility == 'public';
  String get categoryLabel {
    switch (category) {
      case 'hiking':
        return '🥾 Hiking';
      case 'offroading':
        return '🚙 Off-Road';
      default:
        return '🏔️ All Adventure';
    }
  }

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    final createdByRaw = json['createdBy'];
    final createdBy = createdByRaw is Map<String, dynamic>
        ? CommunityCreatorModel.fromJson(createdByRaw)
        : const CommunityCreatorModel();

    return CommunityModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      visibility: json['visibility'] as String?,
      category: json['category'] as String?,
      image: json['image'] as String?,
      coverImage: json['coverImage'] as String?,
      membersCount: (json['membersCount'] as num?)?.toInt(),
      totalPosts: (json['totalPosts'] as num?)?.toInt(),
      createdBy: createdBy,
      isMember: json['isMember'] as bool? ?? false,
      userRole: json['userRole'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  /// Parses `GET /community/:id` body: `{ community, isMember, userRole }`.
  factory CommunityModel.fromDetailResponse(Map<String, dynamic> json) {
    final community = json['community'];
    if (community is! Map<String, dynamic>) {
      return CommunityModel(createdBy: const CommunityCreatorModel());
    }
    return CommunityModel.fromJson({
      ...community,
      'isMember': json['isMember'],
      'userRole': json['userRole'],
    });
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (visibility != null) 'visibility': visibility,
        if (category != null) 'category': category,
        if (image != null) 'image': image,
        if (coverImage != null) 'coverImage': coverImage,
        if (membersCount != null) 'membersCount': membersCount,
        if (totalPosts != null) 'totalPosts': totalPosts,
        'createdBy': createdBy.toJson(),
        'isMember': isMember,
        if (userRole != null) 'userRole': userRole,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
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
