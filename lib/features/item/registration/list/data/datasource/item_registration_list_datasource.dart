import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_registration_error_messages.dart';
import 'package:bidbird/features/item/registration/list/model/item_registration_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationDatasource {
  RegistrationDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<List<ItemRegistrationData>> fetchMyPendingItems() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception(ItemRegistrationErrorMessages.loginRequired);
    }

    try {
      final List<dynamic> rows = await _supabase
          .from('items_detail')
          .select(
        'item_id, title, description, start_price, buy_now_price, keyword_type, seller_id, thumbnail_image, is_agreed, created_at, auction_duration_hours',
      )
          .eq('seller_id', user.id)
          .filter('is_agreed', 'is', null)
          .order('created_at', ascending: false);

      return rows.map<ItemRegistrationData>((dynamic raw) {
        final Map<String, dynamic> row = raw as Map<String, dynamic>;

        return ItemRegistrationData(
          id: row['item_id']?.toString() ?? '',
          title: row['title']?.toString() ?? '',
          description: row['description']?.toString() ?? '',
          startPrice: (row['start_price'] as num?)?.toInt() ?? 0,
          instantPrice: (row['buy_now_price'] as num?)?.toInt() ?? 0,
          auctionDurationHours:
              (row['auction_duration_hours'] as num?)?.toInt() ?? 0,
          thumbnailUrl: row['thumbnail_image']?.toString(),
          keywordTypeId: (row['keyword_type'] as num?)?.toInt(),
        );
      }).toList();
    } on PostgrestException catch (e) {
      debugPrint('[RegistrationDatasource] PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[RegistrationDatasource] fetchMyPendingItems error: $e');
      rethrow;
    }
  }
}

