import 'attached_track_model.dart';
import 'reaction_summary_model.dart';

/// Dio / JSON decode often yields [Map<dynamic, dynamic>]; strict [Map<String, dynamic>]
/// checks fail and break post parsing.
Map<String, dynamic>? _mapFromJson(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

class PostAuthorModel {
  const PostAuthorModel({
    required this.id,
    required this.name,
    this.profileImage,
  });

  final String id;
  final String name;
  final String? profileImage;

  factory PostAuthorModel.fromJson(Map<String, dynamic> json) {
    return PostAuthorModel(
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
    required this.id,
    required this.title,
    required this.type,
    required this.difficulty,
    required this.distance,
    this.coverImage,
  });

  final String id;
  final String title;
  final String type;
  final String difficulty;
  final double distance;
  final String? coverImage;

  String get distanceKm =>
      '${(distance / 1000).toStringAsFixed(1)} km';

  factory PostTrackModel.fromJson(Map<String, dynamic> json) {
    return PostTrackModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      coverImage: json['coverImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'difficulty': difficulty,
        'distance': distance,
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
    required this.id,
    required this.content,
    this.images = const [],
    this.likesCount = 0,
    this.isLiked = false,
    this.commentsCount = 0,
    this.isPinned = false,
    this.reactionSummary = const ReactionSummaryModel(),
    required this.createdAt,
    required this.author,
    this.track,
    this.attachedTrack,
  });

  final String id;
  final String content;
  final List<String> images;
  final int likesCount;
  final bool isLiked;
  final int commentsCount;
  final bool isPinned;
  final ReactionSummaryModel reactionSummary;
  final DateTime createdAt;
  final PostAuthorModel author;
  final PostTrackModel? track;
  final AttachedTrackModel? attachedTrack;

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['images'];
    final authorMap = _mapFromJson(json['author']);
    final trackMap = _mapFromJson(json['track']);
    final attachedTrackMap = _mapFromJson(json['attachedTrack']);

    final reactionCountsMap = _mapFromJson(json['reactionCounts']) ?? const <String, dynamic>{};
    final reactionSummary = ReactionSummaryModel.fromJson({
      'fire': reactionCountsMap['fire'],
      'heart': reactionCountsMap['heart'],
      'clap': reactionCountsMap['clap'],
      'wow': reactionCountsMap['wow'],
      'haha': reactionCountsMap['haha'],
      'strong': reactionCountsMap['strong'],
      'userReaction': json['userReaction'],
      'totalReactions': json['totalReactions'],
    });
    return CommunityPostModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      content: json['content'] as String? ?? '',
      images: imagesRaw is List
          ? imagesRaw.map((e) => e.toString()).toList()
          : const [],
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
      reactionSummary: reactionSummary,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
      author: authorMap != null
          ? PostAuthorModel.fromJson(authorMap)
          : const PostAuthorModel(id: '', name: ''),
      track: trackMap != null && trackMap.isNotEmpty
          ? PostTrackModel.fromJson(trackMap)
          : null,
      attachedTrack: attachedTrackMap != null && attachedTrackMap.isNotEmpty
          ? AttachedTrackModel.fromJson(attachedTrackMap)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'images': images,
        'likesCount': likesCount,
        'isLiked': isLiked,
        'commentsCount': commentsCount,
        'isPinned': isPinned,
        'reactionCounts': {
          'fire': reactionSummary.fire,
          'heart': reactionSummary.heart,
          'clap': reactionSummary.clap,
          'wow': reactionSummary.wow,
          'haha': reactionSummary.haha,
          'strong': reactionSummary.strong,
        },
        if (reactionSummary.userReaction != null) 'userReaction': reactionSummary.userReaction,
        'createdAt': createdAt.toIso8601String(),
        'author': author.toJson(),
        if (track != null) 'track': track!.toJson(),
        if (attachedTrack != null) 'attachedTrack': attachedTrack!.toJson(),
      };

  CommunityPostModel copyWith({
    String? id,
    String? content,
    List<String>? images,
    int? likesCount,
    bool? isLiked,
    int? commentsCount,
    bool? isPinned,
    ReactionSummaryModel? reactionSummary,
    DateTime? createdAt,
    PostAuthorModel? author,
    PostTrackModel? track,
    AttachedTrackModel? attachedTrack,
  }) {
    return CommunityPostModel(
      id: id ?? this.id,
      content: content ?? this.content,
      images: images ?? this.images,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      commentsCount: commentsCount ?? this.commentsCount,
      isPinned: isPinned ?? this.isPinned,
      reactionSummary: reactionSummary ?? this.reactionSummary,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
      track: track ?? this.track,
      attachedTrack: attachedTrack ?? this.attachedTrack,
    );
  }
}
