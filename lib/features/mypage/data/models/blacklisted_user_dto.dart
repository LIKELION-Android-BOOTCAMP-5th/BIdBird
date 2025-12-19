import '../../domain/entities/blacklisted_user_entity.dart';

class BlacklistedUserDto {
  const BlacklistedUserDto({
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

  BlacklistedUserEntity toEntity() {
    return BlacklistedUserEntity(
      targetUserId: targetUserId,
      nickName: nickName,
      profileImageUrl: profileImageUrl,
      registerUserId: registerUserId,
      createdAt: createdAt,
      isBlocked: isBlocked,
    );
  }
}
