import '../repositories/favorites_repository.dart';

class RemoveFavorite {
  RemoveFavorite(this._repository);

  final FavoritesRepository _repository;

  Future<void> call(String itemId) {
    return _repository.removeFavorite(itemId);
  }
}
