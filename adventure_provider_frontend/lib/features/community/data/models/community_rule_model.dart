class CommunityRuleModel {
  const CommunityRuleModel({
    required this.title,
    required this.description,
    required this.order,
  });

  final String title;
  final String description;
  final int order;

  factory CommunityRuleModel.fromJson(Map<String, dynamic> json) {
    return CommunityRuleModel(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'order': order,
      };
}

