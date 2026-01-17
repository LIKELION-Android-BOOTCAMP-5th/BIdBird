import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:bidbird/features/bid/presentation/widgets/item_detail_bid_history_entry.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_bottom_action_bar.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_description_section.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_image_gallery.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_seller_row.dart';
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

