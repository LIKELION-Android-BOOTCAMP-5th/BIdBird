import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../datasource/item_detail_datasource.dart';

abstract class ItemDetailRepository {
  Future<ItemDetail?> fetchItemDetail(String itemId);
  Future<bool> checkIsFavorite(String itemId);
  Future<void> toggleFavorite(String itemId, bool currentState);
  Future<Map<String, dynamic>?> fetchSellerProfile(String sellerId);
  Future<List<Map<String, dynamic>>> fetchBidHistory(String itemId);
  Future<bool> checkIsMyItem(String itemId, String sellerId);
  bool? getLastIsTopBidder();
  SupabaseClient get supabase;
}

class ItemDetailRepositoryImpl implements ItemDetailRepository {
  ItemDetailRepositoryImpl({
    ItemDetailDatasource? datasource,
    SupabaseClient? supabase,
  })  : _datasource = datasource ?? ItemDetailDatasource(),
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
  Future<List<Map<String, dynamic>>> fetchBidHistory(String itemId) {
    return _datasource.fetchBidHistory(itemId);
  }

  @override
  Future<bool> checkIsMyItem(String itemId, String sellerId) {
    return _datasource.checkIsMyItem(itemId, sellerId);
  }

  @override
  bool? getLastIsTopBidder() {
    return _datasource.getLastIsTopBidder();
  }

  @override
  SupabaseClient get supabase => _supabase;
}
