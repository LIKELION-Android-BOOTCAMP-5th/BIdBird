import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/user_profile/model/user_profile_entity.dart';
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
          .select('id, nick_name')
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
    // 현재 users 테이블에 프로필 이미지 컬럼이 없으므로 빈 문자열 사용
    final avatarUrl = '';

    // 2) user_review 테이블에서 받은 리뷰들의 평점/개수 및 목록 집계
    double rating = 0;
    int reviewCount = 0;
    List<UserReview> reviewsList = [];

    try {
      final reviews = await _supabase
          .from('user_review')
          .select('rating, comment, created_at')
          .eq('to_user_id', userId)
          .order('created_at', ascending: false);

      if (reviews is List) {
        final ratings = <double>[];
        for (final row in reviews) {
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
    // TODO: 실제 userId 별 거래내역 조회로 교체
    await Future.delayed(const Duration(milliseconds: 200));
    return dummyUserProfile.trades;
  }
}
