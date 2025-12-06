import 'package:flutter/material.dart';

class UserTradeSummary {
  UserTradeSummary({
    required this.title,
    required this.price,
    required this.date,
    required this.statusLabel,
    required this.statusColor,
    this.thumbnailUrl,
  });

  final String title;
  final String price;
  final String date;
  final String statusLabel;
  final Color statusColor;
  final String? thumbnailUrl;
}

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
    required this.trades,
    required this.reviews,
  });

  final String userId;
  final String nickname;
  final double rating;
  final int reviewCount;
  final String avatarUrl;
  final List<UserTradeSummary> trades;
  final List<UserReview> reviews;
}
