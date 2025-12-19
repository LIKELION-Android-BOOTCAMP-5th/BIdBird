import '../entities/favorite_entity.dart';

abstract class FavoritesRepository {
  Future<List<FavoriteEntity>> fetchFavorites();
  Future<void> addFavorite(String itemId);
  Future<void> removeFavorite(String itemId);
}
