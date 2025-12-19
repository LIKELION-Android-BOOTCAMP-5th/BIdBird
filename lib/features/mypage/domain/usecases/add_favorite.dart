import '../repositories/favorites_repository.dart';

class AddFavorite {
  AddFavorite(this._repository);

  final FavoritesRepository _repository;

  Future<void> call(String itemId) {
    return _repository.addFavorite(itemId);
  }
}
