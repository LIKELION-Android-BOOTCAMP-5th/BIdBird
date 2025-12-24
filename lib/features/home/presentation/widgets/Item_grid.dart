import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/home_viewmodel.dart';
import 'item_card.dart';

class ItemGrid extends StatelessWidget {
  const ItemGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // 길이만 구독해서 페이징(addAll) 같은 동일 리스트 참조 변경도 감지
    final itemsLength = context.select<HomeViewmodel, int>(
      (vm) => vm.items.length,
    );
    final items = context.read<HomeViewmodel>().items;
    return SliverPadding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 15),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            final title = item.title;

            return ItemCard(item: item, title: title);
          },
          childCount: itemsLength,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }
}
