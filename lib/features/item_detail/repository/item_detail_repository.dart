import 'package:flutter/material.dart';
import 'package:bidbird/core/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/item_detail_data.dart';

class ItemDetailRepository {
  final SupabaseClient _supabase = SupabaseManager.shared.supabase;

  Future<ItemDetail?> fetchItemDetail(String itemId) async {
    final List<dynamic> result = await _supabase
        .from('items')
        .select()
        .eq('id', itemId)
        .limit(1);

    if (result.isEmpty) return null;

    final Map<String, dynamic> row = result.first as Map<String, dynamic>;

    // 종료 시각 계산
    final createdAtRaw = row['created_at']?.toString();
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
        : DateTime.now();
    final durationHours = (row['auction_duration_hours'] as int?) ?? 24;
    final finishTime = createdAt.add(Duration(hours: durationHours));

    // 판매자 정보
    final String sellerId = row['seller_id']?.toString() ?? '';
    String sellerTitle = await _fetchSellerName(sellerId, row);

    // 이미지 로딩
    final List<String> images = await _fetchImages(itemId);

    // 입찰 수 조회
    final int biddingCount = await _fetchBiddingCount(itemId, row);

    final currentPrice = (row['current_price'] as int?) ?? 0;
    final minBidStep = _calculateBidStep(currentPrice);

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

  Future<String> _fetchSellerName(String sellerId, Map<String, dynamic> row) async {
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
        debugPrint('[ItemDetailRepository] fetch seller name error: $e');
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

      if (imageRows is List) {
        for (final raw in imageRows) {
          final imgRow = raw as Map<String, dynamic>;
          final imageUrl = imgRow['image_url']?.toString();
          if (imageUrl != null && imageUrl.isNotEmpty) {
            images.add(imageUrl);
          }
        }
      }
    } catch (e) {
      debugPrint('[ItemDetailRepository] fetch images error: $e');
    }

    return images;
  }

  Future<int> _fetchBiddingCount(String itemId, Map<String, dynamic> row) async {
    try {
      final countResponse = await _supabase
          .from('bid_log')
          .select('id')
          .eq('item_id', itemId)
          .count(CountOption.exact);
      return countResponse.count;
    } catch (e) {
      debugPrint('[ItemDetailRepository] fetch bidding count error: $e');
      return (row['bidding_count'] as int?) ?? 0;
    }
  }

  int _calculateBidStep(int currentPrice) {
    if (currentPrice <= 100000) {
      return 1000;
    } else {
      final priceStr = currentPrice.toString();
      if (priceStr.length >= 3) {
        return int.parse(priceStr.substring(0, priceStr.length - 2));
      } else {
        return 1000;
      }
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
      debugPrint('[ItemDetailRepository] check favorite error: $e');
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
      debugPrint('[ItemDetailRepository] check top bidder error: $e');
      return false;
    }
  }
}
