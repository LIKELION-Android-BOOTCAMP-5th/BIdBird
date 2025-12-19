class AuthSetProfileEntity {
  final String id;
  final String? nickName;
  final String? profileImageUrl;
  final List<int>? keywordCodes;

  AuthSetProfileEntity({
    required this.id,
    this.nickName,
    this.profileImageUrl,
    this.keywordCodes,
  });

  factory AuthSetProfileEntity.fromMap(Map<String, dynamic> map) {
    final rawKeywordCodes = map['keyword_code'];

    return AuthSetProfileEntity(
      id: map['id'] as String,
      nickName: map['nick_name'] as String?,
      profileImageUrl: map['profile_image'] as String?,
      keywordCodes: rawKeywordCodes == null
          ? []
          : List<int>.from(rawKeywordCodes),
    );
  }
}


