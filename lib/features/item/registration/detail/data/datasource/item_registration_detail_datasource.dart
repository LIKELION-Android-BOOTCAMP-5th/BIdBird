import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_registration_error_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemRegistrationDetailDatasource {
  ItemRegistrationDetailDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<String> fetchTermsText() async {
    try {
      final Map<String, dynamic> row = await _supabase
          .from('terms')
          .select('terms')
          .eq('id', 1)
          .single();

      return (row['terms'] ?? '').toString();
    } on PostgrestException catch (e) {
      debugPrint('[ItemRegistrationDetailDatasource] fetchTermsText PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ItemRegistrationDetailDatasource] fetchTermsText error: $e');
      rethrow;
    }
  }

  Future<DateTime> confirmRegistration(String itemId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception(ItemRegistrationErrorMessages.loginRequired);
      }

      final response = await _supabase.functions.invoke(
        'schedule-item-registration',
        body: <String, dynamic>{
          'itemId': itemId,
          'userId': user.id,
        },
      );

      final dynamic data = response.data;
      if (data is Map<String, dynamic> && data['scheduled_at'] != null) {
        return DateTime.parse(data['scheduled_at'].toString()).toLocal();
      }

      throw Exception('잘못된 Edge Function 응답입니다: ${response.data}');
    } on PostgrestException catch (e) {
      debugPrint('[ItemRegistrationDetailDatasource] PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ItemRegistrationDetailDatasource] confirmRegistration error: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _supabase.from('item_images').delete().eq('item_id', itemId);
      await _supabase.from('items_detail').delete().eq('item_id', itemId);
    } on PostgrestException catch (e) {
      debugPrint('[ItemRegistrationDetailDatasource] deleteItem PostgrestException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ItemRegistrationDetailDatasource] deleteItem error: $e');
      rethrow;
    }
  }
}
