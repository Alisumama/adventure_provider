class EmergencyContactModel {
  final String? name;
  final String? phone;
  final String? relation;

  const EmergencyContactModel({
    this.name,
    this.phone,
    this.relation,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EmergencyContactModel();
    return EmergencyContactModel(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name ?? '',
        'phone': phone ?? '',
        'relation': relation ?? '',
      };

  EmergencyContactModel copyWith({
    String? name,
    String? phone,
    String? relation,
  }) {
    return EmergencyContactModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relation: relation ?? this.relation,
    );
  }
}

class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? profileImage;
  final String? bio;
  final EmergencyContactModel? emergencyContact;
  final int? totalTracks;
  final double? totalDistance;
  final int? totalSteps;
  final int? totalAdventures;
  final bool? isActive;
  final bool? isEmailVerified;
  final DateTime? createdAt;

  const UserModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.profileImage,
    this.bio,
    this.emergencyContact,
    this.totalTracks,
    this.totalDistance,
    this.totalSteps,
    this.totalAdventures,
    this.isActive,
    this.isEmailVerified,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      profileImage: json['profileImage'] as String?,
      bio: json['bio'] as String?,
      emergencyContact: EmergencyContactModel.fromJson(
        json['emergencyContact'] as Map<String, dynamic>?,
      ),
      totalTracks: (json['totalTracks'] as num?)?.toInt(),
      totalDistance: (json['totalDistance'] as num?)?.toDouble(),
      totalSteps: (json['totalSteps'] as num?)?.toInt(),
      totalAdventures: (json['totalAdventures'] as num?)?.toInt(),
      isActive: json['isActive'] as bool?,
      isEmailVerified: json['isEmailVerified'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (profileImage != null) 'profileImage': profileImage,
        if (bio != null) 'bio': bio,
        if (emergencyContact != null)
          'emergencyContact': emergencyContact!.toJson(),
        if (totalTracks != null) 'totalTracks': totalTracks,
        if (totalDistance != null) 'totalDistance': totalDistance,
        if (totalSteps != null) 'totalSteps': totalSteps,
        if (totalAdventures != null) 'totalAdventures': totalAdventures,
        if (isActive != null) 'isActive': isActive,
        if (isEmailVerified != null) 'isEmailVerified': isEmailVerified,
        if (createdAt != null) 'createdAt': createdAt?.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    String? bio,
    EmergencyContactModel? emergencyContact,
    int? totalTracks,
    double? totalDistance,
    int? totalSteps,
    int? totalAdventures,
    bool? isActive,
    bool? isEmailVerified,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      totalTracks: totalTracks ?? this.totalTracks,
      totalDistance: totalDistance ?? this.totalDistance,
      totalSteps: totalSteps ?? this.totalSteps,
      totalAdventures: totalAdventures ?? this.totalAdventures,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
