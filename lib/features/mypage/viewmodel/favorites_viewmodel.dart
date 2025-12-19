import 'package:flutter/material.dart';

import '../domain/entities/favorite_entity.dart';
import '../domain/usecases/add_favorite.dart';
import '../domain/usecases/get_favorites.dart';
import '../domain/usecases/remove_favorite.dart';

class FavoritesViewModel extends ChangeNotifier {
  FavoritesViewModel({
    required GetFavorites getFavorites,
    required AddFavorite addFavorite,
    required RemoveFavorite removeFavorite,
  })  : _getFavorites = getFavorites,
        _addFavorite = addFavorite,
        _removeFavorite = removeFavorite;

  final GetFavorites _getFavorites;
  final AddFavorite _addFavorite;
  final RemoveFavorite _removeFavorite;

  List<FavoriteEntity> items = [];
  bool isLoading = false;
  String? errorMessage;
  final Set<String> _processingIds = {};

  Future<void> loadFavorites() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      items = await _getFavorites();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  //중복방지
  bool isProcessing(String itemId) => _processingIds.contains(itemId);

  Future<void> toggleFavorite(FavoriteEntity item) async {
    if (_processingIds.contains(item.itemId)) return;

    _processingIds.add(item.itemId);
    notifyListeners();

    try {
      if (item.isFavorite) {
        await _removeFavorite(item.itemId);
        _updateItem(item.copyWith(isFavorite: false));
      } else {
        await _addFavorite(item.itemId);
        _updateItem(item.copyWith(isFavorite: true));
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _processingIds.remove(item.itemId);
      notifyListeners();
    }
  }

  void _updateItem(FavoriteEntity updated) {
    final index = items.indexWhere((e) => e.itemId == updated.itemId);
    if (index >= 0) {
      items[index] = updated;
    } else {
      items.insert(0, updated); //최신목록
    }
  }
}
