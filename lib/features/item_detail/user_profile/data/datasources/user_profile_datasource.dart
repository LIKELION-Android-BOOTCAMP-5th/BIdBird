import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/features/item_detail/user_profile/domain/entities/user_profile_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileDatasource {
  UserProfileDatasource({SupabaseClient? supabase})
    : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;
  
  // 프로필 캐시 (userId -> {profile, timestamp})
  static final Map<String, Map<String, dynamic>> _profileCache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // 캐시 유효성 확인
  bool _isCacheValid(String userId) {
    if (!_profileCache.containsKey(userId)) return false;
    final cacheEntry = _profileCache[userId];
    if (cacheEntry == null) return false;
    
    final timestamp = cacheEntry['timestamp'] as DateTime?;
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }
  
  // 캐시에서 프로필 반환
  UserProfile? _getCachedProfile(String userId) {
    if (!_isCacheValid(userId)) return null;
    return _profileCache[userId]?['profile'] as UserProfile?;
  }
  
  // 캐시에 프로필 저장
  void _setCachedProfile(String userId, UserProfile profile) {
    _profileCache[userId] = {
      'profile': profile,
      'timestamp': DateTime.now(),
    };
  }
  
  // 캐시 무효화
  static void invalidateCache(String? userId) {
    // if (userId == null) {
    //   _profileCache.clear();
    // } else {
    //   _profileCache.remove(userId);
    // }
  }

  Future<UserProfile> fetchUserProfile(String userId) async {
    // 캐시 확인: 유효한 캐시가 있으면 즉시 반환
    final cachedProfile = _getCachedProfile(userId);
    if (cachedProfile != null) {
      return cachedProfile;
    }
    
    // 1) 기본 유저 정보 조회 (닉네임, 아바타 등)
    Map<String, dynamic>? userRow;
    try {
      userRow = await _supabase
          .from('users')
          .select('id, nick_name, profile_image')
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      userRow = null;
    }

    String nickname;
    if (userRow != null) {
      final nickNameRaw = getNullableStringFromRow(userRow, 'nick_name');
      nickname = (nickNameRaw != null && nickNameRaw.isNotEmpty)
          ? nickNameRaw
          : '알 수 없음';
    } else {
      nickname = '알 수 없는 사용자';
    }

    final avatarUrl = userRow != null
        ? getStringFromRow(userRow, 'profile_image')
        : '';

    // 2) user_review 테이블에서 받은 리뷰들의 평점/개수 및 목록 집계
    double rating = 0;
    int reviewCount = 0;
    List<UserReview> reviewsList = [];

    try {
      final List<dynamic> reviews = await _supabase
          .from('user_review')
          .select('from_user_id, rating, comment, created_at')
          .eq('to_user_id', userId)
          .order('created_at', ascending: false);

      final ratings = <double>[];
      for (final row in reviews) {
        if (row is! Map<String, dynamic>) continue;
        final fromUserId = getStringFromRow(row, 'from_user_id');
        final ratingValue = getNullableDoubleFromRow(row, 'rating');
        final comment = getStringFromRow(row, 'comment');
        final createdAtRaw = getNullableStringFromRow(row, 'created_at');

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
        final List<dynamic> userRows = await _supabase
            .from('users')
            .select('id, nick_name')
            .inFilter('id', fromIds);

        final nickMap = <String, String>{};
        for (final row in userRows) {
          if (row is! Map<String, dynamic>) continue;
          final id = getNullableStringFromRow(row, 'id');
          final nick = getNullableStringFromRow(row, 'nick_name');
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
    } catch (e) {
      rating = 0;
      reviewCount = 0;
      reviewsList = [];
    }

    final profile = UserProfile(
      userId: userId,
      nickname: nickname,
      rating: rating,
      reviewCount: reviewCount,
      avatarUrl: avatarUrl,
      reviews: reviewsList,
    );
    
    // 캐시에 저장
    _setCachedProfile(userId, profile);
    
    return profile;
  }
}



