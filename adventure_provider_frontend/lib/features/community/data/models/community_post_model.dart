class PostAuthorModel {
  const PostAuthorModel({
    this.id,
    this.name,
    this.profileImage,
  });

  final String? id;
  final String? name;
  final String? profileImage;

  factory PostAuthorModel.fromJson(Map<String, dynamic> json) {
    return PostAuthorModel(
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

  PostAuthorModel copyWith({
    String? id,
    String? name,
    String? profileImage,
  }) {
    return PostAuthorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

class PostTrackModel {
  const PostTrackModel({
    this.id,
    this.title,
    this.type,
    this.difficulty,
    this.distance,
    this.coverImage,
  });

  final String? id;
  final String? title;
  final String? type;
  final String? difficulty;
  final double? distance;
  final String? coverImage;

  String get distanceKm =>
      '${((distance ?? 0) / 1000).toStringAsFixed(1)} km';

  factory PostTrackModel.fromJson(Map<String, dynamic> json) {
    return PostTrackModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      title: json['title'] as String?,
      type: json['type'] as String?,
      difficulty: json['difficulty'] as String?,
      distance: (json['distance'] as num?)?.toDouble(),
      coverImage: json['coverImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        if (title != null) 'title': title,
        if (type != null) 'type': type,
        if (difficulty != null) 'difficulty': difficulty,
        if (distance != null) 'distance': distance,
        if (coverImage != null) 'coverImage': coverImage,
      };

  PostTrackModel copyWith({
    String? id,
    String? title,
    String? type,
    String? difficulty,
    double? distance,
    String? coverImage,
  }) {
    return PostTrackModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      distance: distance ?? this.distance,
      coverImage: coverImage ?? this.coverImage,
    );
  }
}

class CommunityPostModel {
  const CommunityPostModel({
    this.id,
    this.content,
    this.images = const [],
    this.likesCount,
    this.isLiked = false,
    this.createdAt,
    required this.author,
    this.track,
  });

  final String? id;
  final String? content;
  final List<String> images;
  final int? likesCount;
  final bool isLiked;
  final DateTime? createdAt;
  final PostAuthorModel author;
  final PostTrackModel? track;

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['images'];
    final images = imagesRaw is List
        ? imagesRaw.map((e) => e.toString()).toList()
        : <String>[];

    final authorRaw = json['author'];
    final author = authorRaw is Map<String, dynamic>
        ? PostAuthorModel.fromJson(authorRaw)
        : const PostAuthorModel();

    final trackRaw = json['track'];
    final track = trackRaw is Map<String, dynamic> ? PostTrackModel.fromJson(trackRaw) : null;

    return CommunityPostModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      content: json['content'] as String?,
      images: images,
      likesCount: (json['likesCount'] as num?)?.toInt(),
      isLiked: json['isLiked'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      author: author,
      track: track,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        if (content != null) 'content': content,
        'images': images,
        if (likesCount != null) 'likesCount': likesCount,
        'isLiked': isLiked,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        'author': author.toJson(),
        if (track != null) 'track': track!.toJson(),
      };

  CommunityPostModel copyWith({
    String? id,
    String? content,
    List<String>? images,
    int? likesCount,
    bool? isLiked,
    DateTime? createdAt,
    PostAuthorModel? author,
    PostTrackModel? track,
  }) {
    return CommunityPostModel(
      id: id ?? this.id,
      content: content ?? this.content,
      images: images ?? this.images,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
      track: track ?? this.track,
    );
  }
}
