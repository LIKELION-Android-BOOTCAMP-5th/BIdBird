class ToSEntity {
  final String content;
  final String createdAt;

  ToSEntity({
    required this.content,
    required this.createdAt,
  });

  factory ToSEntity.fromJson(Map<String, dynamic> json) {
    return ToSEntity(
      content: json['content'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}


