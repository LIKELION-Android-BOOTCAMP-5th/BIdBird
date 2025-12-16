import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/item/components/cards/trade_status_item_card.dart';
import 'package:bidbird/features/item/user_history/data/datasource/user_history_datasource.dart';
import 'package:bidbird/features/item/user_history/model/user_history_entity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserTradeHistoryScreen extends StatelessWidget {
  const UserTradeHistoryScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('거래내역'), centerTitle: true),
      backgroundColor: BackgroundColor,
      body: SafeArea(
        child: FutureBuilder<List<UserTradeSummary>>(
          future: UserHistoryDatasource().fetchUserTrades(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final trades = snapshot.data ?? [];
            if (trades.isEmpty) {
              return const Center(
                child: Text(
                  '거래 내역이 없습니다.',
                  style: TextStyle(fontSize: 14, color: BorderColor),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: trades.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final trade = trades[index];
                // 가격 문자열에서 숫자만 추출 (예: "144,867원" -> 144867)
                final priceValue = int.tryParse(
                  trade.price.replaceAll(RegExp(r'[^0-9]'), ''),
                ) ?? 0;
                
                return TradeStatusItemCard(
                  title: trade.title,
                  price: priceValue,
                  thumbnailUrl: trade.thumbnailUrl,
                  roleText: trade.isSeller ? '판매자' : '구매자',
                  statusText: trade.statusLabel,
                  onTap: trade.itemId != null
                      ? () {
                          context.push('/item/${trade.itemId}');
                        }
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
