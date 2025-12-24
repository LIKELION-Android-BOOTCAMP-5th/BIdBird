import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item_detail/detail/data/datasources/item_detail_datasource.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/domain/repositories/item_detail_repository.dart'
    as domain;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Item Detail 리포지토리 구현체
class ItemDetailRepositoryImpl implements domain.ItemDetailRepository {
  ItemDetailRepositoryImpl({
    ItemDetailDatasource? datasource,
    SupabaseClient? supabase,
  }) : _datasource = datasource ?? ItemDetailDatasource(),
       _supabase = supabase ?? SupabaseManager.shared.supabase;

  final ItemDetailDatasource _datasource;
  final SupabaseClient _supabase;

  @override
  Future<ItemDetail?> fetchItemDetail(String itemId) {
    return _datasource.fetchItemDetail(itemId);
  }

  @override
  Future<bool> checkIsFavorite(String itemId) {
    return _datasource.checkIsFavorite(itemId);
  }

  @override
  Future<void> toggleFavorite(String itemId, bool currentState) {
    return _datasource.toggleFavorite(itemId, currentState);
  }

  @override
  Future<Map<String, dynamic>?> fetchSellerProfile(String sellerId) {
    return _datasource.fetchSellerProfile(sellerId);
  }

  @override
  Future<List<BidHistoryItem>> fetchBidHistory(String itemId) {
    return _datasource.fetchBidHistory(itemId);
  }

  @override
  Future<bool> checkIsMyItem(String itemId, String sellerId) {
    return _datasource.checkIsMyItem(itemId, sellerId);
  }

  @override
  Future<bool> isCurrentUserTopBidder(String itemId) {
    return _datasource.isCurrentUserTopBidder(itemId);
  }

  @override
  bool? getLastIsTopBidder() {
    return _datasource.getLastIsTopBidder();
  }

  @override
  bool? getLastIsFavorite() {
    return _datasource.getLastIsFavorite();
  }

  @override
  String? getLastSellerProfileImage() {
    return _datasource.getLastSellerProfileImage();
  }

  @override
  SupabaseClient get supabase => _supabase;
}
