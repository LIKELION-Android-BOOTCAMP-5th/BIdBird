import 'package:flutter/material.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_bottom_action_bar.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/blocks/item_detail_body.dart';

class ItemDetailContentBlock extends StatelessWidget {
  const ItemDetailContentBlock({
    super.key,
    required this.item,
    required this.isMyItem,
    required this.onRefresh,
    required this.appBar,
  });

  final ItemDetail item;
  final bool isMyItem;
  final Future<void> Function() onRefresh;
  final PreferredSizeWidget appBar;

  @override
  Widget build(BuildContext context) {
    return ItemDetailBody(
      item: item,
      isMyItem: isMyItem,
      onRefresh: onRefresh,
      appBar: appBar,
      bottomActionBar: ItemBottomActionBar(
        item: item,
        isMyItem: isMyItem,
      ),
    );
  }
}

