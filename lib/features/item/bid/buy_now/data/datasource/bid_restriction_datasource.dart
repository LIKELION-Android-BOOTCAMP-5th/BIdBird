import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_registration_error_messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BidRestrictionDatasource {
  BidRestrictionDatasource({SupabaseClient? supabase})
      : _supabase = supabase ?? SupabaseManager.shared.supabase;

  final SupabaseClient _supabase;

  Future<bool> isBidRestricted() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception(ItemRegistrationErrorMessages.loginRequired);
    }

    final row = await _supabase
        .from('restriction_user')
        .select('fail_count')
        .eq('user_id', user.id)
        .maybeSingle();

    if (row == null) {
      return false;
    }

    final int failCount = (row['fail_count'] as num?)?.toInt() ?? 0;
    return failCount >= 3;
  }
}
