import '../../../../core/managers/supabase_manager.dart';
import '../../domain/entities/tos_entity.dart';
import '../../domain/repositories/tos_repository.dart' as domain;
import '../datasources/tos_datasource.dart';

/// ToS 리포지토리 구현체
class ToSRepositoryImpl implements domain.ToSRepository {
  @override
  Future<List<ToSEntity>> getToSinfo() async {
    return await ToSDatasource.shared.getToSinfo();
  }

  @override
  Future<void> tosAgreed() async {
    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      throw Exception('User not logged in');
    }

    await ToSDatasource.shared.updateTosAgreed(currentUserId);
  }
}


