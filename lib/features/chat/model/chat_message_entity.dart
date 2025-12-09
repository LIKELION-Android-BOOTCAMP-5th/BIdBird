class ChatMessageEntity {
  final String id;
  final String room_id;
  final String sender_id;
  final String message_type;
  final String? text;
  final String? image_url;
  final String? thumbnail_url;
  final String created_at;

  ChatMessageEntity({
    required this.id,
    required this.room_id,
    required this.sender_id,
    required this.message_type,
    required this.text,
    required this.image_url,
    required this.thumbnail_url,
    required this.created_at,
  });

  factory ChatMessageEntity.fromJson(Map<String, dynamic> json) {
    return ChatMessageEntity(
      id: json['id'] as String,
      room_id: json['room_id'] as String,
      sender_id: json['sender_id'] as String,
      message_type: json['message_type'] as String,
      text: json['text'] as String?,
      image_url: json['image_url'] as String?,
      thumbnail_url: json['thumbnail_url'] as String?,
      created_at: json['created_at'] as String,
    );
  }
}
