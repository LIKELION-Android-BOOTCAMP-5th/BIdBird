import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
import 'package:flutter/material.dart';
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

    final Map<String, dynamic> row = result.first as Map<String, dynamic>;

    final createdAtRaw = row['created_at']?.toString();
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
        : DateTime.now();
    final durationHours = (row['auction_duration_hours'] as int?) ?? 24;
    final finishTime = createdAt.add(Duration(hours: durationHours));

    final String sellerId = row['seller_id']?.toString() ?? '';
    String sellerTitle = await _fetchSellerName(sellerId, row);

    // 판매자 별점/리뷰 수 계산 (bid_status 기반)
    SellerRatingSummary? ratingSummary;
    if (sellerId.isNotEmpty) {
      ratingSummary = await _fetchSellerRating(sellerId);
    }

    final List<String> images = await _fetchImages(itemId);

    final int biddingCount = await _fetchBiddingCount(itemId, row);

    final currentPrice = (row['current_price'] as int?) ?? 0;
    final minBidStep = ItemDetailPriceHelper.calculateBidStep(currentPrice);

    return ItemDetail(
      itemId: row['item_id']?.toString() ?? itemId,
      sellerId: sellerId,
      itemTitle: row['title']?.toString() ?? '',
      itemImages: images,
      finishTime: finishTime,
      sellerTitle: sellerTitle,
      buyNowPrice: (row['buy_now_price'] as int?) ?? 0,
      biddingCount: biddingCount,
      itemContent: row['description']?.toString() ?? '',
      currentPrice: currentPrice,
      bidPrice: minBidStep,
      sellerRating: ratingSummary?.rating ??
          (row['seller_rating'] as num?)?.toDouble() ?? 0.0,
      sellerReviewCount: ratingSummary?.reviewCount ??
          (row['seller_review_count'] as int?) ?? 0,
      statusCode: (row['status_code'] as int?) ?? 0,
    );
  }

  Future<String> _fetchSellerName(
    String sellerId,
    Map<String, dynamic> row,
  ) async {
    String sellerTitle = row['seller_name']?.toString() ?? '';

    if (sellerTitle.isEmpty && sellerId.isNotEmpty) {
      try {
        final userRow = await _supabase
            .from('users')
            .select('nick_name, name')
            .eq('id', sellerId)
            .maybeSingle();

        if (userRow is Map<String, dynamic>) {
          final rawNick = userRow['nick_name']?.toString() ?? '';
          sellerTitle = rawNick.isNotEmpty
              ? rawNick
              : (userRow['name']?.toString() ?? '');
        }
      } catch (e) {
        debugPrint('[ItemDetailDatasource] fetch seller name error: $e');
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
        final imageUrl = imgRow['image_url']?.toString();
        if (imageUrl != null && imageUrl.isNotEmpty) {
          images.add(imageUrl);
        }
      }
    } catch (e) {
      debugPrint('[ItemDetailDatasource] fetch images error: $e');
    }

    return images;
  }

  Future<int> _fetchBiddingCount(
    String itemId,
    Map<String, dynamic> row,
  ) async {
    try {
      final countResponse = await _supabase
          .from('bid_log')
          .select('id')
          .eq('item_id', itemId)
          .isFilter('instant_buy_triggered_at', null)
          .neq('bid_price', 0)
          .count(CountOption.exact);
      return countResponse.count;
    } catch (e) {
      return (row['bidding_count'] as int?) ?? 0;
    }
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
      debugPrint('[ItemDetailDatasource] check favorite error: $e');
      return false;
    }
  }

  Future<void> toggleFavorite(String itemId, bool currentState) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

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
    // TODO: 서버 스키마 확정 후 bid_log의 사용자 컬럼명에 맞춰 재구현
    return false;
  }

  Future<Map<String, dynamic>?> fetchSellerProfile(String sellerId) async {
    if (sellerId.isEmpty) return null;

    try {
      final userRow = await _supabase
          .from('users')
          .select('''
            id,
            name,
            nick_name,
            profile_image_url,
            email,
            created_at
          ''')
          .eq('id', sellerId)
          .maybeSingle();

      if (userRow is Map<String, dynamic>) {
        final ratingSummary = await _fetchSellerRating(sellerId);

        return {
          ...userRow,
          'rating': ratingSummary.rating,
          'review_count': ratingSummary.reviewCount,
        };
      }
      return null;
    } catch (e) {
      debugPrint('[ItemDetailDatasource] fetch seller profile error: $e');
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
      debugPrint('[ItemDetailDatasource] fetch seller rating error: $e');
      return SellerRatingSummary(rating: 0.0, reviewCount: 0);
    }
  }

  Future<List<Map<String, dynamic>>> fetchBidHistory(String itemId) async {
    try {
      final List<dynamic> rows = await _supabase
          .from('bid_log')
          .select('bid_price, created_at')
          .eq('item_id', itemId)
          .order('created_at', ascending: false)
          .limit(10);

      List<Map<String, dynamic>> bidHistory = [];

      for (final row in rows) {
        final Map<String, dynamic> bidRow = row as Map<String, dynamic>;

        final dynamic rawPrice = bidRow['bid_price'];
        final int price;
        if (rawPrice is num) {
          price = rawPrice.toInt();
        } else {
          price = int.tryParse(rawPrice?.toString() ?? '') ?? 0;
        }

        bidHistory.add({
          'price': price,
          'user_name': '알 수 없음',
          'user_id': '',
          'created_at': bidRow['created_at']?.toString() ?? '',
          'profile_image_url': null,
        });
      }

      return bidHistory;
    } catch (e) {
      return [];
    }
  }
}
