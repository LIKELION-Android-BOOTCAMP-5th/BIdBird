class ProfileEntity {
  const ProfileEntity({
    required this.id,
    this.nickName,
    this.profileImageUrl,
  });

  final String id;
  final String? nickName;
  final String? profileImageUrl;
}
