import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/core/utils/item/item_security_utils.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/edit_item_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditItemDatasource {
  EditItemDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<EditItemEntity> fetchItemForEdit(String itemId) async {
    await ItemSecurityUtils.requireAuthAndVerifyOwnership(_supabase, itemId);

    try {
      final Map<String, dynamic> row = await _supabase
          .from('items_detail')
          .select(
            'title, description, start_price, buy_now_price, keyword_type, auction_duration_hours',
          )
          .eq('item_id', itemId)
          .single();

      final List<dynamic> imageRows = await _supabase
          .from('item_images')
          .select('image_url, sort_order')
          .eq('item_id', itemId)
          .order('sort_order');

      final List<String> imageUrls = imageRows
          .whereType<Map<String, dynamic>>()
          .map((e) => getStringFromRow(e, 'image_url'))
          .where((url) => url.isNotEmpty)
          .toList();

      final List<dynamic> docRows = await _supabase
          .from('item_documents')
          .select('document_url, document_name, file_size')
          .eq('item_id', itemId);

      final List<String> documentUrls = [];
      final List<String> documentNames = [];
      final List<int> documentSizes = [];

      for (var row in docRows) {
        final url = getStringFromRow(row, 'document_url');
        if (url.isNotEmpty) {
          documentUrls.add(url);
          documentNames.add(getStringFromRow(row, 'document_name'));
          documentSizes.add(getIntFromRow(row, 'file_size'));
        }
      }

      return EditItemEntity(
        title: getStringFromRow(row, 'title'),
        description: getStringFromRow(row, 'description'),
        startPrice: getIntFromRow(row, 'start_price'),
        keywordTypeId: getIntFromRow(row, 'keyword_type'),
        auctionDurationHours: getIntFromRow(row, 'auction_duration_hours', 4),
        imageUrls: imageUrls,
        documentUrls: documentUrls,
        documentNames: documentNames,
        documentSizes: documentSizes,
      );
    } catch (e) {
      if (e.toString().contains('PGRST116') || e.toString().contains('No rows')) {
        throw Exception('아이템을 찾을 수 없습니다. 아이템이 삭제되었거나 존재하지 않습니다.');
      }
      rethrow;
    }
  }
}



