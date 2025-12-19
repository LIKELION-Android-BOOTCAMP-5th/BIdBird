import '../../domain/entities/profile_entity.dart';

class ProfileDto {
  ProfileDto({
    required this.id,
    required this.nickName,
    required this.profileImageUrl,
  });

  final String id;
  final String? nickName;
  final String? profileImageUrl;

  factory ProfileDto.fromMap(Map<String, dynamic> map) {
    return ProfileDto(
      id: map['id']?.toString() ?? '',
      nickName: map['nick_name'] as String?,
      profileImageUrl: map['profile_image'] as String?,
    );
  }

  ProfileEntity toEntity() {
    return ProfileEntity(
      id: id,
      nickName: nickName,
      profileImageUrl: profileImageUrl,
    );
  }
}
