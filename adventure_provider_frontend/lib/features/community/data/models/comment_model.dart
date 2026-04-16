class MentionModel {
  const MentionModel({
    required this.userId,
    required this.username,
  });

  final String userId;
  final String username;

  factory MentionModel.fromJson(Map<String, dynamic> json) {
    return MentionModel(
      userId: json['userId']?.toString() ?? '',
      username: json['username'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
      };

  MentionModel copyWith({
    String? userId,
    String? username,
  }) {
    return MentionModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
    );
  }
}

class CommentAuthorModel {
  const CommentAuthorModel({
    required this.id,
    required this.name,
    this.profileImage,
  });

  final String id;
  final String name;
  final String? profileImage;

  factory CommentAuthorModel.fromJson(Map<String, dynamic> json) {
    return CommentAuthorModel(
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

  CommentAuthorModel copyWith({
    String? id,
    String? name,
    String? profileImage,
  }) {
    return CommentAuthorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

class CommentModel {
  const CommentModel({
    required this.id,
    required this.content,
    this.likesCount = 0,
    this.isLiked = false,
    required this.createdAt,
    required this.author,
    this.mentions = const [],
  });

  final String id;
  final String content;
  final int likesCount;
  final bool isLiked;
  final DateTime createdAt;
  final CommentAuthorModel author;
  final List<MentionModel> mentions;

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final authorRaw = json['author'];
    final authorMap = authorRaw is Map<String, dynamic>
        ? authorRaw
        : (authorRaw is Map ? Map<String, dynamic>.from(authorRaw) : null);

    final mentionsRaw = json['mentions'];
    final mentions = mentionsRaw is List
        ? mentionsRaw
            .whereType<Object?>()
            .map((e) => e is Map<String, dynamic>
                ? MentionModel.fromJson(e)
                : MentionModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <MentionModel>[];

    return CommentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      content: json['content'] as String? ?? '',
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
      author: authorMap != null
          ? CommentAuthorModel.fromJson(authorMap)
          : const CommentAuthorModel(id: '', name: ''),
      mentions: mentions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'likesCount': likesCount,
        'isLiked': isLiked,
        'createdAt': createdAt.toIso8601String(),
        'author': author.toJson(),
        'mentions': mentions.map((m) => m.toJson()).toList(),
      };

  CommentModel copyWith({
    String? id,
    String? content,
    int? likesCount,
    bool? isLiked,
    DateTime? createdAt,
    CommentAuthorModel? author,
    List<MentionModel>? mentions,
  }) {
    return CommentModel(
      id: id ?? this.id,
      content: content ?? this.content,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
      mentions: mentions ?? this.mentions,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 30) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

