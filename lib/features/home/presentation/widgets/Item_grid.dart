import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/home_viewmodel.dart';
import 'item_card.dart';

class ItemGrid extends StatelessWidget {
  const ItemGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20, top: 10),
      sliver: Consumer<HomeViewmodel>(
        builder: (context, viewModel, _) {
          final items = viewModel.items;
          final itemsLength = items.length;

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

                return ItemCard(item: item, title: title);
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
