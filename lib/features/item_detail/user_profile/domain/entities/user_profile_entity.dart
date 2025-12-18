class UserReview {
  UserReview({
    required this.fromUserId,
    required this.fromUserNickname,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String fromUserId;
  final String fromUserNickname;
  final double rating;
  final String comment;
  final DateTime createdAt;
}

class UserProfile {
  UserProfile({
    required this.userId,
    required this.nickname,
    required this.rating,
    required this.reviewCount,
    required this.avatarUrl,
    required this.reviews,
  });

  final String userId;
  final String nickname;
  final double rating;
  final int reviewCount;
  final String avatarUrl;
  final List<UserReview> reviews;
}



