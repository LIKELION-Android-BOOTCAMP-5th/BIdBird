import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemDetailDatasource {
  ItemDetailDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<ItemDetail?> fetchItemDetail(String itemId) async {
    final List<dynamic> result = await _supabase
        .from('items_detail')
        .select()
        .eq('item_id', itemId)
        .limit(1);

    if (result.isEmpty) return null;

    final firstResult = result.first;
    if (firstResult is! Map<String, dynamic>) return null;
    final row = firstResult;

    DateTime? finishTime;

    final String sellerId = getStringFromRow(row, 'seller_id');
    String sellerTitle = await _fetchSellerName(sellerId, row);

    SellerRatingSummary? ratingSummary;
    if (sellerId.isNotEmpty) {
      ratingSummary = await _fetchSellerRating(sellerId);
    }

    final List<String> images = await _fetchImages(itemId);

    int biddingCount = 0;
    int currentPrice = 0;
    int statusCode = 0;
    int? tradeStatusCode;

    try {
      final auctionRow = await _supabase
          .from('auctions')
          .select(
            'current_price, bid_count, auction_status_code, trade_status_code, auction_end_at',
          )
          .eq('item_id', itemId)
          .eq('round', 1)
          .maybeSingle();

      if (auctionRow is Map<String, dynamic>) {
        currentPrice = getIntFromRow(auctionRow, 'current_price');
        biddingCount = getIntFromRow(auctionRow, 'bid_count');
        statusCode = getIntFromRow(auctionRow, 'auction_status_code');
        tradeStatusCode = getNullableIntFromRow(auctionRow, 'trade_status_code');

        final endRaw = getNullableStringFromRow(auctionRow, 'auction_end_at');
        if (endRaw != null && endRaw.isNotEmpty) {
          finishTime = DateTime.tryParse(endRaw);
        }
      }
    } catch (e) {
      // auction info 조회 실패 시 조용히 처리
    }

    final minBidStep = ItemPriceHelper.calculateBidStep(currentPrice);

    DateTime effectiveFinishTime;
    if (finishTime != null) {
      effectiveFinishTime = finishTime;
    } else {
      final createdAtRaw = getNullableStringFromRow(row, 'created_at');
      final createdAt = createdAtRaw != null
          ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
          : DateTime.now();
      final durationHours = getIntFromRow(row, 'auction_duration_hours', 24);
      effectiveFinishTime = createdAt.add(Duration(hours: durationHours));
    }

    return ItemDetail(
      itemId: getStringFromRow(row, 'item_id', itemId),
      sellerId: sellerId,
      itemTitle: getStringFromRow(row, 'title'),
      itemImages: images,
      finishTime: effectiveFinishTime,
      sellerTitle: sellerTitle,
      buyNowPrice: getIntFromRow(row, 'buy_now_price'),
      biddingCount: biddingCount,
      itemContent: getStringFromRow(row, 'description'),
      currentPrice: currentPrice,
      bidPrice: minBidStep,
      sellerRating: ratingSummary?.rating ??
          getDoubleFromRow(row, 'seller_rating'),
      sellerReviewCount: ratingSummary?.reviewCount ??
          getIntFromRow(row, 'seller_review_count'),
      statusCode: statusCode,
      tradeStatusCode: tradeStatusCode,
    );
  }

  Future<String> _fetchSellerName(
    String sellerId,
    Map<String, dynamic> row,
  ) async {
    String sellerTitle = getStringFromRow(row, 'seller_name');

    if (sellerTitle.isEmpty && sellerId.isNotEmpty) {
      try {
        final userRow = await _supabase
            .from('users')
            .select('nick_name, name')
            .eq('id', sellerId)
            .maybeSingle();

        if (userRow is Map<String, dynamic>) {
          final rawNick = getStringFromRow(userRow, 'nick_name');
          sellerTitle = rawNick.isNotEmpty
              ? rawNick
              : getStringFromRow(userRow, 'name');
        }
      } catch (e) {
        // seller name 조회 실패 시 조용히 처리
      }
    }

    return sellerTitle;
  }

  Future<List<String>> _fetchImages(String itemId) async {
    final List<String> images = [];

    try {
      final imageRows = await _supabase
          .from('item_images')
          .select('image_url')
          .eq('item_id', itemId)
          .order('sort_order', ascending: true);

      for (final Map<String, dynamic> imgRow in imageRows) {
        final imageUrl = getNullableStringFromRow(imgRow, 'image_url');
        if (imageUrl != null && imageUrl.isNotEmpty) {
          images.add(imageUrl);
        }
      }
    } catch (e) {
      // images 조회 실패 시 조용히 처리
    }

    return images;
  }

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

  Future<bool> checkIsTopBidder(String itemId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final row = await _supabase
          .from('auctions')
          .select('last_bid_user_id')
          .eq('item_id', itemId)
          .eq('round', 1)
          .maybeSingle();

      if (row is! Map<String, dynamic>) return false;

      final String? lastBidUserId = getNullableStringFromRow(row, 'last_bid_user_id');
      return lastBidUserId != null && lastBidUserId == user.id;
    } catch (e) {
      return false;
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
    } catch (e) {
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
    } catch (e) {
      return SellerRatingSummary(rating: 0.0, reviewCount: 0);
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
          'user_name': '알 수 없음',
          'user_id': '',
          'created_at': getStringFromRow(logRow, 'created_at'),
          'profile_image_url': null,
          'auction_log_code': logRow['auction_log_code'],
        });
      }

      return bidHistory;
    } catch (e) {
      return [];
    }
  }

  Future<bool> checkIsMyItem(String itemId, String sellerId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return false;
      }
      return currentUser.id == sellerId;
    } catch (e) {
      return false;
    }
  }
}
