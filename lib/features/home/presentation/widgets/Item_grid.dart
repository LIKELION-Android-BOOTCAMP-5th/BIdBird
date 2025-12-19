import 'package:flutter/material.dart';

import '../viewmodel/home_viewmodel.dart';
import 'item_card.dart';

class ItemGrid extends StatelessWidget {
  final HomeViewmodel viewModel;
  const ItemGrid({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 15),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = viewModel.items[index];
          final title = item.title;

          return ItemCard(item: item, title: title);
        }, childCount: viewModel.items.length),
      ),
    );
  }
}
