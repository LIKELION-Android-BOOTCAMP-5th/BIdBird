import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:bidbird/features/mypage/model/trade_history_model.dart';
import 'package:bidbird/features/mypage/viewmodel/trade_history_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

    final statusOptions = vm.role == TradeRole.seller
        ? _sellerFilters
        : _buyerFilters;

    return Scaffold(
      backgroundColor: BackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('거래 내역'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopRoleTabs(role: vm.role, onChanged: vm.changeRole),
              const SizedBox(height: 16),
              _Filters(
                options: statusOptions,
                selected: vm.statusFilter,
                onSelected: vm.changeFilter,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) => _onScrollNotification(n, vm),
                    child: vm.items.isEmpty && vm.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : vm.items.isEmpty
                        ? const _EmptyState()
                        : ListView.separated(
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
                              return _HistoryItem(item: item);
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

class _StatusInfo {
  const _StatusInfo({
    required this.code,
    required this.label,
    required this.color,
    required this.pricePrefix,
  });

  final int code;
  final String label;
  final Color color;
  final String pricePrefix;
}

const List<_StatusInfo> _statusInfoList = [
  _StatusInfo(
    code: 300,
    label: '경매 대기',
    color: BorderColor,
    pricePrefix: '시작가',
  ),
  _StatusInfo(
    code: 310,
    label: '경매 진행 중',
    color: blueColor,
    pricePrefix: '현재가',
  ),
  _StatusInfo(
    code: 311,
    label: '즉시 구매 진행 중',
    color: blueColor,
    pricePrefix: '현재가',
  ),
  _StatusInfo(
    code: 321,
    label: '낙찰',
    color: tradeSaleDoneColor,
    pricePrefix: '낙찰가',
  ),
  _StatusInfo(
    code: 322,
    label: '즉시 구매 완료',
    color: tradeSaleDoneColor,
    pricePrefix: '낙찰가',
  ),
  _StatusInfo(code: 323, label: '유찰', color: RedColor, pricePrefix: '최고가'),
  _StatusInfo(
    code: 410,
    label: '입찰 참여',
    color: tradeBidPendingColor,
    pricePrefix: '내 입찰가',
  ),
  _StatusInfo(
    code: 411,
    label: '상위 입찰 중',
    color: tradeBidPendingColor,
    pricePrefix: '내 입찰가',
  ),
  _StatusInfo(
    code: 430,
    label: '입찰 낙찰',
    color: tradePurchaseDoneColor,
    pricePrefix: '낙찰가',
  ),
  _StatusInfo(
    code: 431,
    label: '즉시 구매 낙찰',
    color: tradePurchaseDoneColor,
    pricePrefix: '구매가',
  ),
  _StatusInfo(
    code: 510,
    label: '결제 대기',
    color: yellowColor,
    pricePrefix: '결제 금액',
  ),
  _StatusInfo(
    code: 520,
    label: '결제 완료',
    color: tradePurchaseDoneColor,
    pricePrefix: '결제 금액',
  ),
  _StatusInfo(
    code: 550,
    label: '거래 완료',
    color: tradeSaleDoneColor,
    pricePrefix: '거래가',
  ),
  _StatusInfo(code: 0, label: '패찰', color: BorderColor, pricePrefix: '내 입찰가'),
];

final Map<int, _StatusInfo> _statusInfoMap = {
  for (final m in _statusInfoList) m.code: m,
};

List<_StatusInfo> _buildFilters(List<int> codes) =>
    codes.map((code) => _statusInfoMap[code]).whereType<_StatusInfo>().toList();

final List<_StatusInfo> _sellerFilters = _buildFilters([
  300,
  310,
  311,
  321,
  322,
  510,
  520,
  550,
  323,
]);

final List<_StatusInfo> _buyerFilters = _buildFilters([
  410,
  411,
  430,
  431,
  510,
  520,
  550,
  0,
]);

class _TopRoleTabs extends StatelessWidget {
  const _TopRoleTabs({required this.role, required this.onChanged});

  final TradeRole role;
  final ValueChanged<TradeRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoleTabButton(
          label: '판매 내역',
          isSelected: role == TradeRole.seller,
          onTap: () => onChanged(TradeRole.seller),
        ),
        const SizedBox(width: 8),
        _RoleTabButton(
          label: '구매 내역',
          isSelected: role == TradeRole.buyer,
          onTap: () => onChanged(TradeRole.buyer),
        ),
      ],
    );
  }
}

class _RoleTabButton extends StatelessWidget {
  const _RoleTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? blueColor : BackgroundColor,
            borderRadius: defaultBorder,
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
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<_StatusInfo> options;
  final int? selected;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(option.label),
              selected: selected == option.code,
              onSelected: (_) => onSelected(option.code),
              showCheckmark: false,
              selectedColor: blueColor.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: selected == option.code ? blueColor : textColor,
              ),
              backgroundColor: Colors.white,
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected == option.code
                      ? blueColor.withValues(alpha: 0.5)
                      : BorderColor.withValues(alpha: 0.4),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.item});

  final TradeHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final info = _statusInfoMap[item.statusCode];
    final priceLabel = _priceLabel(item, info);
    final buyNowText = (item.buyNowPrice != null && item.buyNowPrice! > 0)
        ? '즉시구매가 ${_formatMoney(item.buyNowPrice!)}'
        : null;
    final displayInfo =
        info ??
        _StatusInfo(
          code: item.statusCode,
          label: '알 수 없음 (${item.statusCode})',
          color: BorderColor,
          pricePrefix: '가격',
        );

    return GestureDetector(
      onTap: () {
        if (item.itemId.isNotEmpty) {
          context.push('/item/${item.itemId}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: defaultBorder,
          border: Border.all(color: BorderColor.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(url: item.thumbnailUrl),
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
                          item.title,
                          style: const TextStyle(fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Status(label: displayInfo.label, color: displayInfo.color),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    priceLabel,
                    style: const TextStyle(fontSize: 13, color: textColor),
                  ),
                  if (buyNowText != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          buyNowText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: BorderColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _priceLabel(TradeHistoryItem item, _StatusInfo? info) {
    final prefix = info?.pricePrefix ?? '가격';
    final label = info?.label ?? '';
    if (item.currentPrice <= 0 &&
        (label.contains('유찰') || label.contains('패찰'))) {
      return '입찰 없음';
    }
    final price = _formatMoney(item.currentPrice);
    return '$prefix $price';
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

class _Status extends StatelessWidget {
  const _Status({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: defaultBorder,
      ),
      child: Text(label, style: TextStyle(color: color)),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final hasImage = url != null && url!.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 64,
        height: 64,
        color: BackgroundColor,
        child: hasImage
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_outlined, color: BorderColor),
              )
            : const Icon(Icons.image_outlined, color: BorderColor),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '표시할 거래가 없습니다.',
        style: TextStyle(fontSize: 13, color: BorderColor),
      ),
    );
  }
}
