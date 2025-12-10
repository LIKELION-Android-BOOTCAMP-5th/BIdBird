import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../bottom_sheet_buy_now_input/data/repository/bid_restriction_gateway_impl.dart';
import '../../../bottom_sheet_buy_now_input/model/check_bid_restriction_usecase.dart';
import '../../../bottom_sheet_buy_now_input/screen/bottom_sheet_buy_now_input.dart';
import '../../../bottom_sheet_buy_now_input/viewmodel/buy_now_input_viewmodel.dart';
import '../../../bottom_sheet_price_Input/screen/price_input_screen.dart';
import '../../../bottom_sheet_price_Input/viewmodel/price_input_viewmodel.dart';
import '../../../identity_verification/data/repository/identity_verification_gateway_impl.dart';
import '../../../item_bid_win/model/item_bid_win_entity.dart';
import '../../../item_bid_win/screen/item_bid_win_screen.dart';
import '../../../../../core/widgets/components/pop_up/ask_popup.dart';
import '../../model/item_detail_entity.dart';
import '../../viewmodel/item_detail_viewmodel.dart';

class ItemBottomActionBar extends StatefulWidget {
  const ItemBottomActionBar({
    required this.item,
    required this.isMyItem,
    super.key,
  });

  final ItemDetail item;
  final bool isMyItem;

  @override
  State<ItemBottomActionBar> createState() => _ItemBottomActionBarState();
}

class _ItemBottomActionBarState extends State<ItemBottomActionBar> {
  int? _statusCode;
  bool _isBidRestricted = false;

  final CheckBidRestrictionUseCase _checkBidRestrictionUseCase =
      CheckBidRestrictionUseCase(BidRestrictionGatewayImpl());

  Future<bool> _ensureIdentityVerified() async {
    final gateway = IdentityVerificationGatewayImpl();
    final ctx = context;

    // 1. 먼저 서버에서 CI 존재 여부 확인 (BuildContext 사용 없음)
    try {
      final hasCi = await gateway.hasCi();
      if (hasCi) {
        // 이미 CI 가 있으면 팝업/본인인증 없이 바로 통과
        return true;
      }
    } catch (e) {
      // CI 조회 실패 시에는 아래 본인인증 플로우로 유도
    }

    bool proceed = false;

    // 2. CI 가 없을 때만 AskPopup 으로 본인인증 안내
    await showDialog<void>(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AskPopup(
          content: '입찰 및 즉시 구매를 위해서는 본인 인증이 필요합니다.\n지금 본인 인증을 진행하시겠습니까?',
          noText: '취소',
          yesText: '확인',
          yesLogic: () async {
            proceed = true;
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );

    if (!proceed) {
      return false;
    }

    try {
      final success = await gateway.requestIdentityVerification(ctx);
      if (!ctx.mounted) {
        return false;
      }
      if (!success) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('본인 인증 후 이용 가능합니다.'),
          ),
        );
      }
      return success;
    } catch (e) {
      if (!ctx.mounted) {
        return false;
      }
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('본인 인증 상태를 확인하지 못했습니다. 잠시 후 다시 시도해주세요.\n$e'),
        ),
      );
      return false;
    }
    // 모든 경로가 값을 반환하도록 안전망
    // (정상 흐름에서는 도달하지 않음)
    // ignore: dead_code
    return false;
  }

  @override
  void initState() {
    super.initState();
    _statusCode = widget.item.statusCode;
    _checkBidRestriction();
  }

  Future<void> _checkBidRestriction() async {
    try {
      final isBlocked = await _checkBidRestrictionUseCase();
      if (!mounted) return;

      setState(() {
        _isBidRestricted = isBlocked;
      });
    } catch (e) {
      debugPrint('Failed to check bid restriction: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemDetailViewModel = context.watch<ItemDetailViewModel?>();
    final isFavorite = itemDetailViewModel?.isFavorite ?? false;
    final isTopBidder = itemDetailViewModel?.isTopBidder ?? false;
    final isMyItem = widget.isMyItem;
    final isBidRestricted = _isBidRestricted;
    final bool isTimeOver = DateTime.now().isAfter(widget.item.finishTime);

    const disabledStatusesForBuyNow = {
      300,
      311,
      321,
      322,
      323,
    };
    final bool showBuyNow =
        widget.item.buyNowPrice > 0 &&
        !disabledStatusesForBuyNow.contains(_statusCode) &&
        !isTimeOver;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(defaultRadius),
          topRight: Radius.circular(defaultRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // 결제 실패 3회 이상으로 입찰 제한된 경우: 안내 문구만 전체 폭으로 노출 (하트 없음)
          if (!isMyItem && isBidRestricted) ...[
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: BackgroundColor,
                  borderRadius: BorderRadius.circular(8.7),
                  border: Border.all(color: BorderColor),
                ),
                child: const Center(
                  child: Text(
                    '결제 3회 이상 실패하여 입찰이 제한되었습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          ]
          // 일반 사용자: 하트 + 입찰/즉시구매 버튼
          else if (!isMyItem) ...[
            _buildFavoriteButton(isFavorite, itemDetailViewModel),
            const SizedBox(width: 12),
            Expanded(child: _buildBidButton(isTopBidder)),
            if (showBuyNow) ...[
              const SizedBox(width: 8),
              Expanded(child: _buildBuyNowButton()),
            ],
          ] else ...[
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: BackgroundColor,
                  borderRadius: BorderRadius.circular(8.7),
                  border: Border.all(color: BorderColor),
                ),
                child: const Center(
                  child: Text(
                    '내 매물은 입찰이 불가능합니다',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TopBidderTextColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(
    bool isFavorite,
    ItemDetailViewModel? itemDetailViewModel,
  ) {
    return InkWell(
      onTap: () {
        itemDetailViewModel?.toggleFavorite();
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: BorderColor),
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : iconColor,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildBidButton(bool isTopBidder) {
    final int statusCode = _statusCode ?? 0;

    final bool isTimeOver = DateTime.now().isAfter(widget.item.finishTime);

    final bool isAuctionEnded = isTimeOver ||
        statusCode == 321 ||
        statusCode == 322 ||
        statusCode == 323;

    final bool isAuctionActive = statusCode == 310;
    final bool isBuyNowInProgress = statusCode == 311;
    final bool isBuyNowCompleted = statusCode == 322;

    final bool showBidButton =
        !isAuctionEnded &&
        isAuctionActive &&
        !isTopBidder &&
        !isBuyNowInProgress;

    // 경매가 완전히 끝난 상태(유찰/즉시구매 완료 등)
    if (isAuctionEnded && statusCode != 321) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: BackgroundColor,
          borderRadius: BorderRadius.circular(8.7),
          border: Border.all(color: BorderColor),
        ),
        child: const Center(
          child: Text(
            '경매가 종료되었습니다.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TopBidderTextColor,
            ),
          ),
        ),
      );
    }

    // 경매 낙찰(321) 상태에서, 내가 낙찰자인 경우 결제 버튼 노출
    // 현재 화면의 ViewModel 에서 isTopBidder 가 true 인 상태를 낙찰자로 간주
    if (statusCode == 321 && isTopBidder) {
      return ElevatedButton(
        onPressed: () {
          // TODO: 결제 화면으로 이동하는 로직 연동
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: blueColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.7),
          ),
        ),
        child: const Text(
          '결제하러 가기',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    }

    // 즉시 구매 진행 중(1006)인 경우
    // - 즉시 구매를 건 사용자(현재 최고 입찰자)는 '결제하러 가기' 버튼 노출
    // - 그 외 사용자는 안내 문구만 노출
    if (isBuyNowInProgress && !isBuyNowCompleted) {
      if (isTopBidder) {
        return ElevatedButton(
          onPressed: () {
            debugPrint('[ItemBottomActionBar] 결제하러 가기 버튼 탭');
            // TODO: 결제 화면으로 이동하는 로직 연동
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: blueColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.7),
            ),
          ),
          child: const Text(
            '결제하러 가기',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        );
      }

      // 다른 사용자는 결제 대기 안내 문구만 표시
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: BackgroundColor,
          borderRadius: BorderRadius.circular(8.7),
          border: Border.all(color: BorderColor),
        ),
        child: const Center(
          child: Text(
            '즉시 구매 결제 대기중입니다',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TopBidderTextColor,
            ),
          ),
        ),
      );
    }

    if (isBuyNowCompleted) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: BackgroundColor,
          borderRadius: BorderRadius.circular(8.7),
          border: Border.all(color: BorderColor),
        ),
        child: const Center(
          child: Text(
            '즉시 구매되었습니다',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TopBidderTextColor,
            ),
          ),
        ),
      );
    }

    if (showBidButton) {
      return OutlinedButton(
        onPressed: () async {
          final passed = await _ensureIdentityVerified();
          if (!passed) return;
          if (!mounted) return;

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(defaultRadius),
              ),
            ),
            builder: (context) {
              return ChangeNotifierProvider<PriceInputViewModel>(
                create: (_) => PriceInputViewModel(),
                child: BidBottomSheet(
                  itemId: widget.item.itemId,
                  currentPrice: widget.item.currentPrice,
                  bidUnit: widget.item.bidPrice,
                  buyNowPrice: widget.item.buyNowPrice,
                ),
              );
            },
          );
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: blueColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.7),
          ),
        ),
        child: Text(
          '입찰하기',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: blueColor,
          ),
        ),
      );
    }

    // 입찰이 비활성화된 경우: 이유를 버튼 형태로 표시
    String reason;

    // 1) 이미 최고 입찰자인 경우
    if (isTopBidder) {
      reason = '최고 입찰자입니다';
    } else if (isTimeOver) {
      // 2) 경매 시간이 지난 경우
      reason = '경매가 종료되었습니다.';
    } else {
      // 3) 상태 코드별 상세 사유
      switch (statusCode) {
        case 300:
          reason = '경매가 아직 시작되지 않았습니다';
          break;
        case 321:
        case 323:
          reason = '경매가 종료되었습니다.';
          break;
        case 311:
          reason = '즉시 구매 결제 대기중입니다';
          break;
        case 322:
          reason = '즉시 구매되었습니다';
          break;
        default:
          reason = '현재 입찰할 수 없습니다';
          break;
      }
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: BackgroundColor,
        borderRadius: BorderRadius.circular(8.7),
        border: Border.all(color: BorderColor),
      ),
      child: Center(
        child: Text(
          reason,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: TopBidderTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBuyNowButton() {
    return ElevatedButton(
      onPressed: () async {
        final passed = await _ensureIdentityVerified();
        if (!passed) return;
        if (!mounted) return;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(defaultRadius),
            ),
          ),
          builder: (context) {
            return ChangeNotifierProvider<BuyNowInputViewModel>(
              create: (_) => BuyNowInputViewModel(),
              child: BuyNowInputBottomSheet(
                itemId: widget.item.itemId,
                buyNowPrice: widget.item.buyNowPrice,
              ),
            );
          },
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: blueColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.7)),
      ),
      child: const Text(
        '즉시 구매하기',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
