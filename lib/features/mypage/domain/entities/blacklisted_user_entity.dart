class BlacklistedUserEntity {
  const BlacklistedUserEntity({
    required this.targetUserId,
    required this.nickName,
    required this.profileImageUrl,
    required this.registerUserId,
    required this.createdAt,
    this.isBlocked = true,
  });

  final String targetUserId;
  final String? nickName;
  final String? profileImageUrl;
  final String? registerUserId;
  final DateTime? createdAt;
  final bool isBlocked;

  BlacklistedUserEntity copyWith({
    bool? isBlocked,
    String? registerUserId,
    DateTime? createdAt,
  }) {
    return BlacklistedUserEntity(
      targetUserId: targetUserId,
      nickName: nickName,
      profileImageUrl: profileImageUrl,
      registerUserId: registerUserId ?? this.registerUserId,
      createdAt: createdAt ?? this.createdAt,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
