import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/domain/repositories/item_detail_repository.dart'
    as domain;
import 'package:bidbird/features/item_detail/detail/domain/usecases/fetch_item_detail_usecase.dart';

class ItemDetailFlowResult {
  final ItemDetail item;
  final bool isFavorite;
  final bool isMyItem;
  final String? sellerProfileImage;
  final bool isTopBidder;
  const ItemDetailFlowResult({
    required this.item,
    required this.isFavorite,
    required this.isMyItem,
    required this.sellerProfileImage,
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
    required domain.ItemDetailRepository repository,
  }) : _fetchItemDetailUseCase = fetchItemDetailUseCase,
       _repository = repository;

  final FetchItemDetailUseCase _fetchItemDetailUseCase;
  final domain.ItemDetailRepository _repository;

  /// 초기 데이터 로드: 엣지 펑션에서 모든 정보 포함
  /// 최적화된 초기 로드: 엣지 펑션 호출 후 sellerId로 프로필 이미지 병렬 조회
  Future<(ItemDetailFlowResult?, ItemDetailFlowError?)> loadInitial(
    String itemId,
  ) async {
    try {
      // 단일 API 호출: 엣지 펑션에서 모든 정보 포함
      final item = await _fetchItemDetailUseCase(itemId);
      if (item == null) {
        return (null, const ItemDetailFlowError('상품을 찾을 수 없습니다.'));
      }

      // ⚠️ FetchItemDetailUseCase의 repository에서 캐시된 값을 가져와야 함!
      // _repository가 아니라 _fetchItemDetailUseCase._repository 사용
      final sellerProfileImage = _repository.getLastSellerProfileImage();
      final isFavoriteFromEdge = _repository.getLastIsFavorite() ?? false;
      final isTopBidderFromEdge = _repository.getLastIsTopBidder() ?? false;

      print(
        '🔍 FlowUseCase: sellerProfileImage from repo = $sellerProfileImage',
      );

      // 클라이언트 측에서 즉시 계산
      final currentUserId = _repository.supabase.auth.currentUser?.id;
      final isMyItem = currentUserId != null && item.sellerId == currentUserId;

      return (
        ItemDetailFlowResult(
          item: item,
          isFavorite: isFavoriteFromEdge,
          isMyItem: isMyItem,
          sellerProfileImage: sellerProfileImage,
          isTopBidder: isTopBidderFromEdge,
        ),
        null,
      );
    } catch (e) {
      return (null, ItemDetailFlowError(e.toString()));
    }
  }
}
