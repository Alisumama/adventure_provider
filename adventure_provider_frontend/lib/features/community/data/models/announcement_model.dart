class AnnouncementAuthorModel {
  const AnnouncementAuthorModel({
    required this.id,
    required this.name,
    this.profileImage,
  });

  final String id;
  final String name;
  final String? profileImage;

  factory AnnouncementAuthorModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementAuthorModel(
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

  AnnouncementAuthorModel copyWith({
    String? id,
    String? name,
    String? profileImage,
  }) {
    return AnnouncementAuthorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.isPinned = false,
    required this.createdAt,
    required this.author,
  });

  final String id;
  final String title;
  final String content;
  final bool isPinned;
  final DateTime createdAt;
  final AnnouncementAuthorModel author;

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    final authorRaw = json['author'];
    final authorMap = authorRaw is Map<String, dynamic>
        ? authorRaw
        : (authorRaw is Map ? Map<String, dynamic>.from(authorRaw) : null);

    return AnnouncementModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ??
              DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
      author: authorMap != null
          ? AnnouncementAuthorModel.fromJson(authorMap)
          : const AnnouncementAuthorModel(id: '', name: ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'isPinned': isPinned,
        'createdAt': createdAt.toIso8601String(),
        'author': author.toJson(),
      };

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? content,
    bool? isPinned,
    DateTime? createdAt,
    AnnouncementAuthorModel? author,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
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

