import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:bidbird/features/bid/presentation/widgets/item_detail_bid_history_entry.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_bottom_action_bar.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_description_section.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_image_gallery.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_seller_row.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_summary_section.dart';

class ItemDetailContentBlock extends StatelessWidget {
  const ItemDetailContentBlock({super.key, required this.item, required this.isMyItem, required this.onRefresh, required this.appBar});
  final ItemDetail item;
  final bool isMyItem;
  final Future<void> Function() onRefresh;
  final PreferredSizeWidget appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Column(
        children: [
          Expanded(
            child: TransparentRefreshIndicator(
              onRefresh: onRefresh,
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ItemDetailImageGallery(item: item),
                    Transform.translate(
                      offset: const Offset(0, -30),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            children: [
                              ItemDetailSummarySection(item: item, isMyItem: isMyItem),
                              ItemDetailSellerRow(item: item),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ItemDetailDescriptionSection(item: item),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: context.screenPadding),
                      child: const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                    ),
                    ItemDetailBidHistoryEntry(item: item),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
          ItemBottomActionBar(item: item, isMyItem: isMyItem),
        ],
      ),
    );
  }
}
