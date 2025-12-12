class ChattingNotificationSetEntity {
  final String id;
  final String userId;
  final String roomId;
  bool isNotificationOn;

  ChattingNotificationSetEntity({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.isNotificationOn,
  });

  factory ChattingNotificationSetEntity.fromJson(Map<String, dynamic> json) {
    return ChattingNotificationSetEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      roomId: json['room_id'] as String,
      isNotificationOn: json['is_notification_on'] as bool,
    );
  }
}