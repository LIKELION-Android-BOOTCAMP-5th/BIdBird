class ChatMessageEntity {
  final String id;
  final String roomId;
  final String senderId;
  final String messageType;
  final String? text;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String createdAt;

  ChatMessageEntity({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.messageType,
    required this.text,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.createdAt,
  });

  factory ChatMessageEntity.fromJson(Map<String, dynamic> json) {
    return ChatMessageEntity(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      senderId: json['sender_id'] as String,
      messageType: json['message_type'] as String,
      text: json['text'] as String?,
      imageUrl: json['image_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'message_type': messageType,
      'text': text,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'created_at': createdAt,
    };
  }
}