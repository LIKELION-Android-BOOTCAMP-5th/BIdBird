import 'package:bidbird/core/utils/item/item_trade_status_utils.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:bidbird/core/widgets/notification_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/ui_set/border_radius_style.dart';
import '../model/current_trade_entity.dart';
import '../viewmodel/current_trade_viewmodel.dart';

class CurrentTradeScreen extends StatefulWidget {
  const CurrentTradeScreen({super.key});

  @override
  State<CurrentTradeScreen> createState() => _CurrentTradeScreenState();
}

class _CurrentTradeScreenState extends State<CurrentTradeScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
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
            // Layer 1: 역할 탭
            _buildTabBar(),
            // Layer 2: 액션 허브
            if (!viewModel.isLoading && viewModel.error == null) ...[
              const SizedBox(height: 16),
              if (_selectedTabIndex == 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ActionHub(
                    items: viewModel.saleActionHubItems,
                    isSeller: true,
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (_selectedTabIndex == 1) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ActionHub(
                    items: viewModel.bidActionHubItems,
                    isSeller: false,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
            // Layer 3: 그룹핑된 리스트
            if (viewModel.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (viewModel.error != null)
              Expanded(
                child: Center(child: Text(viewModel.error ?? '오류가 발생했습니다.')),
              )
            else
              Expanded(
                child: _selectedTabIndex == 0
                    ? _buildSaleHistoryList(viewModel)
                    : _buildBidHistoryList(viewModel),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTabButton(index: 0, label: '판매 내역'),
          const SizedBox(width: 8),
          _buildTabButton(index: 1, label: '입찰 내역'),
        ],
      ),
    );
  }

  Widget _buildTabButton({required int index, required String label}) {
    final bool isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? blueColor : BackgroundColor,
            borderRadius: BorderRadius.circular(defaultRadius),
            border: Border.all(color: blueColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: buttonFontStyle.fontSize,
              fontWeight: buttonFontStyle.fontWeight,
              color: isSelected ? BackgroundColor : blueColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBidHistoryList(CurrentTradeViewModel viewModel) {
    // 모든 거래 항목을 하나의 리스트로 합치기 (완료 제외)
    final allItems = [
      ...viewModel.todoBidItems,
      ...viewModel.inProgressBidItems,
      ...viewModel.completedBidItems,
    ];

    if (allItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
        child: const Center(child: Text('입찰 내역이 없습니다.')),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          ...allItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryCard(
                  title: item.title,
                  thumbnailUrl: item.thumbnailUrl,
                  status: item.status,
                  price: item.price,
                  itemId: item.itemId,
                  actionType: item.actionType,
                  isHighlighted: item.itemStatus == TradeItemStatus.todo,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSaleHistoryList(CurrentTradeViewModel viewModel) {
    // 모든 거래 항목을 하나의 리스트로 합치기 (완료 포함)
    final allItems = [
      ...viewModel.todoSaleItems,
      ...viewModel.inProgressSaleItems,
      ...viewModel.completedSaleItems,
    ];

    if (allItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
        child: const Center(child: Text('판매 내역이 없습니다.')),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          ...allItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryCard(
                  title: item.title,
                  thumbnailUrl: item.thumbnailUrl,
                  status: item.status,
                  price: item.price,
                  itemId: item.itemId,
                  actionType: item.actionType,
                  isHighlighted: item.itemStatus == TradeItemStatus.todo,
                  date: item.date,
                ),
              )),
        ],
      ),
    );
  }
}

/// 액션 허브 위젯 (Layer 2)
class _ActionHub extends StatelessWidget {
  const _ActionHub({
    required this.items,
    required this.isSeller,
  });

  final List<ActionHubItem> items;
  final bool isSeller;

  @override
  Widget build(BuildContext context) {
    final itemList = items.take(2).toList();
    return Column(
      children: [
        for (int i = 0; i < itemList.length; i++) ...[
          _ActionHubCard(
            item: itemList[i],
            isSeller: isSeller,
          ),
          if (i < itemList.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _ActionHubCard extends StatelessWidget {
  const _ActionHubCard({
    required this.item,
    required this.isSeller,
  });

  final ActionHubItem item;
  final bool isSeller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/bid/filtered',
          extra: {
            'actionType': item.actionType,
            'isSeller': isSeller,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: defaultBorder,
          border: Border.all(color: BorderColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: blueColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${item.count}건',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: blueColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: BorderColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.title,
    required this.thumbnailUrl,
    required this.status,
    required this.price,
    required this.itemId,
    required this.actionType,
    this.isHighlighted = false,
    this.date,
  });

  final String title;
  final String? thumbnailUrl;
  final String status;
  final int price;
  final String itemId;
  final TradeActionType actionType;
  final bool isHighlighted;
  final String? date;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (itemId.isNotEmpty) {
          context.push('/item/$itemId');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: defaultBorder,
          border: Border.all(
            color: BorderColor.withValues(alpha: 0.25),
            width: isHighlighted ? 1.5 : 1,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: blueColor.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
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
                    child: thumbnailUrl != null && thumbnailUrl!.isNotEmpty
                        ? Image.network(
                            thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.image_outlined, color: BorderColor),
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
                              title,
                              style: const TextStyle(fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: getTradeStatusColor(status).withValues(alpha: 0.1),
                              borderRadius: defaultBorder,
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: getTradeStatusColor(status),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatMoney(price),
                        style: const TextStyle(fontSize: 13, color: textColor),
                      ),
                      if (date != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          date!,
                          style: const TextStyle(fontSize: 12, color: BorderColor),
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
