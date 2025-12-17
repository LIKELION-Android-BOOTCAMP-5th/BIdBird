import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/current_trade/model/current_trade_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CurrentTradeDatasource {
  CurrentTradeDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<List<BidHistoryItem>> fetchMyBidHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase.functions.invoke(
        'get-my-current-bid',
      );

      if (response.data == null) {
        return [];
      }

      final responseData = response.data as Map<String, dynamic>;
      
      if (responseData['success'] == true && responseData['data'] != null) {
        final List<dynamic> bidHistoryList = responseData['data'] as List<dynamic>;
        return bidHistoryList
            .map((item) {
              final map = item as Map<String, dynamic>;
              return BidHistoryItem(
                itemId: map['itemId']?.toString() ?? '',
                title: map['title']?.toString() ?? '',
                price: (map['price'] as num?)?.toInt() ?? 0,
                thumbnailUrl: map['thumbnailUrl']?.toString(),
                status: map['status']?.toString() ?? '',
                tradeStatusCode: map['tradeStatusCode'] as int?,
                auctionStatusCode: map['auctionStatusCode'] as int?,
                hasShippingInfo: map['hasShippingInfo'] as bool? ?? false,
              );
            })
            .toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SaleHistoryItem>> fetchMySaleHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase.functions.invoke(
        'get-my-current-sale',
      );

      if (response.data == null) {
        return [];
      }

      final responseData = response.data as Map<String, dynamic>;
      
      if (responseData['success'] == true && responseData['data'] != null) {
        final List<dynamic> saleHistoryList = responseData['data'] as List<dynamic>;
        return saleHistoryList
            .map((item) {
              final map = item as Map<String, dynamic>;
              return SaleHistoryItem(
                itemId: map['itemId']?.toString() ?? '',
                title: map['title']?.toString() ?? '',
                price: (map['price'] as num?)?.toInt() ?? 0,
                thumbnailUrl: map['thumbnailUrl']?.toString(),
                status: map['status']?.toString() ?? '',
                date: map['date']?.toString() ?? '',
                tradeStatusCode: map['tradeStatusCode'] as int?,
                auctionStatusCode: map['auctionStatusCode'] as int?,
                hasShippingInfo: map['hasShippingInfo'] as bool? ?? false,
              );
            })
            .toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }
}