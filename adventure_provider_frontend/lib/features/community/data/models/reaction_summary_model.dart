class ReactionSummaryModel {
  const ReactionSummaryModel({
    this.fire = 0,
    this.heart = 0,
    this.clap = 0,
    this.wow = 0,
    this.haha = 0,
    this.strong = 0,
    this.userReaction,
    this.totalReactions = 0,
  });

  final int fire;
  final int heart;
  final int clap;
  final int wow;
  final int haha;
  final int strong;
  final String? userReaction;
  final int totalReactions;

  factory ReactionSummaryModel.fromJson(Map<String, dynamic> json) {
    final fire = (json['fire'] as num?)?.toInt() ?? 0;
    final heart = (json['heart'] as num?)?.toInt() ?? 0;
    final clap = (json['clap'] as num?)?.toInt() ?? 0;
    final wow = (json['wow'] as num?)?.toInt() ?? 0;
    final haha = (json['haha'] as num?)?.toInt() ?? 0;
    final strong = (json['strong'] as num?)?.toInt() ?? 0;

    final total = (json['totalReactions'] as num?)?.toInt() ??
        (fire + heart + clap + wow + haha + strong);

    return ReactionSummaryModel(
      fire: fire,
      heart: heart,
      clap: clap,
      wow: wow,
      haha: haha,
      strong: strong,
      userReaction: json['userReaction'] as String?,
      totalReactions: total,
    );
  }

  List<MapEntry<String, int>> get topReactions {
    final entries = <MapEntry<String, int>>[
      MapEntry('🔥', fire),
      MapEntry('❤️', heart),
      MapEntry('👏', clap),
      MapEntry('😮', wow),
      MapEntry('😂', haha),
      MapEntry('💪', strong),
    ].where((e) => e.value > 0).toList();

    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).toList();
  }
}

