class GroupMember {
  const GroupMember({
    required this.userId,
    required this.name,
    this.profileImage,
    this.role = 'member',
    this.isActive = true,
  });

  final String userId;
  final String name;
  final String? profileImage;
  final String role;
  final bool isActive;

  bool get isAdmin => role == 'admin';

  factory GroupMember.fromJson(Map<String, dynamic> json) {
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
    }

    return GroupMember(
      userId: userId,
      name: name,
      profileImage: profileImage,
      role: json['role'] as String? ?? 'member',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        if (profileImage != null) 'profileImage': profileImage,
        'role': role,
        'isActive': isActive,
      };

  GroupMember copyWith({
    String? userId,
    String? name,
    String? profileImage,
    String? role,
    bool? isActive,
  }) {
    return GroupMember(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}

class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    this.members = const [],
    this.inviteCode,
    this.isTrackingActive = false,
    this.maxMembers = 10,
    this.isActive = true,
    this.coverImage,
  });

  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final List<GroupMember> members;
  final String? inviteCode;
  final bool isTrackingActive;
  final int maxMembers;
  final bool isActive;
  final String? coverImage;

  int get memberCount => members.where((m) => m.isActive).length;

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final createdByRaw = json['createdBy'];
    final createdBy = createdByRaw is Map<String, dynamic>
        ? (createdByRaw['_id']?.toString() ??
            createdByRaw['id']?.toString() ??
            '')
        : createdByRaw?.toString() ?? '';

    final membersRaw = json['members'] as List<dynamic>?;
    final members = membersRaw
            ?.map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return GroupModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      createdBy: createdBy,
      members: members,
      inviteCode: json['inviteCode'] as String?,
      isTrackingActive: json['isTrackingActive'] as bool? ?? false,
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 10,
      isActive: json['isActive'] as bool? ?? true,
      coverImage: json['coverImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'createdBy': createdBy,
        'members': members.map((m) => m.toJson()).toList(),
        if (inviteCode != null) 'inviteCode': inviteCode,
        'isTrackingActive': isTrackingActive,
        'maxMembers': maxMembers,
        'isActive': isActive,
        if (coverImage != null) 'coverImage': coverImage,
      };

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    List<GroupMember>? members,
    String? inviteCode,
    bool? isTrackingActive,
    int? maxMembers,
    bool? isActive,
    String? coverImage,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? this.members,
      inviteCode: inviteCode ?? this.inviteCode,
      isTrackingActive: isTrackingActive ?? this.isTrackingActive,
      maxMembers: maxMembers ?? this.maxMembers,
      isActive: isActive ?? this.isActive,
      coverImage: coverImage ?? this.coverImage,
    );
  }
}
