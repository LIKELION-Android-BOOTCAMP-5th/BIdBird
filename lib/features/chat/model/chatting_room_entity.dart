class ChattingRoomEntity {
  final String id;
  final String item_id;
  final String user_id;
  final String? profile_image;
  final String? user_nickname;
  final String last_message;
  final String last_message_send_at;
  final String item_title;
  final int? count;
  ChattingRoomEntity({
    required this.id,
    required this.item_id,
    required this.user_id,
    required this.profile_image,
    required this.user_nickname,
    required this.last_message,
    required this.last_message_send_at,
    required this.item_title,
    required this.count,
  });
  factory ChattingRoomEntity.fromJson(Map<String, dynamic> json) {
    return ChattingRoomEntity(
      id: json['id'] as String,
      item_id: json['item_id'] as String,
      user_id: json['user_id'] as String,
      profile_image: json['profile_image'] as String?,
      user_nickname: json['user_nickname'] as String? ?? "사용자",
      last_message: json['last_message'] as String,
      last_message_send_at: json['last_message_send_at'] as String,
      item_title: json['item_title'] as String,
      count: int.tryParse(json['count'].toString()) ?? 0,
    );
  }
}
