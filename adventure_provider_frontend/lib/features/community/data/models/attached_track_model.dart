class AttachedTrackModel {
  const AttachedTrackModel({
    required this.trackId,
    required this.title,
    required this.type,
    required this.difficulty,
    required this.distanceMeters,
    this.coverImage,
  });

  final String trackId;
  final String title;
  final String type;
  final String difficulty;
  final double distanceMeters;
  final String? coverImage;

  String get distanceKm => '${(distanceMeters / 1000).toStringAsFixed(1)} km';

  factory AttachedTrackModel.fromJson(Map<String, dynamic> json) {
    return AttachedTrackModel(
      trackId: json['trackId']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0,
      coverImage: json['coverImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'trackId': trackId,
        'title': title,
        'type': type,
        'difficulty': difficulty,
        'distanceMeters': distanceMeters,
        if (coverImage != null) 'coverImage': coverImage,
      };

  AttachedTrackModel copyWith({
    String? trackId,
    String? title,
    String? type,
    String? difficulty,
    double? distanceMeters,
    String? coverImage,
  }) {
    return AttachedTrackModel(
      trackId: trackId ?? this.trackId,
      title: title ?? this.title,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      coverImage: coverImage ?? this.coverImage,
    );
  }
}

