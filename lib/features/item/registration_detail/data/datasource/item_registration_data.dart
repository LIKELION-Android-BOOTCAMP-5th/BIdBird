import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemRegistrationDatasource {
  ItemRegistrationDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<void> registerItem(String itemId, DateTime auctionStartAt) async {
    final user = _supabase.auth.currentUser;

    final DateTime normalizedAuctionStartAt = DateTime(
      auctionStartAt.year,
      auctionStartAt.month,
      auctionStartAt.day,
      auctionStartAt.hour,
      auctionStartAt.minute,
    );

    await _supabase
        .from('items')
        .update(<String, dynamic>{
          'is_agree': true,
          'auction_start_at': normalizedAuctionStartAt.toIso8601String(),
          'auction_stat': normalizedAuctionStartAt.toIso8601String(),
          'status_code': 1001,
        })
        .eq('id', itemId);

    if (user != null) {
      await _supabase.from('bid_status').insert(<String, dynamic>{
        'item_id': itemId,
        'user_id': user.id,
        'int_code': 1001,
        'text_code': '경매 대기',
      });
    }
  }
}