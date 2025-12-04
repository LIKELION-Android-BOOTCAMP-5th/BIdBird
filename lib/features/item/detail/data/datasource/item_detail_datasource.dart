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
        .from('items')
        .select()
        .eq('id', itemId)
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

    final List<String> images = await _fetchImages(itemId);

    final int biddingCount = await _fetchBiddingCount(itemId, row);

    final currentPrice = (row['current_price'] as int?) ?? 0;
    final minBidStep = ItemDetailPriceHelper.calculateBidStep(currentPrice);

    return ItemDetail(
      itemId: row['id']?.toString() ?? itemId,
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
      sellerRating: (row['seller_rating'] as num?)?.toDouble() ?? 0.0,
      sellerReviewCount: (row['seller_review_count'] as int?) ?? 0,
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
            .select('nickname, name')
            .eq('id', sellerId)
            .maybeSingle();

        if (userRow is Map<String, dynamic>) {
          sellerTitle = (userRow['nickname']?.toString() ?? '').isNotEmpty
              ? userRow['nickname'].toString()
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
          .count(CountOption.exact);
      return countResponse.count;
    } catch (e) {
      debugPrint('[ItemDetailDatasource] fetch bidding count error: $e');
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
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final List<dynamic> rows = await _supabase
          .from('bid_log')
          .select('bid_user, bid_price')
          .eq('item_id', itemId)
          .order('bid_price', ascending: false)
          .limit(1);

      if (rows.isNotEmpty) {
        final topBidUserId = rows[0]['bid_user']?.toString() ?? '';
        return topBidUserId == user.id;
      }
      return false;
    } catch (e) {
      debugPrint('[ItemDetailDatasource] check top bidder error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchSellerProfile(String sellerId) async {
    if (sellerId.isEmpty) return null;

    try {
      final userRow = await _supabase
          .from('users')
          .select('''
            id,
            name,
            nickname,
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
      final completedTrades = await _supabase
          .from('bid_status')
          .select('rating')
          .eq('user_id', sellerId)
          .eq('text_code', 'COMPLETED')
          .not('rating', 'is', null);

      return SellerRatingSummary.fromCompletedTrades(completedTrades);
    } catch (e) {
      debugPrint('[ItemDetailDatasource] fetch seller rating error: $e');
      return SellerRatingSummary(rating: 0.0, reviewCount: 0);
    }
  }

  Future<List<Map<String, dynamic>>> fetchBidHistory(String itemId) async {
    try {
      final List<dynamic> rows = await _supabase
          .from('bid_log')
          .select('''
            bid_price,
            bid_user,
            created_at
          ''')
          .eq('item_id', itemId)
          .order('created_at', ascending: false)
          .limit(10);

      List<Map<String, dynamic>> bidHistory = [];

      for (final row in rows) {
        final Map<String, dynamic> bidRow = row as Map<String, dynamic>;
        final userId = bidRow['bid_user']?.toString() ?? '';

        Map<String, dynamic>? userInfo;
        if (userId.isNotEmpty) {
          userInfo = await _fetchUserInfo(userId);
        }

        bidHistory.add({
          'price': ItemDetailPriceHelper
              .formatPrice(bidRow['bid_price'] as int? ?? 0),
          'user_name': userInfo?['nickname'] ?? userInfo?['name'] ?? '알 수 없음',
          'user_id': userId,
          'created_at': bidRow['created_at']?.toString() ?? '',
          'profile_image_url': userInfo?['profile_image_url'],
        });
      }

      return bidHistory;
    } catch (e) {
      debugPrint('[ItemDetailDatasource] fetch bid history error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _fetchUserInfo(String userId) async {
    try {
      final Map<String, dynamic>? userRow = await _supabase
          .from('users')
          .select('nickname, name, profile_image_url')
          .eq('id', userId)
          .maybeSingle();

      return userRow;
    } catch (e) {
      debugPrint('[ItemDetailDatasource] fetch user info error: $e');
      return null;
    }
  }

}
