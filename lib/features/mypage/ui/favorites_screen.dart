import 'package:bidbird/core/utils/extension/money_extension.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:bidbird/features/mypage/model/favorites_model.dart';
import 'package:bidbird/features/mypage/viewmodel/favorites_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class FavoriteStatusInfo {
  const FavoriteStatusInfo(this.label, this.color);
  final String label;
  final Color color;
}

FavoriteStatusInfo statusInfoText(int code) {
  switch (code) {
    case 321:
      return const FavoriteStatusInfo('낙찰', tradeSaleDoneColor);
    case 322:
      return const FavoriteStatusInfo('즉시 구매 완료', tradeSaleDoneColor);
    case 323:
      return const FavoriteStatusInfo('유찰', RedColor);
    case 430:
      return const FavoriteStatusInfo('입찰 낙찰', tradePurchaseDoneColor);
    case 431:
      return const FavoriteStatusInfo('즉시 구매 낙찰', tradePurchaseDoneColor);
    case 520:
      return const FavoriteStatusInfo('결제 완료', tradePurchaseDoneColor);
    case 550:
      return const FavoriteStatusInfo('거래 완료', tradeSaleDoneColor);
    default: //db코드나중에확인하기
      return const FavoriteStatusInfo(
        '진행중',
        blueColor,
      ); //아이템이삭제됐을때도진행중이라고뜨는문제가있음
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoritesViewModel>();

    return Scaffold(
      backgroundColor: BackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('관심 목록'),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _FavoritesBody(vm: vm),
        ),
      ),
    );
  }
}

class _FavoritesBody extends StatelessWidget {
  const _FavoritesBody({required this.vm});

  final FavoritesViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading) {
      return const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (vm.items.isEmpty) {
      return const Center(child: Text('관심 등록한 상품이 없습니다.'));
    }

    return RefreshIndicator(
      onRefresh: vm.loadFavorites,
      child: ListView.separated(
        itemBuilder: (context, index) {
          final item = vm.items[index];
          final bool isProcessing = vm.isProcessing(item.itemId);
          return _Item(
            item: item,
            isProcessing: isProcessing,
            onPressed: () => vm.toggleFavorite(item),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemCount: vm.items.length,
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.item,
    required this.onPressed,
    required this.isProcessing,
  });

  final FavoritesItem item;
  final VoidCallback onPressed;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final statusInfo = statusInfoText(item.statusCode);

    return GestureDetector(
      onTap: () {
        if (item.itemId.isNotEmpty) {
          context.push('/item/${item.itemId}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BorderColor,
          borderRadius: defaultBorder,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: defaultBorder,
              child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                  ? Image.network(
                      item.thumbnailUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: ImageBackgroundColor,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: iconColor,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusInfo.color.withValues(alpha: 0.1),
                          borderRadius: defaultBorder,
                        ),
                        child: Text(
                          statusInfo.label,
                          style: TextStyle(
                            color: statusInfo.color,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (item.currentPrice > 0)
                    Text(
                      '현재가격 ${item.currentPrice.toCommaString()}원',
                      style: const TextStyle(fontSize: 14),
                    ),
                  if (item.buyNowPrice != null && item.buyNowPrice! > 0)
                    Text(
                      '즉시가격 ${item.buyNowPrice!.toCommaString()}원',
                      style: const TextStyle(fontSize: 14),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: isProcessing ? null : onPressed,
              icon: isProcessing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      item.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: item.isFavorite ? RedColor : iconColor,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
