import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/item/user_history/data/repository/user_history_repository.dart';
import 'package:bidbird/features/item/user_history/model/user_history_entity.dart';
import 'package:bidbird/core/widgets/item/trade_status_chip.dart';
import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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
          future: UserHistoryRepository().fetchUserTrades(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final trades = snapshot.data ?? [];
            if (trades.isEmpty) {
              return const Center(
                child: Text(
                  '거래 내역이 없습니다.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trades.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final trade = trades[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BackgroundColor,
                    borderRadius: defaultBorder,
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: trade.thumbnailUrl != null &&
                                  trade.thumbnailUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: trade.thumbnailUrl!,
                                  cacheManager:
                                      ItemImageCacheManager.instance,
                                  fit: BoxFit.cover,
                                  errorWidget:
                                      (context, error, stackTrace) =>
                                          Container(color: BackgroundColor),
                                )
                              : Container(color: BackgroundColor),
                        ),
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
    );
  }
}
