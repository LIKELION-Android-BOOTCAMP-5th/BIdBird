class UserEntity {
  final String id;
  final String? name;
  final String? birth;
  final String? CI;
  final bool? is_banned;
  final String? created_at;
  final String? profile_image;
  final String? device_token;
  final String? device_type;
  final String? phone_number;
  final String? nick_name;
  final String? unregister_at;
  final String? email;

  UserEntity({
    required this.id,
    required this.name,
    required this.birth,
    required this.CI,
    required this.is_banned,
    required this.created_at,
    required this.profile_image,
    required this.device_token,
    required this.device_type,
    required this.phone_number,
    required this.nick_name,
    required this.unregister_at,
    required this.email,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      name: json['name'] as String?,
      birth: json['birth'] as String?,
      CI: json['CI'] as String?,
      is_banned: json['is_banned'] as bool?,
      created_at: json['created_at'] as String?,
      profile_image: json['profile_image'] as String?,
      device_token: json['device_token'] as String?,
      device_type: json['device_type'] as String?,
      phone_number: json['phone_number'] as String?,
      nick_name: json['nick_name'] as String?,
      unregister_at: json['unregister_at'] as String?,
      email: json['email'] as String?,
    );
  }
}
