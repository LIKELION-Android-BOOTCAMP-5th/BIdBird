import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/item_trade/trade_status/presentation/widgets/trade_status_item_card.dart';
import 'package:bidbird/features/item_detail/user_history/domain/entities/user_history_entity.dart';
import 'package:bidbird/features/item_detail/user_history/presentation/viewmodels/user_history_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class UserTradeHistoryScreen extends StatelessWidget {
  const UserTradeHistoryScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserHistoryViewModel()..loadTrades(userId),
      child: Scaffold(
        appBar: AppBar(title: const Text('거래내역'), centerTitle: true),
        backgroundColor: BackgroundColor,
        body: SafeArea(
          child: Consumer<UserHistoryViewModel>(
            builder: (context, viewModel, _) {
              if (viewModel.trades.isEmpty) {
                return const Center(
                  child: Text(
                    '거래 내역이 없습니다.',
                    style: TextStyle(fontSize: 14, color: BorderColor),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: viewModel.trades.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final trade = viewModel.trades[index];
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
      ),
    );
  }
}



