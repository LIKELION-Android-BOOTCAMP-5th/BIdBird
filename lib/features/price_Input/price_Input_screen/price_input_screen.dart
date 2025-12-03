import 'package:bidbird/core/utils/ui_set/border_radius.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/features/item_detail/data/item_detail_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../price_Input_viewmodel/price_input_viewmodel.dart';

class BidBottomSheet extends StatefulWidget {
  const BidBottomSheet({super.key, required this.itemId});

  final String itemId;

  @override
  State<BidBottomSheet> createState() => _BidBottomSheetState();
}

class _BidBottomSheetState extends State<BidBottomSheet> {
  // TODO: 실제 itemId를 기반으로 상세 데이터를 가져오도록 수정
  late final ItemDetail _item = dummyItemDetail;

  late int _bidAmount;

  @override
  void initState() {
    super.initState();
    // 기본 입찰 금액: 현재 가격 + 1회 호가
    _bidAmount = _item.currentPrice + _item.bidPrice;
  }

  void _increaseBid() {
    setState(() {
      final next = _bidAmount + _item.bidPrice;
      // 즉시 구매가를 상한선으로 제한
      if (next <= _item.buyNowPrice) {
        _bidAmount = next;
      }
    });
  }

  void _decreaseBid() {
    setState(() {
      final minBid = _item.currentPrice + _item.bidPrice;
      final next = _bidAmount - _item.bidPrice;
      if (next >= minBid) {
        _bidAmount = next;
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

    return Padding(
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
                          '${_formatPrice(_item.currentPrice)}원',
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
                          _formatBidUnit(_item.bidPrice),
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
                // 입찰 금액 표시 (좌우 끝까지)
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
                  : () {
                      final vm = context.read<PriceInputViewModel>();
                      vm.placeBid(
                        context,
                        itemId: widget.itemId,
                        bidPrice: _bidAmount,
                      );
                    },
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
    );
  }
}
