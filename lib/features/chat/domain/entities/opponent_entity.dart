class OpponentEntity {
  final String? profileImage;
  final String? nickName;

  OpponentEntity({required this.profileImage, required this.nickName});

  factory OpponentEntity.fromJson(Map<String, dynamic> json) {
    return OpponentEntity(
      profileImage: json['profile_image'] as String?,
      nickName: json['nick_name'] as String?,
    );
  }
}


