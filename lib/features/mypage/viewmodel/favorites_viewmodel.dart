import 'package:flutter/material.dart';

import '../data/favorites_repository.dart';
import '../model/favorites_model.dart';

class FavoritesViewModel extends ChangeNotifier {
  FavoritesViewModel({required this.repository});

  final FavoritesRepository repository;

  List<FavoritesItem> items = [];
  bool isLoading = false;
  String? errorMessage;
  final Set<String> _processingIds = {};

  Future<void> loadFavorites() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      items = await repository.fetchFavorites();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  //중복방지
  bool isProcessing(String itemId) => _processingIds.contains(itemId);

  Future<void> toggleFavorite(FavoritesItem item) async {
    if (_processingIds.contains(item.itemId)) return;

    _processingIds.add(item.itemId);
    notifyListeners();

    try {
      if (item.isFavorite) {
        await repository.removeFavorite(item.itemId);
        _updateItem(item.copyWith(isFavorite: false));
      } else {
        await repository.addFavorite(item.itemId);
        _updateItem(item.copyWith(isFavorite: true));
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _processingIds.remove(item.itemId);
      notifyListeners();
    }
  }

  void _updateItem(FavoritesItem updated) {
    final index = items.indexWhere((e) => e.itemId == updated.itemId);
    if (index >= 0) {
      items[index] = updated;
    } else {
      items.insert(0, updated); //최신목록
    }
  }
}
