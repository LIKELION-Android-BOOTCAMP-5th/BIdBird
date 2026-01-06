class NotificationEntity {
  final String id;
  final String user_id;
  final String? item_id;
  final String? room_id;
  final String? alarm_type;
  final String title;
  final String body;
  bool is_checked;
  final String created_at;
  String? deleted_at;

  NotificationEntity({
    required this.id,
    required this.user_id,
    required this.item_id,
    required this.room_id,
    required this.title,
    required this.alarm_type,
    required this.body,
    required this.is_checked,
    required this.created_at,
    required this.deleted_at,
  });

  factory NotificationEntity.fromJson(Map<String, dynamic> json) {
    return NotificationEntity(
      id: json["id"] as String,
      user_id: json["user_id"] as String,
      item_id: json["item_id"] as String?,
      room_id: json["room_id"] as String?,
      title: json["title"] as String,
      alarm_type: json["alarm_type"] as String?,
      body: json["body"] as String,
      is_checked: json["is_checked"] as bool,
      created_at: json["created_at"] as String,
      deleted_at: json["deleted_at"] as String?,
    );
  }
}
