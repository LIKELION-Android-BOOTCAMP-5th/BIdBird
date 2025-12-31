import 'package:bidbird/core/widgets/unified_empty_state.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/current_trade/presentation/widgets/trade_history_card.dart';
import 'package:bidbird/features/item_detail/user_history/presentation/viewmodels/user_history_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserProfileHistoryScreen extends StatelessWidget {
  const UserProfileHistoryScreen({super.key, required this.userId});

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
              if (viewModel.isLoading) {
                return const SizedBox.shrink();
              }
              
              if (viewModel.trades.isEmpty) {
                return const UnifiedEmptyState(
                  title: '거래 내역이 없습니다',
                  subtitle: '아직 거래 기록이 존재하지 않습니다.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: viewModel.trades.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final trade = viewModel.trades[index];
                  final label = trade.statusLabel;
                  
                  // 뱃지 상태 결정 로직
                  final isWon = label.contains('낙찰');
                  final isExpired = label.contains('만료') || label.contains('유찰') || label.contains('취소') || label.contains('패찰');

                  // 가격 문자열 파싱 (예: "10,000원" -> 10000)
                  final priceInt = int.tryParse(trade.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

                  // 반응형 여부
                  final useResponsive = MediaQuery.of(context).size.width >= 360;

                  return TradeHistoryCard(
                    title: trade.title,
                    thumbnailUrl: trade.thumbnailUrl,
                    status: label,
                    price: priceInt,
                    itemId: trade.itemId ?? '',
                    isSeller: trade.isSeller,
                    useResponsive: useResponsive,
                    isTopBidder: !trade.isSeller && isWon,
                    isOpponentTopBidder: trade.isSeller && isWon,
                    isExpired: isExpired,
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
