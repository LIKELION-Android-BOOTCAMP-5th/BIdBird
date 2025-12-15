import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/item/components/cards/trade_history_card.dart';
import 'package:bidbird/core/widgets/notification_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/widgets/item/components/others/action_hub.dart';
import '../model/current_trade_entity.dart';
import '../viewmodel/current_trade_viewmodel.dart';

class CurrentTradeScreen extends StatefulWidget {
  const CurrentTradeScreen({super.key});

  @override
  State<CurrentTradeScreen> createState() => _CurrentTradeScreenState();
}

class _CurrentTradeScreenState extends State<CurrentTradeScreen> {
  @override
  void initState() {
    super.initState();
    // 데이터 로드가 안 되어 있으면 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<CurrentTradeViewModel>();
      if (viewModel.bidHistory.isEmpty && 
          viewModel.saleHistory.isEmpty && 
          !viewModel.isLoading) {
        viewModel.loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CurrentTradeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [const Text('현재 거래 내역'), NotificationButton()],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Layer 2: 액션 허브
            if (!viewModel.isLoading && viewModel.error == null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ActionHub(
                  saleItems: viewModel.saleActionHubItems,
                  bidItems: viewModel.bidActionHubItems,
                  todoSaleItems: viewModel.todoSaleItems,
                  todoBidItems: viewModel.todoBidItems,
                  saleHistory: viewModel.saleHistory,
                  bidHistory: viewModel.bidHistory,
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const SizedBox.shrink(),
            ],
            // Layer 3: 통합된 리스트
            Expanded(
              child: _buildContent(viewModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(CurrentTradeViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (viewModel.error != null) {
      return RefreshIndicator(
        onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    viewModel.error ?? '오류가 발생했습니다.',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<CurrentTradeViewModel>().refresh(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return _buildUnifiedHistoryList(viewModel);
  }

  Widget _buildUnifiedHistoryList(CurrentTradeViewModel viewModel) {
    // 판매와 입찰 내역을 모두 합치기
    final allSaleItems = [
      ...viewModel.todoSaleItems,
      ...viewModel.inProgressSaleItems,
      ...viewModel.completedSaleItems,
    ].where((item) => !item.status.contains('유찰')).toList();
    
    final allBidItems = [
      ...viewModel.todoBidItems,
      ...viewModel.inProgressBidItems,
      ...viewModel.completedBidItems,
    ].where((item) => !item.status.contains('유찰')).toList();

    if (allSaleItems.isEmpty && allBidItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
        child: const Center(child: Text('거래 내역이 없습니다.')),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          // 판매 내역
          ...allSaleItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TradeHistoryCard(
                  title: item.title,
                  thumbnailUrl: item.thumbnailUrl,
                  status: item.status,
                  price: item.price,
                  itemId: item.itemId,
                  isSeller: true,
                  isHighlighted: item.itemStatus == TradeItemStatus.todo,
                ),
              )),
          // 입찰 내역
          ...allBidItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TradeHistoryCard(
                  title: item.title,
                  thumbnailUrl: item.thumbnailUrl,
                  status: item.status,
                  price: item.price,
                  itemId: item.itemId,
                  isSeller: false,
                  isHighlighted: item.itemStatus == TradeItemStatus.todo,
                ),
              )),
          // 전체 보기 링크
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  context.push('/mypage/trade');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '전체 보기',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: textColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


