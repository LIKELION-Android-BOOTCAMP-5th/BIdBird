class KeywordType {
  final int id;
  final String title;
  final String created_at;

  KeywordType({
    required this.id,
    required this.title,
    required this.created_at,
  });

  factory KeywordType.fromJson(Map<String, dynamic> json) {
    return KeywordType(
      id: json['id'] as int,
      title: json['title'] as String,
      created_at: json['created_at'] as String,
    );
  }
}
