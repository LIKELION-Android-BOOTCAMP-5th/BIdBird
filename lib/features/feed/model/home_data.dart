class HomeCodeKeywordType {
  final int id;
  final String title;
  final String created_at;

  HomeCodeKeywordType({
    required this.id,
    required this.title,
    required this.created_at,
  });

  factory HomeCodeKeywordType.fromJson(Map<String, dynamic> json) {
    return HomeCodeKeywordType(
      id: json['id'] as int,
      title: json['title'] as String,
      created_at: json['created_at'] as String,
    );
  }
}
