import 'package:bidbird/core/widgets/unified_empty_state.dart';
import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/core/utils/extension/money_extension.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:bidbird/features/mypage/domain/entities/trade_history_entity.dart';
import 'package:bidbird/features/mypage/viewmodel/trade_history_viewmodel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
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
    final vm = context
        .watch<
          TradeHistoryViewModel
        >(); //read로해놨었는데로딩인디케이터만보이는현상있어서watch해보니까돼서그냥이렇게하기로함
    final role = context.select<TradeHistoryViewModel, TradeRole>(
      (vm) => vm.role,
    );
    final statusFilter = context.select<TradeHistoryViewModel, List<int>?>(
      (vm) => vm.statusFilters,
    );

    final statusOptions = role == TradeRole.seller
        ? _sellerFilterGroups
        : _buyerFilterGroups;

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
              const SizedBox(height: 6),
              _Filters(
                options: statusOptions,
                selected: statusFilter,
                onSelected: vm.changeFilter,
              ),
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
                                    const SizedBox(height: 8),
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

class _StatusInfo {
  const _StatusInfo({
    required this.code,
    required this.label,
    required this.color,
  });

  final int code;
  final String label;
  final Color color;
}

class _StatusFilterGroup {
  const _StatusFilterGroup({required this.label, required this.codes});

  final String label;
  final List<int> codes;
}

//favorites처럼이부분도repository로빼는게맞겠음
// 즉시구매자는일단last_bid_user_id에바로기록되고즉시구매에실패하면이전의상위입찰자가last_bid_user_id가되는방식임
//판매자는 500번대>>300번대
//auctions에서auction_status_code(300번대)trade_status_code(500번대)
//구매자는 500번대>>400번대
//auction_log_code(400번대)trade_status_code(500번대)
//auctions에서auction_status_code(300번대종료코드321/322),trade_status_code,auction_end_at,last_bid_user_id로종료/낙찰여부계산//즉시구매되었는데내가낙찰자가아니면패찰433(내가만든번호)
_StatusInfo? _statusInfoText(int code) {
  switch (code) {
    // case 300:
    //   return const _StatusInfo(code: 300, label: '경매대기', color: BorderColor);
    case 310:
      return const _StatusInfo(code: 310, label: '경매진행중', color: blueColor);
    case 311:
      return const _StatusInfo(code: 311, label: '즉시구매중', color: blueColor);
    case 321:
      return const _StatusInfo(
        code: 321,
        label: '낙찰종료',
        color: tradeSaleDoneColor,
      );
    case 322:
      return const _StatusInfo(
        code: 322,
        label: '즉시구매종료',
        color: tradeSaleDoneColor,
      );
    case 323:
      return const _StatusInfo(code: 323, label: '유찰', color: RedColor);
    // case 400:
    //   return const _StatusInfo(code: 400, label: '입찰대기', color: blueColor);
    case 410:
      return const _StatusInfo(code: 410, label: '경매진행중', color: blueColor);
    case 411:
      return const _StatusInfo(code: 411, label: '상위입찰', color: blueColor);
    case 420:
      return const _StatusInfo(code: 420, label: '즉시구매시도', color: blueColor);
    case 421:
      return const _StatusInfo(
        code: 421,
        label: '즉시구매성공',
        color: tradeSaleDoneColor,
      );
    case 422:
      return const _StatusInfo(
        code: 422,
        label: '즉시구매실패',
        color: tradeBlockedColor,
      );
    case 430:
      return const _StatusInfo(
        code: 430,
        label: '낙찰종료',
        color: tradeSaleDoneColor,
      );
    case 431:
      return const _StatusInfo(
        code: 431,
        label: '즉시구매종료',
        color: tradeSaleDoneColor,
      );
    case 432:
      return const _StatusInfo(code: 432, label: '유찰', color: RedColor);
    case 433:
      return const _StatusInfo(code: 433, label: '패찰', color: RedColor);
    case 510:
      return const _StatusInfo(
        code: 510,
        label: '결제대기',
        color: tradeSaleDoneColor,
      );
    case 520:
      return const _StatusInfo(
        code: 520,
        label: '결제완료',
        color: tradePurchaseDoneColor,
      );
    case 530:
      return const _StatusInfo(
        code: 530,
        label: '결제실패',
        color: tradeBlockedColor,
      );
    case 540:
      return const _StatusInfo(
        code: 540,
        label: '거래취소',
        color: tradeBlockedColor,
      );
    case 550:
      return const _StatusInfo(
        code: 550,
        label: '거래완료',
        color: tradePurchaseDoneColor,
      );
    default:
      return _StatusInfo(code: code, label: '$code', color: tradeBlockedColor);
  }
}

const List<_StatusFilterGroup> _sellerFilterGroups = [
  _StatusFilterGroup(label: '진행중', codes: [310, 311]),
  _StatusFilterGroup(label: '종료', codes: [321, 322]),
  _StatusFilterGroup(label: '유찰', codes: [323]),
  _StatusFilterGroup(label: '결제중', codes: [510, 520, 530]),
  _StatusFilterGroup(label: '거래완료', codes: [550]),
  _StatusFilterGroup(label: '거래취소', codes: [540]),
];

const List<_StatusFilterGroup> _buyerFilterGroups = [
  _StatusFilterGroup(label: '진행중', codes: [410, 411, 420, 421, 422]),
  _StatusFilterGroup(label: '종료', codes: [430, 431]),
  _StatusFilterGroup(label: '패찰', codes: [432, 433]),
  _StatusFilterGroup(label: '결제중', codes: [510, 520, 530]),
  _StatusFilterGroup(label: '거래완료', codes: [550]),
  _StatusFilterGroup(label: '거래취소', codes: [540]),
];

class _Filters extends StatelessWidget {
  const _Filters({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<_StatusFilterGroup> options;
  final List<int>? selected;
  final ValueChanged<List<int>> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = listEquals(selected, option.codes);
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ChoiceChip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: Text(option.label),
              selected: isSelected,
              onSelected: (_) => onSelected(option.codes),
              showCheckmark: false,
              selectedColor: blueColor.withValues(alpha: 0.1),
              labelStyle: TextStyle(color: isSelected ? blueColor : textColor),
              backgroundColor: Colors.white,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected
                      ? blueColor.withValues(alpha: 0.5)
                      : BorderColor.withValues(alpha: 0.5),
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

  final TradeHistoryEntity item;

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfoText(item.statusCode);

    final labelText = statusInfo?.label ?? '';

    final hasImage = item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty;

    final priceLabel = item.role == TradeRole.buyer
        ? '내 입찰가'
        : '최고입찰가'; //item.currentPrice 다르게나와서수정함

    return GestureDetector(
      onTap: () {
        if (item.itemId.isNotEmpty) {
          context.push('/item/${item.itemId}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white, //앱칼라가없어서그냥이렇게씀,
          borderRadius: defaultBorder,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: defaultBorder,
              child: Container(
                width: 80,
                height: 80,
                color: ImageBackgroundColor,
                child: hasImage
                    ? CachedNetworkImage(
                        imageUrl: item.thumbnailUrl!,
                        cacheManager: ItemImageCacheManager.instance,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.image_outlined, color: iconColor),
                      )
                    : const Icon(Icons.image_outlined, color: iconColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusInfo!.color.withValues(alpha: 0.1),
                          borderRadius: defaultBorder,
                        ),
                        child: Text(
                          statusInfo.label,
                          style: TextStyle(color: statusInfo.color),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (item.currentPrice > 0)
                    Text(
                      '$priceLabel ${item.currentPrice.toCommaString()}원',
                      style: TextStyle(fontSize: 14, color: textColor),
                    )
                  else if (labelText.contains('유찰') || item.currentPrice <= 0)
                    const SizedBox(height: 14),

                  const SizedBox(height: 4),
                  if (item.buyNowPrice != null && item.buyNowPrice! > 0)
                    Text(
                      '즉시구매가 ${item.buyNowPrice!.toCommaString()}원',
                      style: TextStyle(fontSize: 14, color: BorderColor),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
