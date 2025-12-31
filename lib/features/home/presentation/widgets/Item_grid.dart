import 'package:bidbird/core/widgets/unified_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/home_viewmodel.dart';
import 'item_card.dart';

class ItemGrid extends StatelessWidget {
  final GlobalKey? currentPriceKey;
  final GlobalKey? biddingCountKey;
  final GlobalKey? finishTimeKey;
  const ItemGrid({
    super.key,
    this.currentPriceKey,
    this.biddingCountKey,
    this.finishTimeKey,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20, top: 10),
      sliver: Consumer<HomeViewmodel>(
        builder: (context, viewModel, _) {
          final items = viewModel.items;
          final itemsLength = items.length;

          // 로딩 중이거나 아직 초기화되지 않았고 아이템이 없으면 빈 화면(배경) 표시
          if ((viewModel.isLoading || !viewModel.isInitialized) &&
              items.isEmpty) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: SizedBox.shrink(),
            );
          }

          if (items.isEmpty) {
            return const SliverFillRemaining(
              hasScrollBody: false,
              child: UnifiedEmptyState(
                title: '등록된 경매가 없습니다',
                subtitle: '가장 먼저 상품을 등록해보세요!',
              ),
            );
          }

          final double width = MediaQuery.of(context).size.width;
          int crossAxisCount = 2;
          if (width >= 900) {
            crossAxisCount = 4;
          } else if (width >= 600) {
            crossAxisCount = 3;
          }

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.9, // 오버플로우 해결을 위해 비율 조정
              mainAxisSpacing: 5, // 간격 늘리기
              crossAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // 마지막 아이템에 도달하면 다음 페이지 불러오기
                if (index == itemsLength - 1) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    viewModel.fetchNextItems();
                  });
                }

                final item = items[index];
                final title = item.title;

                return ItemCard(
                  item: item,
                  title: title,
                  currentPriceKey: index == 0 ? currentPriceKey : null,
                  biddingCountKey: index == 0 ? biddingCountKey : null,
                  finishTimeKey: index == 0 ? finishTimeKey : null,
                );
              },
              childCount: itemsLength,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
            ),
          );
        },
      ),
    );
  }
}
