import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 액션 허브 위젯 (Layer 2)
class ActionHub extends StatelessWidget {
  const ActionHub({
    super.key,
    required this.saleItems,
    required this.bidItems,
    required this.todoSaleItems,
    required this.todoBidItems,
    required this.saleHistory,
    required this.bidHistory,
  });

  final List<ActionHubItem> saleItems;
  final List<ActionHubItem> bidItems;
  final List<dynamic> todoSaleItems;
  final List<dynamic> todoBidItems;
  final List<dynamic> saleHistory;
  final List<dynamic> bidHistory;

  @override
  Widget build(BuildContext context) {
    // 판매와 입찰 액션을 합치고 중복 제거
    final Map<TradeActionType, int> combinedCounts = {};
    
    // 판매 내역 확인
    for (final item in saleHistory) {
      TradeActionType? actionType;
      
      // tradeStatusCode를 직접 확인
      if (item.tradeStatusCode == 510) {
        actionType = TradeActionType.paymentWaiting; // 판매자는 paymentWaiting
      } else if (item.tradeStatusCode == 520 && !item.hasShippingInfo) {
        actionType = TradeActionType.shippingInfoRequired;
      }
      
      if (actionType != null) {
        final beforeCount = combinedCounts[actionType] ?? 0;
        combinedCounts[actionType] = beforeCount + 1;
      }
    }
    
    // 입찰 내역 확인
    for (final item in bidHistory) {
      TradeActionType? actionType;
      
      // tradeStatusCode를 직접 확인
      if (item.tradeStatusCode == 510) {
        actionType = TradeActionType.paymentRequired;
      } else if (item.tradeStatusCode == 520) {
        // 입찰 내역: 520이면 구매 확정 가능 (배송 정보 있으면 확정, 없으면 대기)
        if (item.hasShippingInfo) {
          actionType = TradeActionType.purchaseConfirmRequired;
        }
      } else if ((item.tradeStatusCode == null || item.tradeStatusCode == 0) && 
                 item.auctionStatusCode == 321) {
        // 입찰 낙찰 상태이고 trade_status_code가 없으면 결제 대기로 간주
        actionType = TradeActionType.paymentRequired;
      }
      
      if (actionType != null) {
        final beforeCount = combinedCounts[actionType] ?? 0;
        combinedCounts[actionType] = beforeCount + 1;
      }
    }
    
    final combinedItems = combinedCounts.entries
        .where((e) => e.value > 0) // 0건인 항목은 제외
        .map((e) => ActionHubItem(actionType: e.key, count: e.value))
        .toList();
    
    combinedItems.sort((a, b) => b.count.compareTo(a.count));
    
    // 전체 건수 계산 (0건이어도 표시)
    final totalCount = combinedItems.fold<int>(0, (sum, item) => sum + item.count);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 통합 액션 박스
        GestureDetector(
          onTap: () async {
            if (combinedItems.isEmpty || !context.mounted) return;
            
            final actionTypes = combinedItems.map((item) => item.actionType).toList();
            await context.push(
              '/bid/filtered',
              extra: {
                'actionType': combinedItems.first.actionType,
                'actionTypes': actionTypes,
                'isSeller': null,
              },
            );
          },
          child: Container(
            padding: EdgeInsets.all(context.spacingMedium),
            decoration: BoxDecoration(
              color: blueColor,
              borderRadius: defaultBorder,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '지금 처리해야 할 거래 $totalCount건',
                        style: TextStyle(
                          fontSize: context.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: chatItemCardBackground,
                        ),
                      ),
                      if (combinedItems.isNotEmpty) ...[
                        SizedBox(height: context.spacingSmall * 0.5),
                        // 액션 타입들을 한 줄로 표시
                        Wrap(
                          spacing: context.spacingSmall,
                          runSpacing: context.spacingSmall * 0.5,
                          children: combinedItems.map((item) {
                            return Text(
                              '${item.label} ${item.count}건',
                              style: TextStyle(
                                fontSize: context.fontSizeSmall,
                                color: chatItemCardBackground.withValues(alpha: 0.9),
                              ),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        SizedBox(height: context.spacingSmall * 0.5),
                        Text(
                          '처리할 거래가 없습니다',
                          style: TextStyle(
                            fontSize: context.fontSizeSmall,
                            color: chatItemCardBackground.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: context.spacingSmall * 1.5),
                Container(
                  width: context.iconSizeMedium,
                  height: context.iconSizeMedium,
                  decoration: BoxDecoration(
                    color: chatItemCardBackground.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: chatItemCardBackground,
                    size: context.iconSizeSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

