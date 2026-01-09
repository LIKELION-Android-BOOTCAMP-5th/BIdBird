import 'package:bidbird/features/mypage/domain/entities/trade_history_entity.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:bidbird/core/widgets/unified_empty_state.dart';
import 'package:bidbird/features/current_trade/presentation/widgets/trade_history_card.dart';
import 'package:bidbird/features/mypage/viewmodel/trade_history_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TradeHistoryScreen extends StatelessWidget {
  const TradeHistoryScreen({super.key});

  bool _onScrollNotification(
    ScrollNotification notification,
    TradeHistoryViewModel vm,
  ) {
    if (notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 200) {
      vm.loadPage();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<TradeHistoryViewModel>();
    final role = context.select<TradeHistoryViewModel, TradeRole>(
      (vm) => vm.role,
    );

    return Scaffold(
      backgroundColor: BackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('거래내역'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopRoleTabs(role: role, onChanged: vm.changeRole),
              const SizedBox(height: 12),
              Expanded(
                child: vm.items.isEmpty && vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.items.isEmpty
                        ? UnifiedEmptyState(
                            title: '표시할 거래가 없습니다.',
                            subtitle: '거래 내역이 쌓이면 이곳에서 확인할 수 있습니다.',
                            onRefresh: vm.refresh,
                          )
                        : TransparentRefreshIndicator(
                            onRefresh: vm.refresh,
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (n) => _onScrollNotification(n, vm),
                              child: ListView.separated(
                                itemCount: vm.items.length + (vm.hasMore ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  if (index >= vm.items.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }
                                  final item = vm.items[index];
                                  // 반응형 여부 확인
                                  final useResponsive =
                                      MediaQuery.of(context).size.width >= 360;

                                  bool isTopBidder = false;
                                  bool isOpponentTopBidder = false;
                                  bool isExpired = false;
                                  final code = item.statusCode;
                                  final role = item.role;

                                  if (role == TradeRole.buyer) {
                                    // 구매자 입장
                                    if ([421, 430, 431, 510, 520, 550]
                                        .contains(code)) {
                                      isTopBidder = true; // "낙찰 물품" (노란색)
                                    } else if ([
                                          422,
                                          432,
                                          433,
                                          530,
                                          540,
                                        ].contains(code) ||
                                        (item.endAt != null &&
                                            item.endAt!.isBefore(DateTime.now()))) {
                                      isExpired = true; // "만료/패찰" (회색)
                                    }
                                  } else {
                                    // 판매자 입장
                                    if ([321, 322, 510, 520, 550]
                                        .contains(code)) {
                                      isOpponentTopBidder = true; // "낙찰자" 존재 (노란색)
                                    } else if ([323, 530, 540].contains(code) ||
                                        (item.endAt != null &&
                                            item.endAt!.isBefore(DateTime.now()) &&
                                            ![321, 322, 510, 520, 550]
                                                .contains(code))) {
                                      isExpired = true; // "유찰/취소" (회색)
                                    }
                                  }

                                  return TradeHistoryCard(
                                    title: item.title,
                                    thumbnailUrl: item.thumbnailUrl,
                                    status: item.statusCode.toString(),
                                    price: item.currentPrice,
                                    itemId: item.itemId,
                                    isSeller: item.role == TradeRole.seller,
                                    useResponsive: useResponsive,
                                    isTopBidder: isTopBidder,
                                    isOpponentTopBidder: isOpponentTopBidder,
                                    isExpired: isExpired,
                                    isHighlighted: false,
                                  );
                                },
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopRoleTabs extends StatelessWidget {
  const _TopRoleTabs({required this.role, required this.onChanged});

  final TradeRole role;
  final ValueChanged<TradeRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(const Size(0, 40)),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? blueColor : BackgroundColor,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? BackgroundColor : blueColor,
      ),
      side: WidgetStateProperty.all(BorderSide(color: blueColor)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: defaultBorder),
      ),
      textStyle: WidgetStateProperty.all(
        TextStyle(
          fontSize: buttonFontStyle.fontSize,
          fontWeight: buttonFontStyle.fontWeight,
        ),
      ),
    );

    return SegmentedButton<TradeRole>(
      segments: const [
        ButtonSegment(value: TradeRole.seller, label: Text('판매 내역')),
        ButtonSegment(value: TradeRole.buyer, label: Text('구매 내역')),
      ],
      selected: {role},
      onSelectionChanged: (selection) {
        final next = selection.first;
        if (next != role) onChanged(next);
      },
      showSelectedIcon: false,
      style: buttonStyle,
    );
  }
}
