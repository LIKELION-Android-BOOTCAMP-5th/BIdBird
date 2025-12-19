import '../../domain/entities/favorite_entity.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_remote_data_source.dart';
import '../models/favorite_dto.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl({FavoritesRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? FavoritesRemoteDataSource();

  final FavoritesRemoteDataSource _remoteDataSource;

  @override
  Future<List<FavoriteEntity>> fetchFavorites() async {
    final rows = await _remoteDataSource.fetchFavoritesRows();

    if (rows.isEmpty) return [];

    final List<String> itemIds = [];
    final Map<String, Map<String, dynamic>> favoritesById = {};
    for (final Map<String, dynamic> row in rows) {
      final itemId = row['item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;
      itemIds.add(itemId);
      favoritesById[itemId] = row;
    }

    if (itemIds.isEmpty) return [];

    final itemsById = await _fetchItemsDetail(itemIds);
    final auctionsByItemId = await _fetchAuctions(itemIds);

    return itemIds
        .map(
          (itemId) => _mapFavorites(
            itemId: itemId,
            favoriteRow: favoritesById[itemId],
            itemRow: itemsById[itemId],
            auctionRow: auctionsByItemId[itemId],
          ),
        )
        .whereType<FavoriteDto>()
        .map((dto) => dto.toEntity())
        .toList();
  }

  Future<Map<String, Map<String, dynamic>>> _fetchItemsDetail(
    List<String> itemIds,
  ) async {
    final rows = await _remoteDataSource.fetchItemsDetail(itemIds);

    final Map<String, Map<String, dynamic>> map = {};
    for (final dynamic row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final itemId = row['item_id']?.toString();
      if (itemId != null) {
        map[itemId] = row;
      }
    }
    return map;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchAuctions(
    List<String> itemIds,
  ) async {
    final rows = await _remoteDataSource.fetchAuctions(itemIds);

    final Map<String, Map<String, dynamic>> map = {};
    for (final dynamic row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final itemId = row['item_id']?.toString();
      if (itemId != null) {
        map[itemId] = row;
      }
    }
    return map;
  }

  FavoriteDto? _mapFavorites({
    required String itemId,
    Map<String, dynamic>? favoriteRow,
    Map<String, dynamic>? itemRow,
    Map<String, dynamic>? auctionRow,
  }) {
    if (favoriteRow == null) return null;

    final favoriteId = favoriteRow['id']?.toString() ?? '';
    final String title = itemRow?['title']?.toString() ?? '';
    final String? thumbnail = itemRow?['thumbnail_image']?.toString();
    final int currentPrice =
        (auctionRow?['current_price'] as num?)?.toInt() ?? 0;
    final int? buyNowPrice = (itemRow?['buy_now_price'] as num?)?.toInt();
    final int statusCode =
        (auctionRow?['auction_status_code'] as int?) ?? 0;

    return FavoriteDto(
      favoriteId: favoriteId,
      itemId: itemId,
      title: title,
      thumbnailUrl: thumbnail,
      currentPrice: currentPrice,
      buyNowPrice: buyNowPrice,
      statusCode: statusCode,
      isFavorite: true,
    );
  }

  @override
  Future<void> removeFavorite(String itemId) {
    return _remoteDataSource.removeFavorite(itemId);
  }

  @override
  Future<void> addFavorite(String itemId) {
    return _remoteDataSource.addFavorite(itemId);
  }
}
