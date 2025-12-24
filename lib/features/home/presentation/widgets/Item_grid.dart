import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/home_viewmodel.dart';
import 'item_card.dart';

class ItemGrid extends StatelessWidget {
  const ItemGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 15),
      sliver: Consumer<HomeViewmodel>(
        builder: (context, viewModel, _) {
          final items = viewModel.items;
          final itemsLength = items.length;

          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
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
