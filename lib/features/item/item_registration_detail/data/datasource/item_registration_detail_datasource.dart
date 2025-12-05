import 'package:bidbird/core/managers/supabase_manager.dart';
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

  /// Edge Function 을 통해 실제 등록 시간을 10분 단위로 계산/등록한다.
  /// 반환값은 최종 등록 예정 시각.
  Future<DateTime> confirmRegistration(String itemId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('로그인 정보가 없습니다. 다시 로그인 해주세요.');
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
}

// TODO: implement ItemRegistrationDetailDatasource here
