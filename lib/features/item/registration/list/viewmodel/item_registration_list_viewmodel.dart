import 'package:bidbird/features/item/registration/list/data/repository/item_registration_list_repository.dart';
import 'package:bidbird/features/item/registration/list/model/item_registration_entity.dart';
import 'package:flutter/material.dart';

class RegistrationViewModel extends ChangeNotifier {
  RegistrationViewModel({RegistrationRepository? repository})
      : _repository = repository ?? RegistrationRepository();

  final RegistrationRepository _repository;

  List<ItemRegistrationData> _items = <ItemRegistrationData>[];
  bool _isLoading = false;
  String? _error;

  List<ItemRegistrationData> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPendingItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _repository.fetchMyPendingItems();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

