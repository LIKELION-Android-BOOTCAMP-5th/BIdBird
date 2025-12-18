import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/viewmodels/item_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bidbird/features/bid/presentation/widgets/item_detail_bid_history_bottom_sheet.dart';

class ItemDetailBidHistoryEntry extends StatelessWidget {
  const ItemDetailBidHistoryEntry({required this.item, super.key});

  final ItemDetail item;

  @override
  Widget build(BuildContext context) {
    return Selector<ItemDetailViewModel, List<BidHistoryItem>>(
      selector: (_, vm) => vm.bidHistory,
      builder: (context, bidHistory, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 15, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '최근 입찰 내역',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF191F28), // Primary Text
                ),
              ),
              GestureDetector(
                onTap: () {
                  final viewModel = context.read<ItemDetailViewModel>();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    useSafeArea: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (bottomSheetContext) => ChangeNotifierProvider<ItemDetailViewModel>.value(
                      value: viewModel,
                      child: ItemDetailBidHistoryBottomSheet(
                        itemId: item.itemId,
                      ),
                    ),
                  );
                },
                child: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0xFF9CA3AF), // Tertiary
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

