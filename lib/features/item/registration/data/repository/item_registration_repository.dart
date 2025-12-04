import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../datasource/item_registration_data.dart';

class ItemRegistrationRepository {
  ItemRegistrationRepository();

  final SupabaseClient _supabase = SupabaseManager.shared.supabase;

  Future<List<ItemRegistrationData>> fetchMyPendingItems() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return <ItemRegistrationData>[];
    }

    final List<dynamic> data = await _supabase
        .from('items')
        .select(
          'id, title, description, start_price, buy_now_price, thumbnail_image, keyword_type, status',
        )
        .eq('seller_id', user.id)
        .eq('is_agree', false);

    return data.map((dynamic row) {
      final map = row as Map<String, dynamic>;
      return ItemRegistrationData(
        id: map['id'].toString(),
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        startPrice: (map['start_price'] as num?)?.toInt() ?? 0,
        instantPrice: (map['buy_now_price'] as num?)?.toInt() ?? 0,
        thumbnailUrl: map['thumbnail_image'] as String?,
        keywordTypeId: (map['keyword_type'] as num?)?.toInt(),
      );
    }).toList();
  }

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
