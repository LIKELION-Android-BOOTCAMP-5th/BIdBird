import 'package:flutter/material.dart';

class UserTradeSummary {
  UserTradeSummary({
    required this.title,
    required this.price,
    required this.date,
    required this.statusLabel,
    required this.statusColor,
  });

  final String title;
  final String price;
  final String date;
  final String statusLabel;
  final Color statusColor;
}

class UserReview {
  UserReview({
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

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

// TODO: 실제 API 연동 전까지 사용하는 더미 데이터
final dummyUserProfile = UserProfile(
  userId: 'user_1',
  nickname: '김재현',
  rating: 4.0,
  reviewCount: 120,
  avatarUrl: '',
  trades: [
    UserTradeSummary(
      title: '1111',
      price: '55,000원',
      date: '1111.11.11',
      statusLabel: '구매 완료',
      statusColor: const Color(0xff4C6FFF),
    ),
    UserTradeSummary(
      title: '2222',
      price: '120,000원',
      date: '1111.11.11',
      statusLabel: '판매 완료',
      statusColor: const Color(0xff27AE60),
    ),
    UserTradeSummary(
      title: '3333',
      price: '250,000원',
      date: '1111.11.11',
      statusLabel: '입찰 중',
      statusColor: const Color(0xffF2994A),
    ),
    UserTradeSummary(
      title: '4444',
      price: '180,000원',
      date: '1111.11.11',
      statusLabel: '판매 완료',
      statusColor: const Color(0xff27AE60),
    ),
  ],
  reviews: [],
);
