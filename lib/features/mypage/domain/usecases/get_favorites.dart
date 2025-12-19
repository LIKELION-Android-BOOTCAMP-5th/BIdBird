import '../entities/favorite_entity.dart';
import '../repositories/favorites_repository.dart';

class GetFavorites {
  GetFavorites(this._repository);

  final FavoritesRepository _repository;

  Future<List<FavoriteEntity>> call() {
    return _repository.fetchFavorites();
  }
}
