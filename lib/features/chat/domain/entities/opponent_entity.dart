class OpponentEntity {
  final String userId;
  final String? profileImage;
  final String? nickName;

  OpponentEntity({
    required this.userId,
    required this.profileImage,
    required this.nickName,
  });

  factory OpponentEntity.fromJson(Map<String, dynamic> json) {
    return OpponentEntity(
      userId: json['user_id'] as String,
      profileImage: json['profile_image'] as String?,
      nickName: json['nick_name'] as String?,
    );
  }
}
