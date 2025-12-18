import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/item_detail/detail/presentation/viewmodels/item_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bidbird/features/bid/presentation/viewmodels/price_input_viewmodel.dart';

class BidBottomSheet extends StatefulWidget {
  const BidBottomSheet({
    super.key,
    required this.itemId,
    required this.currentPrice,
    required this.bidUnit,
    required this.buyNowPrice,
  });

  final String itemId;
  final int currentPrice;
  final int bidUnit;
  final int buyNowPrice;

  @override
  State<BidBottomSheet> createState() => _BidBottomSheetState();
}

class _BidBottomSheetState extends State<BidBottomSheet> {
  late int _bidAmount;
  late int _currentPrice;
  late int _bidUnit;
  ItemDetailViewModel? _itemDetailViewModel;

  @override
  void initState() {
    super.initState();
    _currentPrice = widget.currentPrice;
    _bidUnit = widget.bidUnit;
    _bidAmount = _currentPrice + _bidUnit;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ItemDetailViewModel 변경 감지를 위한 리스너 등록
    ItemDetailViewModel? newViewModel;
    try {
      newViewModel = Provider.of<ItemDetailViewModel>(context, listen: false);
    } catch (e) {
      // Provider가 없으면 무시
    }
    
    // ViewModel이 변경되었을 때만 리스너 재등록
    if (newViewModel != _itemDetailViewModel) {
      _itemDetailViewModel?.removeListener(_handlePriceUpdate);
      _itemDetailViewModel = newViewModel;
      _itemDetailViewModel?.addListener(_handlePriceUpdate);
    }
  }

  @override
  void dispose() {
    _itemDetailViewModel?.removeListener(_handlePriceUpdate);
    super.dispose();
  }

  void _handlePriceUpdate() {
    if (!mounted || _itemDetailViewModel?.itemDetail == null) return;
    
    final newCurrentPrice = _itemDetailViewModel!.itemDetail!.currentPrice;
    final newBidPrice = _itemDetailViewModel!.itemDetail!.bidPrice;
    
    // 현재 가격이 변경되었을 때만 업데이트
    if (newCurrentPrice != _currentPrice || newBidPrice != _bidUnit) {
      setState(() {
        final oldCurrentPrice = _currentPrice;
        _currentPrice = newCurrentPrice;
        _bidUnit = newBidPrice;
        
        // 현재 가격이 올라갔을 때, 입찰 금액이 최소 입찰가보다 낮으면 조정
        final minBid = _currentPrice + _bidUnit;
        if (_bidAmount < minBid) {
          _bidAmount = minBid;
        }
        // 현재 가격이 올라갔을 때, 기존 입찰 금액과의 차이를 유지하려면
        // (기존 입찰 금액 - 기존 현재 가격)을 유지
        else if (newCurrentPrice > oldCurrentPrice) {
          final priceDiff = _bidAmount - oldCurrentPrice;
          final newBidAmount = _currentPrice + priceDiff;
          // 최소 입찰가보다는 높아야 함
          _bidAmount = newBidAmount >= minBid ? newBidAmount : minBid;
        }
      });
    }
  }

  void _increaseBid() {
    setState(() {
      final next = _bidAmount + _bidUnit;

      if (widget.buyNowPrice > 0 && next > widget.buyNowPrice) {
        // 즉시 구매가보다 높으면 업데이트하지 않음
      } else {
        _bidAmount = next;
      }
    });
  }

  void _decreaseBid() {
    setState(() {
      final minBid = _currentPrice + _bidUnit;
      final next = _bidAmount - _bidUnit;
      if (next >= minBid) {
        _bidAmount = next;
      }
    });
  }

  String _formatBidUnit(int price) {
    // 100원 단위까지 버림
    final roundedPrice = (price ~/ 100) * 100;
    
    if (roundedPrice % ItemBidStepConstants.tenThousandUnit == 0) {
      final unit = roundedPrice ~/ ItemBidStepConstants.tenThousandUnit;
      return '$unit만원';
    }
    return '${formatPrice(roundedPrice)}원';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PriceInputViewModel>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '입찰하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: defaultBorder,
                boxShadow: [
                  BoxShadow(
                    color: shadowLow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: defaultBorder,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '현재 가격',
                              style: TextStyle(fontSize: 13, color: textColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formatPrice(_currentPrice)}원',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              '호가',
                              style: TextStyle(fontSize: 13, color: textColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatBidUnit(_bidUnit),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: RedColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(defaultRadius),
                        border: Border.all(color: blueColor, width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '입찰 금액',
                            style: TextStyle(fontSize: 12, color: blueColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${formatPrice(_bidAmount)}원',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: blueColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRoundBidButton('-', _decreaseBid),
                      _buildRoundBidButton('+', _increaseBid),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: viewModel.isSubmitting
                    ? null
                    : () => _showConfirmDialog(context, viewModel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                  ),
                ),
                child: const Text(
                  '입찰 확인',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundBidButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext parentContext,
    PriceInputViewModel viewModel,
  ) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AskPopup(
        content: '${formatPrice(_bidAmount)}원에 입찰하시겠습니까?',
        yesText: '확인',
        noText: '취소',
        yesLogic: () async {
          Navigator.pop(dialogContext);
          await _processBid(parentContext, viewModel);
        },
      ),
    );
  }

  Future<void> _processBid(
    BuildContext parentContext,
    PriceInputViewModel viewModel,
  ) async {
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(blueColor),
          ),
        ),
      ),
    );

    try {
      await viewModel.placeBid(itemId: widget.itemId, bidPrice: _bidAmount);

      if (!parentContext.mounted) return;
      Navigator.pop(parentContext);

      if (!parentContext.mounted) return;
      await showDialog(
        context: parentContext,
        barrierDismissible: false,
        builder: (dialogContext) => AskPopup(
          content: '입찰이 완료되었습니다.',
          yesText: '확인',
          yesLogic: () async {
            Navigator.pop(dialogContext);
            if (!parentContext.mounted) return;

            // 상세 화면 강제 새로고침
            final detailViewModel =
                parentContext.read<ItemDetailViewModel?>();
            if (detailViewModel != null) {
              await detailViewModel.loadItemDetail();
            }

            if (parentContext.mounted) {
              Navigator.pop(parentContext);
            }
          },
        ),
      );
    } catch (e) {
      if (parentContext.mounted) {
        Navigator.pop(parentContext);

        showDialog(
          context: parentContext,
          builder: (dialogContext) => AskPopup(
            content: '오류가 발생했습니다.\n$e',
            yesText: '확인',
            yesLogic: () async {
              Navigator.pop(dialogContext);
            },
          ),
        );
      }
    }
  }
}

