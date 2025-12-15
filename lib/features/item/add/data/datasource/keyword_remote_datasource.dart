import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_data_conversion_utils.dart';
import 'package:bidbird/features/item/add/model/keyword_type_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KeywordRemoteDataSource {
  KeywordRemoteDataSource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<List<KeywordTypeEntity>> fetchKeywordTypes() async {
    final List<dynamic> data = await _supabase
        .from('code_keyword_type')
        .select('id, title')
        .order('id');

    return data
        .whereType<Map<String, dynamic>>()
        .map(
          (e) => KeywordTypeEntity(
            id: getIntFromRow(e, 'id'),
            title: getStringFromRow(e, 'title'),
          ),
        )
        .toList();
  }
}
