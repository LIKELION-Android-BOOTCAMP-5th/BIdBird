import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/domain/repositories/item_detail_repository.dart'
    as domain;
import 'package:bidbird/features/item_detail/detail/domain/usecases/fetch_item_detail_usecase.dart';
import 'package:bidbird/features/item_detail/detail/domain/usecases/check_is_favorite_usecase.dart';
import 'package:bidbird/features/item_detail/detail/domain/usecases/fetch_seller_profile_usecase.dart';
import 'package:bidbird/features/item_detail/detail/domain/usecases/check_is_my_item_usecase.dart';

class ItemDetailFlowResult {
  final ItemDetail item;
  final bool isFavorite;
  final bool isMyItem;
  final Map<String, dynamic>? sellerProfile;
  final bool isTopBidder;
  const ItemDetailFlowResult({
    required this.item,
    required this.isFavorite,
    required this.isMyItem,
    required this.sellerProfile,
    required this.isTopBidder,
  });
}

class ItemDetailFlowError {
  final String message;
  const ItemDetailFlowError(this.message);
}

class ItemDetailFlowUseCase {
  ItemDetailFlowUseCase({
    required FetchItemDetailUseCase fetchItemDetailUseCase,
    required CheckIsFavoriteUseCase checkIsFavoriteUseCase,
    required FetchSellerProfileUseCase fetchSellerProfileUseCase,
    required CheckIsMyItemUseCase checkIsMyItemUseCase,
    required domain.ItemDetailRepository repository,
  }) : _fetchItemDetailUseCase = fetchItemDetailUseCase,
       _checkIsFavoriteUseCase = checkIsFavoriteUseCase,
       _fetchSellerProfileUseCase = fetchSellerProfileUseCase,
       _checkIsMyItemUseCase = checkIsMyItemUseCase,
       _repository = repository;

  final FetchItemDetailUseCase _fetchItemDetailUseCase;
  final CheckIsFavoriteUseCase _checkIsFavoriteUseCase;
  final FetchSellerProfileUseCase _fetchSellerProfileUseCase;
  final CheckIsMyItemUseCase _checkIsMyItemUseCase;
  final domain.ItemDetailRepository _repository;

  /// 초기 데이터 로드 오케스트레이션
  Future<(ItemDetailFlowResult?, ItemDetailFlowError?)> loadInitial(
    String itemId,
  ) async {
    try {
      final item = await _fetchItemDetailUseCase(itemId);
      if (item == null) {
        return (null, const ItemDetailFlowError('상품을 찾을 수 없습니다.'));
      }

      final isFavorite = await _checkIsFavoriteUseCase(itemId);
      final isMyItem = await _checkIsMyItemUseCase(itemId, item.sellerId);
      final sellerProfile = await _fetchSellerProfileUseCase(item.sellerId);
      final isTopBidderFromEdge = _repository.getLastIsTopBidder();
      final isTopBidder = isTopBidderFromEdge ?? false;

      return (
        ItemDetailFlowResult(
          item: item,
          isFavorite: isFavorite,
          isMyItem: isMyItem,
          sellerProfile: sellerProfile,
          isTopBidder: isTopBidder,
        ),
        null,
      );
    } catch (e) {
      return (null, ItemDetailFlowError(e.toString()));
    }
  }
}
