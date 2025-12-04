import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/registration/model/item_registration_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemRegistrationDatasource {
  ItemRegistrationDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

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
}