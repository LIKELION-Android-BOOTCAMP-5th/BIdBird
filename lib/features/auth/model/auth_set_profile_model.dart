class AuthSetProfileModel {
  final String id;
  final String? nickName;
  final String? profileImageUrl;
  final List<int>? keywordCodes;

  AuthSetProfileModel({
    required this.id,
    this.nickName,
    // this.phoneNumber,
    this.profileImageUrl,
    this.keywordCodes,
  });

  factory AuthSetProfileModel.fromMap(Map<String, dynamic> map) {
    final rawKeywordCodes = map['keyword_code'];

    return AuthSetProfileModel(
      id: map['id'] as String,
      nickName: map['nick_name'] as String?,
      profileImageUrl: map['profile_image'] as String?,
      keywordCodes: rawKeywordCodes == null
          ? []
          : List<int>.from(rawKeywordCodes),
    );
  }
}
