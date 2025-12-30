import 'package:bidbird/core/widgets/unified_empty_state.dart';
import 'package:bidbird/core/utils/extension/money_extension.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';

import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:bidbird/features/mypage/domain/entities/favorite_entity.dart';
import 'package:bidbird/features/mypage/viewmodel/favorites_viewmodel.dart';
import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context
        .watch<
          FavoritesViewModel
        >(); //거래내역과비슷한현상//이건처음엔뜨는데//하트활성화비활성화가안보임//read를watch로바꾸니까됨
    final isLoading = context.select<FavoritesViewModel, bool>(
      (vm) => vm.isLoading,
    );
    final items = context.select<FavoritesViewModel, List>((vm) => vm.items);

    Widget body;
    if (isLoading) {
      body = const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (items.isEmpty) {
      body = UnifiedEmptyState(
        title: '관심 등록한 상품이 없습니다.',
        subtitle: '마음에 드는 상품에 하트를 눌러보세요!',
        onRefresh: vm.loadFavorites,
      );
    } else {
      body = TransparentRefreshIndicator(
        onRefresh: vm.loadFavorites,
        child: ListView.separated(
          itemBuilder: (context, index) {
            final item = items[index];
            final bool isProcessing = vm.isProcessing(item.itemId);
            return _Item(
              item: item,
              isProcessing: isProcessing,
              onPressed: () => vm.toggleFavorite(item),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: items.length,
        ),
      );
    }

    return Scaffold(
      backgroundColor: BackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('관심목록'),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(16), child: body),
      ),
    );
  }
}

class FavoriteStatusInfo {
  const FavoriteStatusInfo(this.label, this.color);
  final String label;
  final Color color;
}

//이부분은repository로빼는게맞겠네
//auctions테이블의auction_status_code
//관심물품은300번대만보여줘도될거같음
//관심물품은기본적으로구매자사이드//300번은필요없음
FavoriteStatusInfo statusInfoText(int code) {
  if (code >= 500) {
    // 거래(500번대) 상태는 모두 경매 종료로 취급
    return const FavoriteStatusInfo('경매종료', tradePurchaseDoneColor);
  }

  switch (code) {
    case 310:
      return const FavoriteStatusInfo(
        '경매진행중',
        tradeSaleDoneColor,
      ); //경매진행//"경매 진행 중"
    case 311:
      return const FavoriteStatusInfo(
        '즉시구매중',
        tradeSaleDoneColor,
      ); //경매진행//??//즉시 구매 결제 전
    case 321:
      return const FavoriteStatusInfo(
        '낙찰종료',
        tradePurchaseDoneColor,
      ); //경매종료//"낙찰"인데내가이긴게아닐수있으니"종료(낙찰)"로표시하자
    case 322:
      return const FavoriteStatusInfo(
        '즉시구매종료',
        tradePurchaseDoneColor,
      ); //경매종료//"즉시 구매 완료"인데내가이긴게아닐수있으니"종료(즉시 구매)"로표시하자
    case 323:
      return const FavoriteStatusInfo('유찰', RedColor); //경매종료
    default:
      return FavoriteStatusInfo('$code', tradeBlockedColor); //아이템이삭제되면이리오려나
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.item,
    required this.onPressed,
    required this.isProcessing,
  });

  final FavoriteEntity item;
  final VoidCallback onPressed;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final statusInfo = statusInfoText(item.statusCode);
    final hasImage = item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (item.itemId.isNotEmpty) {
          context.push('/item/${item.itemId}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white, //앱칼라가없어서그냥이렇게씀,
          borderRadius: defaultBorder,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: defaultBorder,
              child: Container(
                width: 80,
                height: 80,
                color: ImageBackgroundColor,
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: item.thumbnailUrl!,
                        cacheManager: ItemImageCacheManager.instance,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.image_outlined, color: iconColor),
                      )
                    : const Icon(Icons.image_outlined, color: iconColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusInfo.color.withValues(alpha: 0.1),
                          borderRadius: defaultBorder,
                        ),
                        child: Text(
                          statusInfo.label,
                          style: TextStyle(color: statusInfo.color),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (item.currentPrice > 0)
                    Text(
                      '최고입찰가 ${item.currentPrice.toCommaString()}원',
                      style: TextStyle(fontSize: 14, color: textColor),
                    )
                  else //else if (item.currentPrice <= 0)
                    const SizedBox(height: 14),

                  const SizedBox(height: 4),
                  if (item.buyNowPrice != null && item.buyNowPrice! > 0)
                    Text(
                      '즉시구매가 ${item.buyNowPrice!.toCommaString()}원',
                      style: TextStyle(fontSize: 14, color: BorderColor),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 80, //섬네일높이
              child: Center(
                child: IconButton(
                  onPressed: isProcessing ? null : onPressed,
                  icon: isProcessing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          item.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: item.isFavorite ? RedColor : iconColor,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
