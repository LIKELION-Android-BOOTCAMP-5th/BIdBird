import 'package:bidbird/core/viewmodels/item_base_viewmodel.dart';
import '../../domain/entities/item_registration_entity.dart';
import '../../domain/usecases/fetch_my_pending_items_usecase.dart';
import '../../data/repositories/item_registration_list_repository.dart';

class ItemRegistrationListViewModel extends ItemBaseViewModel {
  ItemRegistrationListViewModel({FetchMyPendingItemsUseCase? fetchMyPendingItemsUseCase})
      : _fetchMyPendingItemsUseCase =
            fetchMyPendingItemsUseCase ?? FetchMyPendingItemsUseCase(ItemRegistrationListRepositoryImpl());

  final FetchMyPendingItemsUseCase _fetchMyPendingItemsUseCase;

  List<ItemRegistrationData> _items = <ItemRegistrationData>[];

  List<ItemRegistrationData> get items => _items;

  Future<void> loadPendingItems() async {
    startLoading();

    try {
      _items = await _fetchMyPendingItemsUseCase();
      notifyListeners();
    } catch (e) {
      stopLoadingWithError(e.toString());
    } finally {
      stopLoading();
    }
  }
}



