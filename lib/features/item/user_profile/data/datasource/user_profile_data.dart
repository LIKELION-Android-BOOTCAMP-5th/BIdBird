import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/user_profile/model/user_profile_entity.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileDatasource {
  UserProfileDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<UserProfile> fetchUserProfile(String userId) async {
    // 1) 기본 유저 정보 조회 (닉네임, 아바타 등)
    Map<String, dynamic>? userRow;
    try {
      userRow = await _supabase
          .from('users')
          .select('id, nick_name, profile_image')
          .eq('id', userId)
          .maybeSingle();
    } catch (e, st) {
      userRow = null;
    }

    String nickname;
    if (userRow != null) {
      final nickNameRaw = userRow['nick_name']?.toString();
      nickname = (nickNameRaw != null && nickNameRaw.isNotEmpty)
          ? nickNameRaw
          : '알 수 없음';
    } else {
      nickname = '알 수 없는 사용자';
    }
    final avatarUrl = userRow != null
        ? (userRow['profile_image']?.toString() ?? '')
        : '';

    // 2) user_review 테이블에서 받은 리뷰들의 평점/개수 및 목록 집계
    double rating = 0;
    int reviewCount = 0;
    List<UserReview> reviewsList = [];

    try {
      final reviews = await _supabase
          .from('user_review')
          .select('from_user_id, rating, comment, created_at')
          .eq('to_user_id', userId)
          .order('created_at', ascending: false);

      if (reviews is List) {
        final ratings = <double>[];
        for (final row in reviews) {
          final fromUserId = row['from_user_id']?.toString() ?? '';
          final ratingValue = (row['rating'] as num?)?.toDouble();
          final comment = row['comment']?.toString() ?? '';
          final createdAtRaw = row['created_at']?.toString();

          if (ratingValue != null) {
            ratings.add(ratingValue);
          }

          if (ratingValue != null || comment.isNotEmpty) {
            DateTime? createdAt;
            if (createdAtRaw != null) {
              createdAt = DateTime.tryParse(createdAtRaw);
            }
            reviewsList.add(
              UserReview(
                fromUserId: fromUserId,
                fromUserNickname: '',
                rating: ratingValue ?? 0,
                comment: comment,
                createdAt: createdAt ?? DateTime.now(),
              ),
            );
          }
        }
        reviewCount = ratings.length;
        if (reviewCount > 0) {
          rating = ratings.reduce((a, b) => a + b) / reviewCount;
        }

        // 작성자 닉네임 조회
        final fromIds = reviewsList
            .map((e) => e.fromUserId)
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

        if (fromIds.isNotEmpty) {
          final userRows = await _supabase
              .from('users')
              .select('id, nick_name')
              .inFilter('id', fromIds);

          if (userRows is List) {
            final nickMap = <String, String>{};
            for (final row in userRows) {
              final id = row['id']?.toString();
              final nick = row['nick_name']?.toString();
              if (id != null && nick != null && nick.isNotEmpty) {
                nickMap[id] = nick;
              }
            }

            reviewsList = reviewsList
                .map(
                  (e) => UserReview(
                    fromUserId: e.fromUserId,
                    fromUserNickname: nickMap[e.fromUserId] ?? '',
                    rating: e.rating,
                    comment: e.comment,
                    createdAt: e.createdAt,
                  ),
                )
                .toList();
          }
        }
      }
    } catch (_) {
      rating = 0;
      reviewCount = 0;
      reviewsList = [];
    }

    return UserProfile(
      userId: userId,
      nickname: nickname,
      rating: rating,
      reviewCount: reviewCount,
      avatarUrl: avatarUrl,
      trades: const [], // TODO: 실제 거래 내역 쿼리로 교체
      reviews: reviewsList,
    );
  }

  Future<List<UserTradeSummary>> fetchUserTrades(String userId) async {
    if (userId.isEmpty) return [];

    try {
      final rows = await _supabase
          .from('items')
          .select('title, thumbnail_image, current_price, created_at, status_code')
          .eq('seller_id', userId)
          .order('created_at', ascending: false);

      if (rows is! List) return [];

      return rows.map<UserTradeSummary>((row) {
        final String title = row['title']?.toString() ?? '';
        final String? thumbnailUrl = row['thumbnail_image']?.toString();
        final int priceValue = (row['current_price'] as int?) ?? 0;
        final String price = _formatPrice(priceValue);
        final String date = _formatDate(row['created_at']?.toString());
        final int statusCode = (row['status_code'] as int?) ?? 0;

        final _StatusInfo status = _mapStatus(statusCode);

        return UserTradeSummary(
          title: title,
          price: price,
          date: date,
          statusLabel: status.label,
          statusColor: status.color,
          thumbnailUrl: thumbnailUrl,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  String _formatPrice(int price) {
    final buffer = StringBuffer();
    final text = price.toString();
    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1 && i != text.length - 1) {
        buffer.write(',');
      }
    }
    return '${buffer.toString()}원';
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(isoString);
      if (dt == null) return '';
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '${dt.year}.$m.$d';
    } catch (_) {
      return '';
    }
  }
}

class _StatusInfo {
  _StatusInfo(this.label, this.color);

  final String label;
  final Color color;
}

_StatusInfo _mapStatus(int code) {
  switch (code) {
    case 1001: // 경매 대기
    case 1002: // 경매 등록
    case 1003: // 입찰 발생
    case 1006: // 즉시 구매 대기
      return _StatusInfo('입찰 중', const Color(0xffF2994A));
    case 1007: // 즉시 구매 완료
      return _StatusInfo('구매 완료', const Color(0xff4C6FFF));
    case 1009: // 경매 종료 - 낙찰
      return _StatusInfo('판매 완료', const Color(0xff27AE60));
    default:
      return _StatusInfo('입찰 중', const Color(0xffF2994A));
  }
}
