import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';
import 'package:bidbird/features/item_enroll/registration/list/domain/repositories/item_registration_list_repository.dart';

/// 내 대기 중인 상품 목록 조회 유즈케이스
class FetchMyPendingItemsUseCase {
  FetchMyPendingItemsUseCase(this._repository);

  final ItemRegistrationListRepository _repository;

  Future<List<ItemRegistrationData>> call() {
    return _repository.fetchMyPendingItems();
  }
}

