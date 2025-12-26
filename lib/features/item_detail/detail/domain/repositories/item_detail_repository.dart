import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Item Detail 도메인 리포지토리 인터페이스
abstract class ItemDetailRepository {
  Future<ItemDetail?> fetchItemDetail(String itemId);
  Future<bool> checkIsFavorite(String itemId);
  Future<void> toggleFavorite(String itemId, bool currentState);
  Future<Map<String, dynamic>?> fetchSellerProfile(String sellerId);
  Future<String?> fetchSellerProfileImage(String sellerId);
  Future<List<BidHistoryItem>> fetchBidHistory(String itemId);
  Future<bool> checkIsMyItem(String itemId, String sellerId);
  Future<bool> isCurrentUserTopBidder(String itemId);
  bool? getLastIsTopBidder();
  bool? getLastIsFavorite();
  String? getLastSellerProfileImage();
  SupabaseClient get supabase;
}
