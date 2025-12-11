class ChattingNotificationSetEntity {
  final String id;
  final String user_id;
  final String room_id;
  bool is_notification_on;

  ChattingNotificationSetEntity({
    required this.id,
    required this.user_id,
    required this.room_id,
    required this.is_notification_on,
  });

  factory ChattingNotificationSetEntity.fromJson(Map<String, dynamic> json) {
    return ChattingNotificationSetEntity(
      id: json['id'] as String,
      user_id: json['user_id'] as String,
      room_id: json['room_id'] as String,
      is_notification_on: json['is_notification_on'] as bool,
    );
  }
}
