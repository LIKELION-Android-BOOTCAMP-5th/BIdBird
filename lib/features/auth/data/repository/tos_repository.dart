import 'package:bidbird/features/auth/model/tos_model.dart';

import '../../../../core/managers/supabase_manager.dart';
import '../data_sources/tos_datasource.dart';

class ToSRepository {
  Future<List<ToSModel>> getToSinfo() async {
    return await ToSDatasource.shared.getToSinfo();
  }

  Future<void> tosAgreed() async {
    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    await ToSDatasource.shared.updateTosAgreed(currentUserId);
  }
}
