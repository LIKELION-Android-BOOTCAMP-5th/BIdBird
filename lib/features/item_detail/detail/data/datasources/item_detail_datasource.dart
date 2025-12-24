import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemDetailDatasource {
  ItemDetailDatasource({SupabaseClient? supabase})
    : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;
  bool? _lastIsTopBidder;
  bool? _lastIsFavorite;
  String? _lastSellerProfileImage;

  Future<ItemDetail?> fetchItemDetail(String itemId) async {
    try {
      final user = _supabase.auth.currentUser;
      
      // 직접 RPC 호출 (엣지 함수 제거)
      final coreData = await _supabase.rpc(
        'get_item_detail_core',
        params: {
          'p_item_id': itemId,
          'p_user_id': user?.id,
        },
      );

      if (coreData == null || coreData is! Map<String, dynamic>) {
        return null;
      }

      // 이미지 병렬 조회
      final imagesResult = await _supabase
          .from('item_images')
          .select('image_url')
          .eq('item_id', itemId)
          .order('sort_order', ascending: true)
          .limit(10);

      final images = (imagesResult as List<dynamic>?)
          ?.map((e) => (e as Map<String, dynamic>)['image_url']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList() ?? [];

      // finishTime 파싱
      String? finishTimeRaw = coreData['auction_end_at'] as String?;
      DateTime effectiveFinishTime;
      
      if (finishTimeRaw != null && finishTimeRaw.isNotEmpty) {
        effectiveFinishTime = DateTime.tryParse(finishTimeRaw) ?? DateTime.now();
      } else {
        final createdAt = DateTime.tryParse(coreData['created_at'] as String? ?? '') ?? DateTime.now();
        final durationHours = (coreData['auction_duration_hours'] as num?)?.toInt() ?? 24;
        effectiveFinishTime = createdAt.add(Duration(hours: durationHours));
      }

      // RPC에서 받은 값들 캐시
      _lastIsTopBidder = coreData['is_top_bidder'] as bool?;
      _lastIsFavorite = coreData['is_favorite'] as bool?;
      _lastSellerProfileImage = coreData['seller_profile_image'] as String?;

      return ItemDetail(
        itemId: coreData['item_id']?.toString() ?? itemId,
        sellerId: coreData['seller_id']?.toString() ?? '',
        itemTitle: coreData['title']?.toString() ?? '',
        itemImages: images,
        finishTime: effectiveFinishTime,
        sellerTitle: coreData['seller_nick_name']?.toString() ?? coreData['seller_name']?.toString() ?? '',
        buyNowPrice: (coreData['buy_now_price'] as num?)?.toInt() ?? 0,
        biddingCount: (coreData['bid_count'] as num?)?.toInt() ?? 0,
        itemContent: coreData['description']?.toString() ?? '',
        currentPrice: (coreData['current_price'] as num?)?.toInt() ?? 0,
        bidPrice: _calculateBidStep((coreData['current_price'] as num?)?.toInt() ?? 0),
        sellerRating: (coreData['seller_rating'] as num?)?.toDouble() ?? 0.0,
        sellerReviewCount: (coreData['seller_review_count'] as num?)?.toInt() ?? 0,
        statusCode: (coreData['auction_status_code'] as num?)?.toInt() ?? 0,
        tradeStatusCode: coreData['trade_status_code'] as int?,
      );
    } catch (e) {
      _lastIsTopBidder = null;
      _lastIsFavorite = null;
      _lastSellerProfileImage = null;
      return null;
    }
  }

  /// Bid step 계산
  int _calculateBidStep(int currentPrice) {
    if (currentPrice < 1000) return 100;
    if (currentPrice < 10000) return 500;
    if (currentPrice < 50000) return 1000;
    if (currentPrice < 100000) return 5000;
    if (currentPrice < 500000) return 10000;
    if (currentPrice < 1000000) return 50000;
    return 100000;
  }

  /// 마지막으로 fetchItemDetail에서 받은 isTopBidder 값 반환
  bool? getLastIsTopBidder() => _lastIsTopBidder;

  /// 마지막으로 fetchItemDetail에서 받은 isFavorite 값 반환
  bool? getLastIsFavorite() => _lastIsFavorite;

  /// 마지막으로 fetchItemDetail에서 받은 sellerProfileImage 값 반환
  String? getLastSellerProfileImage() => _lastSellerProfileImage;

  Future<bool> checkIsFavorite(String itemId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final List<dynamic> rows = await _supabase
          .from('favorites')
          .select('id')
          .eq('item_id', itemId)
          .eq('user_id', user.id)
          .limit(1);

      return rows.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleFavorite(String itemId, bool currentState) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    if (currentState) {
      await _supabase
          .from('favorites')
          .delete()
          .eq('item_id', itemId)
          .eq('user_id', user.id);
    } else {
      await _supabase.from('favorites').insert(<String, dynamic>{
        'item_id': itemId,
        'user_id': user.id,
      });
    }
  }

  Future<Map<String, dynamic>?> fetchSellerProfile(String sellerId) async {
    if (sellerId.isEmpty) return null;

    try {
      final response = await _supabase.functions.invoke(
        'get-seller-profile',
        body: {'sellerId': sellerId},
      );

      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        return null;
      }

      if (responseData['success'] == true && responseData['data'] != null) {
        return responseData['data'] as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> checkIsMyItem(String itemId, String sellerId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      // sellerId와 현재 사용자 ID를 비교
      return sellerId == user.id;
    } catch (e) {
      return false;
    }
  }

  Future<List<BidHistoryItem>> fetchBidHistory(String itemId) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-bid-history',
        body: {'itemId': itemId},
      );

      final responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        return [];
      }

      if (responseData['success'] == true && responseData['data'] != null) {
        final List<dynamic> bidHistoryList =
            responseData['data'] as List<dynamic>;
        return BidHistoryItem.fromMapList(bidHistoryList);
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// 현재 사용자가 최고 입찰자인지 확인 (DB 직접 조회)
  /// 입찰 직후 WebSocket 지연으로 인한 타이밍 이슈를 방지하기 위해 사용
  Future<bool> isCurrentUserTopBidder(String itemId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      // auctions 테이블에서 해당 아이템의 최고 입찰자 확인
      final List<dynamic> rows = await _supabase
          .from('auctions')
          .select('last_bid_user_id')
          .eq('item_id', itemId)
          .limit(1);

      if (rows.isNotEmpty) {
        final lastBidUserId = rows.first['last_bid_user_id'] as String?;
        return lastBidUserId != null && lastBidUserId == user.id;
      }

      return false;
    } catch (e) {
      // 조회 실패 시 false 반환 (WebSocket 업데이트 대기)
      return false;
    }
  }
}
