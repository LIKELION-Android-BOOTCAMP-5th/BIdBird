import 'package:bidbird/core/utils/ui_set/border_radius.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../price_Input_viewmodel/price_input_viewmodel.dart';

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

  @override
  void initState() {
    super.initState();
    _bidAmount = widget.currentPrice + widget.bidUnit;
  }

  void _increaseBid() {
    debugPrint('[BidBottomSheet] _increaseBid called, bidUnit: ${widget.bidUnit}');
    debugPrint('[BidBottomSheet] _increaseBid: before _bidAmount: $_bidAmount');
    
    setState(() {
      final next = _bidAmount + widget.bidUnit;
      debugPrint('[BidBottomSheet] _increaseBid: _bidAmount: $_bidAmount, next: $next, buyNowPrice: ${widget.buyNowPrice}');

      if (widget.buyNowPrice > 0 && next > widget.buyNowPrice) {
        debugPrint('[BidBottomSheet] _increaseBid: next > buyNowPrice, not updating');
      } else {
        _bidAmount = next;
        debugPrint('[BidBottomSheet] _increaseBid: updated _bidAmount to $_bidAmount');
      }
    });
    
    debugPrint('[BidBottomSheet] _increaseBid: after _bidAmount: $_bidAmount');
  }

  void _decreaseBid() {
    debugPrint('[BidBottomSheet] _decreaseBid called, bidUnit: ${widget.bidUnit}');
    setState(() {
      final minBid = widget.currentPrice + widget.bidUnit;
      final next = _bidAmount - widget.bidUnit;
      debugPrint('[BidBottomSheet] _decreaseBid: _bidAmount: $_bidAmount, next: $next, minBid: $minBid');
      if (next >= minBid) {
        _bidAmount = next;
        debugPrint('[BidBottomSheet] _decreaseBid: updated _bidAmount to $_bidAmount');
      } else {
        debugPrint('[BidBottomSheet] _decreaseBid: next < minBid, not updating');
      }
    });
  }

  String _formatPrice(int price) {
    final buffer = StringBuffer();
    final text = price.toString();
    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1 && i != text.length - 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  String _formatBidUnit(int price) {
    if (price % 10000 == 0) {
      final unit = price ~/ 10000;
      return '$unit만원';
    }
    return '${_formatPrice(price)}원';
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
          const Center(
            child: Text(
              '입찰하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xffF8F8FA),
              borderRadius: defaultBorder,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '현재 가격',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatPrice(widget.currentPrice)}원',
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
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatBidUnit(widget.bidUnit),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatPrice(_bidAmount)}원',
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
                // 아래쪽 전체 폭 네모 버튼 (- / +)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _decreaseBid,
                        borderRadius: BorderRadius.circular(defaultRadius),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xffF2F3F7),
                            borderRadius: BorderRadius.circular(defaultRadius),
                          ),
                          child: const Center(
                            child: Text(
                              '-',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _increaseBid,
                        borderRadius: BorderRadius.circular(defaultRadius),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xffF2F3F7),
                            borderRadius: BorderRadius.circular(defaultRadius),
                          ),
                          child: const Center(
                            child: Text(
                              '+',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
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
                '입찰 확정',
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

  void _showConfirmDialog(BuildContext parentContext, PriceInputViewModel viewModel) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AskPopup(
        content: '${_formatPrice(_bidAmount)}원에 입찰하시겠습니까?',
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
      BuildContext parentContext, PriceInputViewModel viewModel) async {

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
      await viewModel.placeBid(
        itemId: widget.itemId,
        bidPrice: _bidAmount,
      );

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
