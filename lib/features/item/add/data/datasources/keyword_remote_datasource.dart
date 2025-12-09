import 'package:bidbird/core/managers/supabase_manager.dart';
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
        .cast<Map<String, dynamic>>()
        .map(
          (e) => KeywordTypeEntity(
            id: (e['id'] as num).toInt(),
            title: (e['title'] ?? '').toString(),
          ),
        )
        .toList();
  }
}
