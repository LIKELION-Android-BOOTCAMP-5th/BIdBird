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
    // required this.buyNowPrice,
  });

  final String itemId;
  final int currentPrice;
  final int bidUnit;
  // final int? buyNowPrice;

  @override
  State<BidBottomSheet> createState() => _BidBottomSheetState();
}

class _BidInfoSummary extends StatelessWidget {
  const _BidInfoSummary({
    required this.currentPrice,
    required this.bidUnitLabel,
  });

  final int currentPrice;
  final String bidUnitLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현재 최고가',
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatPrice(currentPrice)}원',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '호가',
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bidUnitLabel,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: blueColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.displayCurrentPrice,
    required this.bidUnitLabel,
    required this.statusMessage,
    required this.isValidStatus,
    required this.canSubmit,
    required this.isSubmitting,
    required this.onClose,
    required this.onSubmit,
    required this.buildBidStepper,
    required this.quickPresetRow,
  });

  final int displayCurrentPrice;
  final String bidUnitLabel;
  final String statusMessage;
  final bool isValidStatus;
  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onClose;
  final VoidCallback? onSubmit;
  final Widget Function() buildBidStepper;
  final Widget quickPresetRow;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '입찰하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _BidInfoSummary(
          currentPrice: displayCurrentPrice,
          bidUnitLabel: bidUnitLabel,
        ),
        const SizedBox(height: 20),
        buildBidStepper(),
        const SizedBox(height: 12),
        quickPresetRow,
        const SizedBox(height: 16),
        _BidStatusMessage(
          isValid: isValidStatus,
          statusText: statusMessage,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: blueColor,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(defaultRadius),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '입찰하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _PresetAction {
  const _PresetAction(this.label, this.value, this.type);

  final String label;
  final int value;
  final _PresetActionType type;
}

enum _PresetActionType { adjust, reset }

class _PriceInfo {
  const _PriceInfo(this.currentPrice, this.bidUnit);

  final int currentPrice;
  final int bidUnit;
}

class _BidStepperCard extends StatelessWidget {
  const _BidStepperCard({
    required this.bidAmount,
    required this.bidUnitLabel,
    required this.onIncrease,
    required this.onDecrease,
    required this.canDecrease,
    required this.canIncrease,
    required this.amountFontSize,
  });

  final int bidAmount;
  final String bidUnitLabel;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final bool canDecrease;
  final bool canIncrease;
  final double amountFontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(defaultRadius),
        border: Border.all(color: const Color(0xFFD7E3FF), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade50.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '입찰 금액',
            style: TextStyle(
              fontSize: 13,
              color: blueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StepperButton(
                icon: Icons.remove,
                onPressed: canDecrease ? onDecrease : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${formatPrice(bidAmount)}원',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: amountFontSize,
                        fontWeight: FontWeight.w800,
                        color: blueColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StepperButton(
                icon: Icons.add,
                onPressed: canIncrease ? onIncrease : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isEnabled ? const Color(0xFFD7E3FF) : Colors.grey.shade200,
            width: 1.2,
          ),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isEnabled ? textColor : Colors.grey.shade500,
        ),
      ),
    );
  }
}

class _QuickPresetRow extends StatelessWidget {
  const _QuickPresetRow({
    required this.actions,
    required this.onAdjust,
    required this.onResetMin,
  });

  final List<_PresetAction> actions;
  final void Function(int) onAdjust;
  final VoidCallback onResetMin;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final action in actions)
          _buildChip(
            action.label,
            action.type == _PresetActionType.adjust
                ? () => onAdjust(action.value)
                : onResetMin,
          ),
      ],
    );
  }

  Widget _buildChip(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        backgroundColor: const Color(0xFFF2F3F6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        foregroundColor: textColor,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Text(label),
    );
  }
}

class _BidStatusMessage extends StatelessWidget {
  const _BidStatusMessage({
    required this.isValid,
    required this.statusText,
  });

  final bool isValid;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final color = isValid ? Colors.green : Colors.red;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.error_outline,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _BidBottomSheetState extends State<BidBottomSheet> {
  late int _bidAmount;
  late int _currentPrice;
  late int _bidUnit;
  ItemDetailViewModel? _itemDetailViewModel;

  static const List<_PresetAction> _presetActions = [
    _PresetAction('+1호가', 1, _PresetActionType.adjust),
    _PresetAction('+3호가', 3, _PresetActionType.adjust),
    _PresetAction('+5호가', 5, _PresetActionType.adjust),
    _PresetAction('최소가', 0, _PresetActionType.reset),
  ];

  int get _minNextBid => _currentPrice + _bidUnit;

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
      _bidAmount = _clampBid(next);
    });
  }

  void _decreaseBid() {
    setState(() {
      final next = _bidAmount - _bidUnit;
      _bidAmount = _clampBid(next);
    });
  }

  void _adjustBidBySteps(int stepCount) {
    if (stepCount == 0) return;
    setState(() {
      final next = _bidAmount + (_bidUnit * stepCount);
      _bidAmount = _clampBid(next);
    });
  }

  void _setBidToMinimum() {
    setState(() {
      _bidAmount = _minNextBid;
    });
  }

  int _clampBid(int value) {
    var next = value;
    if (next < _minNextBid) {
      next = _minNextBid;
    }
    // if (widget.buyNowPrice > 0 && next > widget.buyNowPrice) {
    //   next = widget.buyNowPrice;
    // }
    return next;
  }

  String _formatBidUnit(int price) {
    return '${formatPrice(price)}원';
  }

  /// 10만 원 이상이면 금액은 그대로 두고 폰트 크기만 축소
  double _getBidAmountFontSize(int amount) {
    const baseSize = 36.0;
    if (amount >= 100000) {
      return baseSize * 0.7;
    }
    return baseSize;
  }

  @override
  Widget build(BuildContext context) {
    // isSubmitting만 watch하여 불필요한 리빌드 방지
    return Selector<PriceInputViewModel, bool>(
      selector: (_, vm) => vm.isSubmitting,
      builder: (context, isSubmitting, _) {
        final viewModel = context.read<PriceInputViewModel>();
        final priceInfo =
            context.select<ItemDetailViewModel?, _PriceInfo?>((vm) {
          final detail = vm?.itemDetail;
          if (detail == null) return null;
          return _PriceInfo(detail.currentPrice, detail.bidPrice);
        });

        final displayCurrentPrice =
            priceInfo?.currentPrice ?? _currentPrice;
        final displayBidUnit = priceInfo?.bidUnit ?? _bidUnit;
        final displayBidUnitLabel = _formatBidUnit(displayBidUnit);
        final bidAmountFontSize = _getBidAmountFontSize(_bidAmount);

        final minBid = _minNextBid;
        final isBelowMinBid = _bidAmount < minBid;
        // final exceedsBuyNow =
        //     widget.buyNowPrice > 0 && _bidAmount > widget.buyNowPrice;
        // final isValidBid = !isBelowMinBid && !exceedsBuyNow;
        final isValidBid = !isBelowMinBid;
        final canSubmit = isValidBid && !isSubmitting;

        // final statusMessage = isBelowMinBid
        //     ? '최소 ${formatPrice(minBid)}원부터 가능합니다'
        //     : exceedsBuyNow
        //         ? '즉시 구매가를 초과할 수 없습니다'
        //         : '유효한 입찰입니다';
        final statusMessage = isBelowMinBid
            ? '최소 ${formatPrice(minBid)}원부터 가능합니다'
            : '유효한 입찰입니다';

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            color: Colors.white,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: _SheetBody(
                  displayCurrentPrice: displayCurrentPrice,
                  bidUnitLabel: displayBidUnitLabel,
                  statusMessage: statusMessage,
                  isValidStatus: isValidBid,
                  canSubmit: canSubmit,
                  isSubmitting: isSubmitting,
                  onClose: () => Navigator.pop(context),
                  onSubmit: canSubmit
                      ? () => _showConfirmDialog(context, viewModel)
                      : null,
                  buildBidStepper: () => _BidStepperCard(
                    bidAmount: _bidAmount,
                    bidUnitLabel: displayBidUnitLabel,
                    onIncrease: _increaseBid,
                    onDecrease: _decreaseBid,
                    canDecrease: _bidAmount > minBid,
                    // canIncrease: widget.buyNowPrice <= 0
                    //     ? true
                    //     : _bidAmount < widget.buyNowPrice,
                    canIncrease: true,
                    amountFontSize: bidAmountFontSize,
                  ),
                  quickPresetRow: _QuickPresetRow(
                    actions: _presetActions,
                    onAdjust: _adjustBidBySteps,
                    onResetMin: _setBidToMinimum,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        foregroundColor: textColor,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Text(label),
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

            // 상세 화면 강제 새로고침 (캐시 무시)
            final detailViewModel =
                parentContext.read<ItemDetailViewModel?>();
            if (detailViewModel != null) {
              // 입찰 성공 후 즉시 isTopBidder를 true로 설정 (실시간 업데이트로 최종 확인)
              // 이렇게 하면 UI가 즉시 업데이트되고, 실시간 업데이트로 정확한 값이 반영됨
              await detailViewModel.loadItemDetail(forceRefresh: true);
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

