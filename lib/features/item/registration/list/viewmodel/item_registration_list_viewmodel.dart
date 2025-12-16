import 'package:bidbird/core/viewmodels/item_base_viewmodel.dart';
import 'package:bidbird/features/item/registration/list/data/repository/item_registration_list_repository.dart';
import 'package:bidbird/features/item/registration/list/model/item_registration_entity.dart';

class RegistrationViewModel extends ItemBaseViewModel {
  RegistrationViewModel({RegistrationRepository? repository})
      : _repository = repository ?? RegistrationRepositoryImpl();

  final RegistrationRepository _repository;

  List<ItemRegistrationData> _items = <ItemRegistrationData>[];

  List<ItemRegistrationData> get items => _items;

  Future<void> loadPendingItems() async {
    startLoading();

    try {
      _items = await _repository.fetchMyPendingItems();
      notifyListeners();
    } catch (e) {
      stopLoadingWithError(e.toString());
    } finally {
      stopLoading();
    }
  }
}

