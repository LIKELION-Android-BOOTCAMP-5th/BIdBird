import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/core/utils/item/item_security_utils.dart';
import 'package:bidbird/features/item/registration/list/model/item_registration_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationDatasource {
  RegistrationDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<List<ItemRegistrationData>> fetchMyPendingItems() async {
    final userId = ItemSecurityUtils.requireAuth(_supabase);

    try {
      final List<dynamic> rows = await _supabase
          .from('items_detail')
          .select(
        'item_id, title, description, start_price, buy_now_price, keyword_type, seller_id, thumbnail_image, is_agreed, created_at, auction_duration_hours',
      )
          .eq('seller_id', userId)
          .filter('is_agreed', 'is', null)
          .order('created_at', ascending: false);

      return rows
          .whereType<Map<String, dynamic>>()
          .map<ItemRegistrationData>((row) {

        return ItemRegistrationData(
          id: getStringFromRow(row, 'item_id'),
          title: getStringFromRow(row, 'title'),
          description: getStringFromRow(row, 'description'),
          startPrice: getIntFromRow(row, 'start_price'),
          instantPrice: getIntFromRow(row, 'buy_now_price'),
          auctionDurationHours: getIntFromRow(row, 'auction_duration_hours'),
          thumbnailUrl: getNullableStringFromRow(row, 'thumbnail_image'),
          keywordTypeId: getNullableIntFromRow(row, 'keyword_type'),
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }
}

