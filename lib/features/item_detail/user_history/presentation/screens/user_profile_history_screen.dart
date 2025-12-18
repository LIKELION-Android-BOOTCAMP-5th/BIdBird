import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/item_detail/user_history/domain/entities/user_history_entity.dart';
import 'package:bidbird/features/item_detail/user_history/presentation/viewmodels/user_history_viewmodel.dart';
import 'package:bidbird/features/item_trade/trade_status/presentation/widgets/trade_status_chip.dart';
import 'package:bidbird/core/widgets/item/components/thumbnail/fixed_ratio_thumbnail.dart';
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
              if (viewModel.trades.isEmpty) {
                return const Center(
                  child: Text(
                    '거래 내역이 없습니다.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: viewModel.trades.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final trade = viewModel.trades[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BackgroundColor,
                      borderRadius: defaultBorder,
                    ),
                    child: Row(
                      children: [
                        FixedRatioThumbnail(
                          imageUrl: trade.thumbnailUrl,
                          width: 48,
                          height: 48,
                          aspectRatio: 1.0,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trade.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${trade.price}  ·  ${trade.date}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: BorderColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TradeStatusChip(
                          label: trade.statusLabel,
                          color: trade.statusColor,
                        ),
                      ],
                    ),
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



