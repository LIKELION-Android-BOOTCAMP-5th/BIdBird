import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/bid/presentation/viewmodels/price_input_viewmodel.dart';
import 'package:bidbird/features/bid/presentation/widgets/blocks/bid_loading_block.dart';
import 'package:bidbird/features/bid/presentation/widgets/cards/bid_info_summary_card.dart';
import 'package:bidbird/features/bid/presentation/widgets/cards/bid_status_message_card.dart';
import 'package:bidbird/features/bid/presentation/widgets/sections/bid_button_section.dart';
import 'package:bidbird/features/bid/presentation/widgets/sections/bid_price_stepper_section.dart';
import 'package:bidbird/features/bid/presentation/widgets/sections/bid_quick_preset_section.dart';
import 'package:bidbird/features/item_detail/detail/presentation/viewmodels/item_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';

class BidBottomSheet extends StatefulWidget {
  final String itemId;
  final int currentPrice;
  final int bidUnit;

  const BidBottomSheet({
    super.key,
    required this.itemId,
    required this.currentPrice,
    required this.bidUnit,
  });

  @override
  State<BidBottomSheet> createState() => _BidBottomSheetState();
}

class _BidBottomSheetState extends State<BidBottomSheet> {
  late int _bidAmount;
  late int _currentPrice;
  late int _bidUnit;
  ItemDetailViewModel? _itemDetailViewModel;
  final ScrollController _scrollController = ScrollController();

  static const List<BidPresetAction> _presetActions = [
    BidPresetAction('+1호가', 1, BidPresetActionType.adjust),
    BidPresetAction('+3호가', 3, BidPresetActionType.adjust),
    BidPresetAction('+5호가', 5, BidPresetActionType.adjust),
    BidPresetAction('최소가', 0, BidPresetActionType.reset),
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
    ItemDetailViewModel? newViewModel;
    try {
      newViewModel = Provider.of<ItemDetailViewModel>(context, listen: false);
    } catch (e) {
      // Provider 없으면 무시
    }

    if (newViewModel != _itemDetailViewModel) {
      _itemDetailViewModel?.removeListener(_handlePriceUpdate);
      _itemDetailViewModel = newViewModel;
      _itemDetailViewModel?.addListener(_handlePriceUpdate);
    }
  }

  @override
  void dispose() {
    _itemDetailViewModel?.removeListener(_handlePriceUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePriceUpdate() {
    if (!mounted || _itemDetailViewModel?.itemDetail == null) return;

    final newCurrentPrice = _itemDetailViewModel!.itemDetail!.currentPrice;
    final newBidPrice = _itemDetailViewModel!.itemDetail!.bidPrice;

    if (newCurrentPrice != _currentPrice || newBidPrice != _bidUnit) {
      setState(() {
        _currentPrice = newCurrentPrice;
        _bidUnit = newBidPrice;
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
    return value < _minNextBid ? _minNextBid : value;
  }

  String _formatBidUnit(int price) {
    return '${formatPrice(price)}원';
  }

  double _getBidAmountFontSize(int amount) {
    const baseSize = 36.0;
    return amount >= 100000 ? baseSize * 0.7 : baseSize;
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PriceInputViewModel, bool>(
      selector: (_, vm) => vm.isSubmitting,
      builder: (context, isSubmitting, _) {
        final viewModel = context.read<PriceInputViewModel>();
        final priceInfo = context.select<ItemDetailViewModel?, _PriceInfo?>((vm) {
          final detail = vm?.itemDetail;
          if (detail == null) return null;
          return _PriceInfo(detail.currentPrice, detail.bidPrice);
        });

        final displayCurrentPrice = priceInfo?.currentPrice ?? _currentPrice;
        final displayBidUnit = priceInfo?.bidUnit ?? _bidUnit;
        final displayBidUnitLabel = _formatBidUnit(displayBidUnit);
        final bidAmountFontSize = _getBidAmountFontSize(_bidAmount);

        final minBid = _minNextBid;
        final isBelowMinBid = _bidAmount < minBid;
        final isValidBid = !isBelowMinBid;
        final canSubmit = isValidBid && !isSubmitting;

        final statusMessage =
            isBelowMinBid ? '유효하지 않은 입찰입니다' : '유효한 입찰입니다';

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            color: chatItemCardBackground,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.hPadding,
                  context.spacingSmall,
                  context.hPadding,
                  context.spacingMedium * 0.5,
                ),
                child: isSubmitting
                    ? BidLoadingBlock(onClose: () => Navigator.pop(context))
                    : SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                        child: _buildContentView(
                          context,
                          viewModel,
                          displayCurrentPrice,
                          displayBidUnitLabel,
                          statusMessage,
                          isValidBid,
                          canSubmit,
                          isSubmitting,
                          minBid,
                          bidAmountFontSize,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentView(
    BuildContext context,
    PriceInputViewModel viewModel,
    int displayCurrentPrice,
    String displayBidUnitLabel,
    String statusMessage,
    bool isValidBid,
    bool canSubmit,
    bool isSubmitting,
    int minBid,
    double bidAmountFontSize,
  ) {
    return Column(
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
        Expanded(
          child: ListView(
            controller: _scrollController,
            primary: false,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              BidInfoSummaryCard(
                currentPrice: displayCurrentPrice,
                bidUnitLabel: displayBidUnitLabel,
              ),
              const SizedBox(height: 20),
              BidPriceStepperSection(
                bidAmount: _bidAmount,
                bidUnitLabel: displayBidUnitLabel,
                onIncrease: _increaseBid,
                onDecrease: _decreaseBid,
                canDecrease: _bidAmount > minBid,
                canIncrease: true,
                amountFontSize: bidAmountFontSize,
              ),
              const SizedBox(height: 12),
              BidQuickPresetSection(
                actions: _presetActions,
                onAdjust: _adjustBidBySteps,
                onResetMin: _setBidToMinimum,
              ),
              const SizedBox(height: 16),
              BidStatusMessageCard(
                isValid: isValidBid,
                statusText: statusMessage,
              ),
              const SizedBox(height: 20),
              BidButtonSection(
                canSubmit: canSubmit,
                isSubmitting: isSubmitting,
                onClose: () => Navigator.pop(context),
                onSubmit: canSubmit
                    ? () => _showConfirmDialog(context, viewModel)
                    : null,
              ),
            ],
          ),
        ),
      ],
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
      builder: (_) => const Center(
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
      await viewModel.Temporary_bid(
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
            if (!parentContext.mounted) return;

            final detailViewModel =
                parentContext.read<ItemDetailViewModel?>();
            if (detailViewModel != null) {
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

class _PriceInfo {
  final int currentPrice;
  final int bidUnit;

  _PriceInfo(this.currentPrice, this.bidUnit);
}
