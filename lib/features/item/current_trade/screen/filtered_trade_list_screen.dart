import 'package:bidbird/core/utils/item/item_trade_status_utils.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../model/current_trade_entity.dart';
import '../viewmodel/current_trade_viewmodel.dart';

class FilteredTradeListScreen extends StatelessWidget {
  const FilteredTradeListScreen({
    super.key,
    required this.actionType,
    required this.isSeller,
  });

  final TradeActionType actionType;
  final bool isSeller;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CurrentTradeViewModel>();
    
    // 액션 타입에 맞는 항목 필터링
    final filteredItems = isSeller
        ? viewModel.saleHistory
            .where((item) => item.actionType == actionType)
            .toList()
        : viewModel.bidHistory
            .where((item) => item.actionType == actionType)
            .toList();

    // 액션 타입에 맞는 제목 가져오기
    final title = _getTitle(actionType);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: filteredItems.isEmpty
            ? RefreshIndicator(
                onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
                child: const Center(child: Text('해당 내역이 없습니다.')),
              )
            : RefreshIndicator(
                onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  children: [
                    ...filteredItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildHistoryCard(context, item, isSeller),
                        )),
                  ],
                ),
              ),
      ),
    );
  }

  String _getTitle(TradeActionType actionType) {
    switch (actionType) {
      case TradeActionType.paymentRequired:
        return '결제 대기';
      case TradeActionType.shippingInfoRequired:
        return '배송지 입력';
      case TradeActionType.purchaseConfirmRequired:
        return '구매 확정';
      case TradeActionType.none:
        return '현재 거래 내역';
    }
  }

  Widget _buildHistoryCard(BuildContext context, dynamic item, bool isSeller) {
    if (isSeller) {
      final saleItem = item as SaleHistoryItem;
      return GestureDetector(
        onTap: () {
          if (saleItem.itemId.isNotEmpty) {
            context.push('/item/${saleItem.itemId}');
          }
        },
        child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: defaultBorder,
          border: Border.all(
            color: BorderColor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 썸네일
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: BackgroundColor,
                    child: saleItem.thumbnailUrl != null &&
                            saleItem.thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            saleItem.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_outlined,
                                    color: BorderColor),
                          )
                        : const Icon(Icons.image_outlined, color: BorderColor),
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
                          Expanded(
                            child: Text(
                              saleItem.title,
                              style: const TextStyle(fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: getTradeStatusColor(saleItem.status)
                                  .withValues(alpha: 0.1),
                              borderRadius: defaultBorder,
                            ),
                            child: Text(
                              saleItem.status,
                              style: TextStyle(
                                color: getTradeStatusColor(saleItem.status),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatMoney(saleItem.price)}',
                        style: const TextStyle(fontSize: 13, color: textColor),
                      ),
                      if (saleItem.date.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          saleItem.date,
                          style:
                              const TextStyle(fontSize: 12, color: BorderColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      );
    } else {
      final bidItem = item as BidHistoryItem;
      return GestureDetector(
        onTap: () {
          if (bidItem.itemId.isNotEmpty) {
            context.push('/item/${bidItem.itemId}');
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: defaultBorder,
            border: Border.all(
              color: BorderColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 썸네일
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: BackgroundColor,
                      child: bidItem.thumbnailUrl != null &&
                              bidItem.thumbnailUrl!.isNotEmpty
                          ? Image.network(
                              bidItem.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_outlined,
                                      color: BorderColor),
                            )
                          : const Icon(Icons.image_outlined, color: BorderColor),
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
                            Expanded(
                              child: Text(
                                bidItem.title,
                                style: const TextStyle(fontSize: 15),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: getTradeStatusColor(bidItem.status)
                                    .withValues(alpha: 0.1),
                                borderRadius: defaultBorder,
                              ),
                              child: Text(
                                bidItem.status,
                                style: TextStyle(
                                  color: getTradeStatusColor(bidItem.status),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_formatMoney(bidItem.price)}',
                          style:
                              const TextStyle(fontSize: 13, color: textColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  String _formatMoney(int value) {
    final s = value.toString();
    final formatted = s.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '$formatted원';
  }
}

