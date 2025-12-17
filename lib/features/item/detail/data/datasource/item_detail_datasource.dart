import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemDetailDatasource {
  ItemDetailDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;
  bool? _lastIsTopBidder;

  Future<ItemDetail?> fetchItemDetail(String itemId) async {
    try {
      // 엣지 펑션 호출
      final response = await _supabase.functions.invoke(
        'getItemDetail',
        body: {'itemId': itemId},
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) return null;

      if (data['success'] != true) {
        return null;
      }

      final itemData = data['data'] as Map<String, dynamic>;
      if (itemData.isEmpty) return null;

      // finishTime 파싱
      final finishTimeRaw = getStringFromRow(itemData, 'finishTime');
      final effectiveFinishTime = finishTimeRaw.isNotEmpty
          ? DateTime.tryParse(finishTimeRaw) ?? DateTime.now()
          : DateTime.now();

      // 엣지 펑션에서 반환한 isTopBidder 저장
      _lastIsTopBidder = itemData['isTopBidder'] as bool? ?? false;

      return ItemDetail(
        itemId: getStringFromRow(itemData, 'itemId', itemId),
        sellerId: getStringFromRow(itemData, 'sellerId'),
        itemTitle: getStringFromRow(itemData, 'itemTitle'),
        itemImages: (itemData['itemImages'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList() ??
            [],
        finishTime: effectiveFinishTime,
        sellerTitle: getStringFromRow(itemData, 'sellerTitle'),
        buyNowPrice: getIntFromRow(itemData, 'buyNowPrice'),
        biddingCount: getIntFromRow(itemData, 'biddingCount'),
        itemContent: getStringFromRow(itemData, 'itemContent'),
        currentPrice: getIntFromRow(itemData, 'currentPrice'),
        bidPrice: getIntFromRow(itemData, 'bidPrice'),
        sellerRating: getDoubleFromRow(itemData, 'sellerRating'),
        sellerReviewCount: getIntFromRow(itemData, 'sellerReviewCount'),
        statusCode: getIntFromRow(itemData, 'statusCode'),
        tradeStatusCode: getNullableIntFromRow(itemData, 'tradeStatusCode'),
      );
    } catch (e, stackTrace) {
      // 엣지 펑션 호출 실패 시 null 반환
      _lastIsTopBidder = null;
      return null;
    }
  }

  /// 마지막으로 fetchItemDetail에서 받은 isTopBidder 값 반환
  /// 엣지 펑션을 사용하는 경우에만 유효
  bool? getLastIsTopBidder() => _lastIsTopBidder;

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
    } catch (e, stackTrace) {
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
      // 민감 정보(email) 제외
      final userRow = await _supabase
          .from('users')
          .select('''
            id,
            name,
            nick_name,
            profile_image,
            created_at
          ''')
          .eq('id', sellerId)
          .maybeSingle();

      if (userRow is Map<String, dynamic>) {
        final ratingSummary = await _fetchSellerRating(sellerId);

        return {
          ...userRow,
          'profile_image_url': userRow['profile_image'],
          'rating': ratingSummary.rating,
          'review_count': ratingSummary.reviewCount,
        };
      }
      return null;
    } catch (e, stackTrace) {
      return null;
    }
  }

  Future<SellerRatingSummary> _fetchSellerRating(String sellerId) async {
    try {
      // 프로필 화면과 동일하게 user_review 기준으로 평균 평점 계산
      final reviews = await _supabase
          .from('user_review')
          .select('rating')
          .eq('to_user_id', sellerId)
          .not('rating', 'is', null);

      return SellerRatingSummary.fromCompletedTrades(reviews);
    } catch (e, stackTrace) {
      return SellerRatingSummary(rating: 0.0, reviewCount: 0);
    }
  }

  Future<bool> checkIsMyItem(String itemId, String sellerId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      // sellerId와 현재 사용자 ID를 비교
      return sellerId == user.id;
    } catch (e, stackTrace) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchBidHistory(String itemId) async {
    try {
      // 1) 해당 아이템의 경매 ID 조회 (round 1 기준)
      final auctionRow = await _supabase
          .from('auctions')
          .select('auction_id')
          .eq('item_id', itemId)
          .eq('round', 1)
          .maybeSingle();

      if (auctionRow is! Map<String, dynamic>) {
        return [];
      }

      final String? auctionId = getNullableStringFromRow(auctionRow, 'auction_id');
      if (auctionId == null || auctionId.isEmpty) {
        return [];
      }

      // 2) 해당 경매의 모든 로그를 auctions_status_log 에서 조회
      //    (실제 화면에서는 price가 0이 아닌 기록만 노출함)
      final List<dynamic> rows = await _supabase
          .from('auctions_status_log')
          .select('bid_status_id, bid_price, auction_log_code, created_at')
          .eq('bid_status_id', auctionId)
          .order('created_at', ascending: false)
          .limit(10);

      final List<Map<String, dynamic>> bidHistory = [];

      for (final row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final logRow = row;

        final int price = getIntFromRow(logRow, 'bid_price');

        bidHistory.add({
          'price': price,
          'user_name': '익명 참여자',
          'user_id': '',
          'created_at': getStringFromRow(logRow, 'created_at'),
          'profile_image_url': null,
          'auction_log_code': logRow['auction_log_code'],
        });
      }

      return bidHistory;
    } catch (e, stackTrace) {
      return [];
    }
  }
}
