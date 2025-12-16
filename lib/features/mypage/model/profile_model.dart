class Profile {
  final String id;
  final String? nickName;
  final String? profileImageUrl;

  Profile({required this.id, this.nickName, this.profileImageUrl});

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      nickName: map['nick_name'] as String?,
      profileImageUrl: map['profile_image'] as String?,
    );
  }
}
