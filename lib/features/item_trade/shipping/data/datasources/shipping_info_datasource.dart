import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShippingInfoDatasource {
  ShippingInfoDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  /// 송장 정보 저장
  Future<void> saveShippingInfo({
    required String itemId,
    required String carrier,
    required String trackingNumber,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    await _supabase.from('shipping_info').insert({
      'item_id': itemId,
      'carrier': carrier,
      'tracking_number': trackingNumber,
    });
  }

  /// 송장 정보 조회 (item_id로)
  Future<Map<String, dynamic>?> getShippingInfo(String itemId) async {
    final response = await _supabase
        .from('shipping_info')
        .select()
        .eq('item_id', itemId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return response as Map<String, dynamic>?;
  }

  /// 송장 정보 수정
  Future<void> updateShippingInfo({
    required String itemId,
    required String carrier,
    required String trackingNumber,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    await _supabase
        .from('shipping_info')
        .update({
          'carrier': carrier,
          'tracking_number': trackingNumber,
        })
        .eq('item_id', itemId);
  }
}

