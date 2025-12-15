class ToSModel {
  final String content;
  final String created_at;

  ToSModel({required this.content, required this.created_at});

  factory ToSModel.fromJson(Map<String, dynamic> json) {
    return ToSModel(
      content: json['content'] as String,
      created_at: json['created_at'] as String,
    );
  }
}
