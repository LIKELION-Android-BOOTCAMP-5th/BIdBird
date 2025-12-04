import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/utils/ui_set/fonts.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../viewmodel/current_trade_viewmodel.dart';
import '../widgets/history_card.dart';
import '../../../../core/utils/ui_set/border_radius.dart';
import '../../../../core/utils/ui_set/icons.dart';

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
          children: [
            const Text('현재 거래 내역'),
            Image.asset(
              'assets/icons/alarm_icon.png',
              width: iconSize.width,
              height: iconSize.height,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          const SizedBox(height: 8),
          if (viewModel.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (viewModel.error != null)
            Expanded(
              child: Center(
                child: Text(viewModel.error ?? '오류가 발생했습니다.'),
              ),
            )
          else
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildSaleHistoryList(viewModel)
                  : _buildBidHistoryList(viewModel),
            ),
        ],
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
            color: isSelected
                ? blueColor
                : BackgroundColor,
            borderRadius: BorderRadius.circular(defaultRadius),
            border: Border.all(color: blueColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: buttonFontStyle.fontSize,
              fontWeight: buttonFontStyle.fontWeight,
              color: isSelected
                  ? BackgroundColor
                  : blueColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBidHistoryList(CurrentTradeViewModel viewModel) {
    final data = viewModel.bidHistory;

    if (data.isEmpty) {
      return const Center(
        child: Text('입찰 내역이 없습니다.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = data[index];
          return HistoryCard(
            title: item.title,
            thumbnailUrl: item.thumbnailUrl,
            status: item.status,
            date: null,
            onTap: () {
              if (item.itemId.isNotEmpty) {
                context.push('/item/${item.itemId}');
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildSaleHistoryList(CurrentTradeViewModel viewModel) {
    final data = viewModel.saleHistory;

    if (data.isEmpty) {
      return const Center(
        child: Text('판매 내역이 없습니다.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CurrentTradeViewModel>().refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = data[index];
          return HistoryCard(
            title: item.title,
            thumbnailUrl: item.thumbnailUrl,
            status: item.status,
            date: item.date,
            onTap: () {
              final itemId = item.itemId;
              debugPrint('[CurrentTradeScreen] 카드 탭: item_id=$itemId');
              if (itemId.isNotEmpty) {
                context.push('/item/$itemId');
              } else {
                debugPrint('[CurrentTradeScreen] item_id가 비어 있어서 이동하지 않습니다.');
              }
            },
          );
        },
      ),
    );
  }
}
