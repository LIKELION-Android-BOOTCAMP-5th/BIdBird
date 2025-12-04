import 'package:flutter/material.dart';

import '../data/repository/item_registration_repository.dart';
import '../model/item_registration_entity.dart';

class ItemRegistrationListViewModel extends ChangeNotifier {
  ItemRegistrationListViewModel({ItemRegistrationRepository? repository})
      : _repository = repository ?? ItemRegistrationRepository();

  final ItemRegistrationRepository _repository;

  bool isLoading = false;
  List<ItemRegistrationData> items = <ItemRegistrationData>[];

  Future<void> init() async {
    await fetchMyPendingItems();
  }

  Future<void> fetchMyPendingItems() async {
    isLoading = true;
    notifyListeners();

    try {
      items = await _repository.fetchMyPendingItems();
    } catch (e) {
      // TODO: 에러 로깅 또는 처리
      items = <ItemRegistrationData>[];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
