class ChattingRoomEntity {
  final String id;
  final String itemId;
  final String userId;
  final String? profileImage;
  final String? userNickname;
  final String lastMessage;
  final String lastMessageSendAt;
  final String itemTitle;
  int? count;
  ChattingRoomEntity({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.profileImage,
    required this.userNickname,
    required this.lastMessage,
    required this.lastMessageSendAt,
    required this.itemTitle,
    required this.count,
  });
  factory ChattingRoomEntity.fromJson(Map<String, dynamic> json) {
    return ChattingRoomEntity(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      userId: json['user_id'] as String,
      profileImage: json['profile_image'] as String?,
      userNickname: json['user_nickname'] as String? ?? "사용자",
      lastMessage: json['last_message'] as String,
      lastMessageSendAt: json['last_message_send_at'] as String,
      itemTitle: json['item_title'] as String,
      count: int.tryParse(json['count'].toString()) ?? 0,
    );
  }
}