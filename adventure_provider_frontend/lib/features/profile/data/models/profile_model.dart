import '../../../auth/data/models/user_model.dart';

class ProfileModel {
  const ProfileModel({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.bio,
    this.profileImage,
    this.coverImage,
    this.totalTracks,
    this.totalDistance,
    this.totalSteps,
    this.totalAdventures,
    this.emergencyName,
    this.emergencyPhone,
    this.emergencyRelation,
  });

  final String? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? bio;
  final String? profileImage;
  final String? coverImage;
  final int? totalTracks;
  final double? totalDistance; // meters
  final int? totalSteps;
  final int? totalAdventures;

  final String? emergencyName;
  final String? emergencyPhone;
  final String? emergencyRelation;

  bool get _hasEmergencyContactData =>
      (emergencyName?.trim().isNotEmpty ?? false) ||
      (emergencyPhone?.trim().isNotEmpty ?? false) ||
      (emergencyRelation?.trim().isNotEmpty ?? false);

  EmergencyContactModel? get emergencyContact => _hasEmergencyContactData
      ? EmergencyContactModel(
          name: emergencyName,
          phone: emergencyPhone,
          relation: emergencyRelation,
        )
      : null;

  String get totalDistanceKm => ((totalDistance ?? 0) / 1000).toStringAsFixed(1);

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final emergency = json['emergencyContact'];
    final emergencyMap = emergency is Map<String, dynamic> ? emergency : null;

    return ProfileModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      profileImage: json['profileImage'] as String?,
      coverImage: json['coverImage'] as String?,
      totalTracks: (json['totalTracks'] as num?)?.toInt(),
      totalDistance: (json['totalDistance'] as num?)?.toDouble(),
      totalSteps: (json['totalSteps'] as num?)?.toInt(),
      totalAdventures: (json['totalAdventures'] as num?)?.toInt(),
      emergencyName: emergencyMap?['name'] as String?,
      emergencyPhone: emergencyMap?['phone'] as String?,
      emergencyRelation: emergencyMap?['relation'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (bio != null) 'bio': bio,
        if (profileImage != null) 'profileImage': profileImage,
        if (coverImage != null) 'coverImage': coverImage,
        if (totalTracks != null) 'totalTracks': totalTracks,
        if (totalDistance != null) 'totalDistance': totalDistance,
        if (totalSteps != null) 'totalSteps': totalSteps,
        if (totalAdventures != null) 'totalAdventures': totalAdventures,
        'emergencyContact': {
          'name': emergencyName ?? '',
          'phone': emergencyPhone ?? '',
          'relation': emergencyRelation ?? '',
        },
      };

  ProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? profileImage,
    String? coverImage,
    int? totalTracks,
    double? totalDistance,
    int? totalSteps,
    int? totalAdventures,
    String? emergencyName,
    String? emergencyPhone,
    String? emergencyRelation,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      profileImage: profileImage ?? this.profileImage,
      coverImage: coverImage ?? this.coverImage,
      totalTracks: totalTracks ?? this.totalTracks,
      totalDistance: totalDistance ?? this.totalDistance,
      totalSteps: totalSteps ?? this.totalSteps,
      totalAdventures: totalAdventures ?? this.totalAdventures,
      emergencyName: emergencyName ?? this.emergencyName,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      emergencyRelation: emergencyRelation ?? this.emergencyRelation,
    );
  }
}

