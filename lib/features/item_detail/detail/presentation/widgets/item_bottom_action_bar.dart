import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/item/components/buttons/primary_button.dart';
import 'package:bidbird/core/widgets/item/components/buttons/secondary_button.dart';
import 'package:bidbird/features/chat/presentation/screens/chatting_room_screen.dart';
import 'package:bidbird/features/payment/payment_complete/presentation/screens/payment_complete_screen.dart';
import 'package:bidbird/features/payment/portone_payment/domain/entities/item_payment_request_entity.dart';
import 'package:bidbird/features/payment/portone_payment/presentation/screens/portone_payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bidbird/features/identity_verification/presentation/utils/identity_verification_helper.dart';
import 'package:bidbird/features/bid/presentation/widgets/buy_now_input_bottom_sheet.dart';
import 'package:bidbird/features/bid/presentation/widgets/bid_bottom_sheet.dart';
import 'package:bidbird/features/bid/presentation/viewmodels/buy_now_input_viewmodel.dart';
import 'package:bidbird/features/bid/presentation/viewmodels/price_input_viewmodel.dart';
import 'package:bidbird/features/bid/domain/entities/item_bid_win_entity.dart';
import 'package:bidbird/features/bid/presentation/screens/item_bid_win_screen.dart';
import 'package:bidbird/features/item_trade/seller_payment_complete/presentation/screens/seller_payment_complete_screen.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/item_trade/shipping/presentation/widgets/shipping_info_input_popup.dart';
import 'package:bidbird/features/item_trade/shipping/presentation/widgets/shipping_info_view_popup.dart';
import 'package:bidbird/features/item_trade/shipping/data/repositories/shipping_info_repository.dart';
import 'package:bidbird/features/item_trade/shipping/domain/repositories/shipping_info_repository.dart' as domain;
import 'package:bidbird/core/utils/item/trade_status_codes.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/viewmodels/item_detail_viewmodel.dart';
import 'package:bidbird/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:bidbird/features/bid/domain/usecases/check_bid_restriction_usecase.dart';
import 'package:bidbird/features/bid/data/repositories/bid_repository.dart';
import 'package:bidbird/features/item_trade/payment_info/presentation/widgets/payment_info_input_popup.dart';
import 'package:bidbird/features/item_trade/payment_info/data/datasources/offline_payment_datasource.dart';
import 'package:bidbird/features/item_trade/payment_info/presentation/widgets/payment_info_view_popup.dart';

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
  bool _hasShownRelistPopup = false;
  bool _hasShownPaymentCompleteScreen = false;
  bool? _hasShippingInfo;
  bool? _hasShippingInfoForSeller;

  final CheckBidRestrictionUseCase _checkBidRestrictionUseCase =
      CheckBidRestrictionUseCase(BidRepositoryImpl());
  final domain.ShippingInfoRepository _shippingInfoRepository = ShippingInfoRepositoryImpl();

  Future<bool> _ensureIdentityVerified() async {
    if (!mounted) return false;
    // TODO: 사업자 인증 후 아래 주석 해제
    // return await ensureIdentityVerified(
    //   context,
    //   message: '입찰 및 즉시 구매를 위해서는 본인 인증이 필요합니다.\n지금 본인 인증을 진행하시겠습니까?',
    // );
    return true; // 임시: 인증 없이 통과
  }

  @override
  void initState() {
    super.initState();
    _statusCode = widget.item.statusCode;
    _checkBidRestriction();
    _checkShippingInfo();
    _checkShippingInfoForSeller();
  }

  Future<void> _checkShippingInfo() async {
    try {
      final shippingInfo = await _shippingInfoRepository.getShippingInfo(widget.item.itemId);
      if (mounted) {
        setState(() {
          _hasShippingInfo = shippingInfo != null && 
                           shippingInfo['tracking_number'] != null &&
                           (shippingInfo['tracking_number'] as String).isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasShippingInfo = false;
        });
      }
    }
  }

  Future<void> _checkShippingInfoForSeller() async {
    try {
      final shippingInfo = await _shippingInfoRepository.getShippingInfo(widget.item.itemId);
      if (mounted) {
        setState(() {
          _hasShippingInfoForSeller = shippingInfo != null && 
                                     shippingInfo['tracking_number'] != null &&
                                     (shippingInfo['tracking_number'] as String).isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasShippingInfoForSeller = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(ItemBottomActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // statusCode가 변경되면 업데이트
    if (oldWidget.item.statusCode != widget.item.statusCode) {
      _statusCode = widget.item.statusCode;
    }
    
    // trade_status_code가 변경되면 플래그 리셋
    if (oldWidget.item.tradeStatusCode != widget.item.tradeStatusCode) {
      _hasShownPaymentCompleteScreen = false;
    }
    
    // 내 매물 + 유찰(323) 상태일 때, 한 번만 재등록 팝업 노출
    if (widget.isMyItem && (_statusCode == 323) && !_hasShownRelistPopup) {
      _hasShownRelistPopup = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) {
            return AskPopup(
              content: '해당 매물이 유찰되었습니다.\n재등록 하시겠습니까?',
              noText: '취소',
              yesText: '재등록',
              yesLogic: () async {
                Navigator.of(dialogContext).pop();
                if (!context.mounted) return;
                context.push(
                  '/add_item',
                  extra: widget.item.itemId,
                );
              },
            );
          },
        );
      });
    }
    
    // 판매자 입장: trade_status_code가 520이면 자동으로 결제 완료 화면 표시
    final bool isTradePaid = widget.item.tradeStatusCode == 520;
    if (widget.isMyItem && isTradePaid && !_hasShownPaymentCompleteScreen) {
      if (_hasShippingInfo != null && !_hasShippingInfo!) {
        _hasShownPaymentCompleteScreen = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final bidWinEntity = ItemBidWinEntity.fromItemDetail(widget.item);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SellerPaymentCompleteScreen(item: bidWinEntity),
            ),
          );
        });
      }
    }
    
    // 구매자 입장: 낙찰(321) 상태이고 아직 결제하지 않은 경우 자동으로 낙찰 성공 화면 표시
    final itemDetailViewModel = context.read<ItemDetailViewModel?>();
    final isTopBidder = itemDetailViewModel?.isTopBidder ?? false;
    final int statusCode = _statusCode ?? 0;
    final bool hasShownBidWinScreen = itemDetailViewModel?.hasShownBidWinScreen ?? false;
    if (!widget.isMyItem && statusCode == 321 && isTopBidder && !isTradePaid && !hasShownBidWinScreen) {
      itemDetailViewModel?.markBidWinScreenAsShown();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final bidWinEntity = ItemBidWinEntity.fromItemDetail(widget.item);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemBidWinScreen(item: bidWinEntity),
          ),
        );
      });
    }
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
    // isTopBidder와 itemDetail.statusCode를 함께 watch하여 실시간 업데이트 반영
    return Selector<ItemDetailViewModel?, ({bool isTopBidder, int? statusCode})>(
      selector: (_, vm) => (
        isTopBidder: vm?.isTopBidder ?? false,
        statusCode: vm?.itemDetail?.statusCode,
      ),
      builder: (context, data, _) {
        // statusCode가 변경되면 _statusCode 업데이트 (didUpdateWidget에서 처리)
        if (data.statusCode != null && _statusCode != data.statusCode) {
          _statusCode = data.statusCode;
        }
        return _buildContent(context, data.isTopBidder, data.statusCode);
      },
    );
  }

  Widget _buildContent(BuildContext context, bool isTopBidder, int? currentStatusCode) {
    final itemDetailViewModel = context.read<ItemDetailViewModel?>();
    final isMyItem = widget.isMyItem;
    final bool isBidRestricted = _isBidRestricted;
    
    // ViewModel의 최신 itemDetail에서 상태 정보 가져오기 (실시간 업데이트 반영)
    final currentItem = itemDetailViewModel?.itemDetail ?? widget.item;
    // DateTime.now()를 한 번만 호출하여 성능 최적화
    final now = DateTime.now();
    final bool isTimeOver = now.isAfter(currentItem.finishTime);
    final int? tradeStatusCode = currentItem.tradeStatusCode;
    final bool isTradePaid = tradeStatusCode == 520;
    
    // statusCode는 Selector에서 받은 값 또는 현재 값 사용
    final int statusCode = _statusCode ?? currentStatusCode ?? currentItem.statusCode ?? 0;

    const disabledStatusesForBuyNow = {
      AuctionStatusCode.ready,
      AuctionStatusCode.instantBuyPaymentPending,
      AuctionStatusCode.bidWon,
      AuctionStatusCode.instantBuyCompleted,
      AuctionStatusCode.failed,
    };
    final bool showBuyNow =
        currentItem.buyNowPrice > 0 &&
        !disabledStatusesForBuyNow.contains(statusCode) &&
        !isTimeOver &&
        !isTradePaid;

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
            _buildFavoriteButton(itemDetailViewModel),
            const SizedBox(width: 12),
            Expanded(child: _buildBidButton(isTopBidder, isTimeOver)),
            if (showBuyNow) ...[
              const SizedBox(width: 8),
              Expanded(child: _buildBuyNowButton()),
            ],
          ] else ...[
            // 판매자 입장: 낙찰(321) 상태이거나 경매 종료 후 아직 결제 전이면 결제 정보 입력 버튼 표시
            if ((statusCode == 321 || isTimeOver) && !isTradePaid) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChattingRoomScreen(
                          itemId: widget.item.itemId,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: blueColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.7),
                    ),
                  ),
                  child: const Text(
                    '구매자 연락하기',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: blueColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // 이미 결제 정보가 있는지 확인
                    final datasource = OfflinePaymentDatasource();
                    final existingPaymentInfo = await datasource.getPaymentInfo(widget.item.itemId);
                    
                    if (existingPaymentInfo != null) {
                      if (!context.mounted) return;
                      final paymentType = existingPaymentInfo['payment_type'] as String?;
                      final message = paymentType == 'direct_trade' 
                          ? '이미 직거래로 설정되었습니다.'
                          : '이미 계좌 정보가 입력되었습니다.';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                      return;
                    }
                    
                    if (!context.mounted) return;
                    
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (dialogContext) {
                        return PaymentInfoInputPopup(
                          onConfirm: ({
                            required String bankName,
                            required String accountNumber,
                            required String accountHolder,
                            required bool isDirectTrade,
                          }) async {
                            try {
                              final datasource = OfflinePaymentDatasource();
                              await datasource.completePayment(
                                itemId: widget.item.itemId,
                                isDirectTrade: isDirectTrade,
                                bankName: bankName,
                                accountNumber: accountNumber,
                                accountHolder: accountHolder,
                              );
                              
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isDirectTrade 
                                          ? '직거래가 선택되었습니다. 구매자에게 알림이 전송됩니다.'
                                          : '계좌 정보가 구매자에게 전송되었습니다.',
                                    ),
                                  ),
                                );
                              }
                              
                              // 화면 새로고침
                              if (context.mounted) {
                                final viewModel = context.read<ItemDetailViewModel?>();
                                viewModel?.loadItemDetail(forceRefresh: true);
                              }
                            } catch (e) {
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  SnackBar(content: Text('오류: ${e.toString()}')),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.7),
                    ),
                  ),
                  child: const Text(
                    '결제 정보 입력',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ]
            // 판매자 입장: trade_status_code가 520이면 구매자 연락하기, 배송 정보 입력하기 버튼 표시
            else if (isTradePaid) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChattingRoomScreen(
                          itemId: widget.item.itemId,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: blueColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.7),
                    ),
                  ),
                  child: const Text(
                    '구매자 연락하기',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: blueColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // 배송 정보 조회
                    final shippingInfoRepository = ShippingInfoRepositoryImpl();
                    try {
                      final shippingInfo = await shippingInfoRepository.getShippingInfo(widget.item.itemId);
                      
                      if (!context.mounted) return;
                      
                      final hasShippingInfo = shippingInfo != null && 
                          shippingInfo['tracking_number'] != null &&
                          (shippingInfo['tracking_number'] as String?)?.isNotEmpty == true;
                      
                      if (hasShippingInfo) {
                        // 송장 정보가 있으면 확인 팝업 표시
                        showDialog(
                          context: context,
                          builder: (dialogContext) => ShippingInfoViewPopup(
                            createdAt: shippingInfo['created_at'] as String?,
                            carrier: shippingInfo['carrier'] as String?,
                            trackingNumber: shippingInfo['tracking_number'] as String?,
                          ),
                        );
                      } else {
                        // 송장 정보가 없으면 입력 팝업 표시
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (dialogContext) {
                            return ShippingInfoInputPopup(
                              initialCarrier: shippingInfo?['carrier'] as String?,
                              initialTrackingNumber: shippingInfo?['tracking_number'] as String?,
                              onConfirm: (carrier, trackingNumber) async {
                                try {
                                  if (shippingInfo != null) {
                                    // 기존 정보가 있으면 택배사만 수정 (송장 번호는 수정 불가)
                                    final existingTrackingNumber = shippingInfo['tracking_number'] as String?;
                                    await shippingInfoRepository.updateShippingInfo(
                                      itemId: widget.item.itemId,
                                      carrier: carrier,
                                      trackingNumber: existingTrackingNumber ?? trackingNumber,
                                    );
                                    if (dialogContext.mounted) {
                                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                                        const SnackBar(
                                          content: Text('택배사 정보가 수정되었습니다'),
                                        ),
                                      );
                                    }
                                  } else {
                                    // 기존 정보가 없으면 새로 저장
                                    await shippingInfoRepository.saveShippingInfo(
                                      itemId: widget.item.itemId,
                                      carrier: carrier,
                                      trackingNumber: trackingNumber,
                                    );
                                    if (dialogContext.mounted) {
                                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                                        const SnackBar(
                                          content: Text('송장 정보가 입력되었습니다'),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (dialogContext.mounted) {
                                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                                      SnackBar(
                                        content: Text('송장 정보 저장 실패: ${e.toString()}'),
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AskPopup(
                          content: '배송 정보를 불러올 수 없습니다.',
                          yesText: '확인',
                          yesLogic: () async {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.7),
                    ),
                  ),
                  child: Text(
                    _hasShippingInfoForSeller == true ? '배송 정보 확인하기' : '배송 정보 입력하기',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ] else
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

  Widget _buildFavoriteButton(ItemDetailViewModel? itemDetailViewModel) {
    if (itemDetailViewModel == null) {
      return const SizedBox.shrink();
    }
    
    // 즐겨찾기 상태만 Selector로 분리
    return Selector<ItemDetailViewModel, bool>(
      selector: (_, vm) => vm.isFavorite,
      builder: (context, isFavorite, _) {
        return InkWell(
          onTap: () {
            itemDetailViewModel.toggleFavorite();
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
      },
    );
  }

  Widget _buildBidButton(bool isTopBidder, bool isTimeOver) {
    // ViewModel의 최신 itemDetail에서 상태 정보 가져오기 (실시간 업데이트 반영)
    final itemDetailViewModel = context.read<ItemDetailViewModel?>();
    final currentItem = itemDetailViewModel?.itemDetail ?? widget.item;
    
    final int statusCode = _statusCode ?? currentItem.statusCode ?? 0;
    final int? tradeStatusCode = currentItem.tradeStatusCode;
    final bool isTradePaid = tradeStatusCode == 520;

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

    // 경매가 활성 상태이고 최고 입찰자인 경우: "최고 입찰자입니다" 표시
    if (isAuctionActive && isTopBidder && !isBuyNowInProgress) {
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
            '최고 입찰자입니다',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TopBidderTextColor,
            ),
          ),
        ),
      );
    }

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

    // 경매 낙찰(321) 상태이고, 결제가 이미 완료(520)된 경우:
    // 좌측: 결제 내역 보기(결제 상세 화면) / 우측: 판매자와 연락하기 버튼 노출
    if (statusCode == 321 && isTopBidder && isTradePaid) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // 해당 매물의 결제 상세 내역 화면으로 이동
                // 기존 상세 화면을 스택에 유지하기 위해 push 사용
                context.push('/payments?itemId=${widget.item.itemId}');
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: blueColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.7),
                ),
              ),
              child: Text(
                '결제 내역 보기',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: blueColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                // 배송 정보 조회
                final shippingInfoRepository = ShippingInfoRepositoryImpl();
                try {
                  final shippingInfo = await shippingInfoRepository.getShippingInfo(widget.item.itemId);
                  
                  if (!mounted) return;
                  
                  final navigatorContext = context;
                  showDialog(
                    context: navigatorContext,
                    builder: (dialogContext) => ShippingInfoViewPopup(
                      createdAt: shippingInfo?['created_at'] as String?,
                      carrier: shippingInfo?['carrier'] as String?,
                      trackingNumber: shippingInfo?['tracking_number'] as String? ?? 
                                    shippingInfo?['tracking_num'] as String?,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  
                  final navigatorContext = context;
                  showDialog(
                    context: navigatorContext,
                    builder: (dialogContext) => AskPopup(
                      content: '배송 정보를 불러올 수 없습니다.',
                      yesText: '확인',
                      yesLogic: () async {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.7),
                ),
              ),
              child: const Text(
                '배송 정보 확인',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 경매 낙찰(321) 상태에서, 내가 낙찰자이고 아직 결제가 완료되지 않은 경우에만 결제 버튼 노출
    // 현재 화면의 ViewModel 에서 isTopBidder 가 true 인 상태를 낙찰자로 간주
    if (statusCode == 321 && isTopBidder && !isTradePaid) {
      // TODO: 사업자 인증 후 아래 주석 해제
      // final bidWinEntity = ItemBidWinEntity.fromItemDetail(widget.item);
      //
      // return PrimaryButton(
      //   text: '결제하러 가기',
      //   onPressed: () async {
      //     final authVM = context.read<AuthViewModel>();
      //     final String buyerTel = authVM.user?.phone_number ?? '';
      //     const appScheme = 'bidbird';
      //
      //     final request = ItemPaymentRequest(
      //       itemId: widget.item.itemId,
      //       itemTitle: widget.item.itemTitle,
      //       amount: widget.item.currentPrice,
      //       buyerTel: buyerTel,
      //       appScheme: appScheme,
      //     );
      //
      //     final result = await Navigator.push<bool>(
      //       context,
      //       MaterialPageRoute(
      //         builder: (_) => PortonePaymentScreen(request: request),
      //       ),
      //     );
      //
      //     if (!mounted) return;
      //
      //     if (result == true) {
      //       // 결제 성공 시 결제 완료 화면으로 이동
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(
      //           builder: (_) => PaymentCompleteScreen(item: bidWinEntity),
      //         ),
      //       );
      //     } else if (result == false) {
      //       showDialog<void>(
      //         context: context,
      //         barrierDismissible: true,
      //         builder: (dialogContext) {
      //           return AskPopup(
      //             content: '결제가 취소되었거나 실패했습니다.\n다시 시도하시겠습니까?',
      //             noText: '닫기',
      //             yesText: '확인',
      //             yesLogic: () async {
      //               Navigator.of(dialogContext).pop();
      //             },
      //           );
      //         },
      //       );
      //     }
      //   },
      //   width: double.infinity,
      // );
      
      // 임시: 결제 정보 확인 버튼 (결제 정보가 있으면 팝업 표시)
      return GestureDetector(
        onTap: () async {
          final datasource = OfflinePaymentDatasource();
          final paymentInfo = await datasource.getPaymentInfo(widget.item.itemId);
          
          if (!context.mounted) return;
          
          if (paymentInfo != null) {
            // 결제 정보가 있으면 팝업 표시
            showDialog(
              context: context,
              builder: (dialogContext) => PaymentInfoViewPopup(
                paymentType: paymentInfo['payment_type'] as String? ?? '',
                bankName: paymentInfo['bank_name'] as String?,
                accountNumber: paymentInfo['account_number'] as String?,
                accountHolder: paymentInfo['account_holder'] as String?,
              ),
            );
          } else {
            // 결제 정보가 없으면 안내 메시지
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('판매자가 아직 결제 정보를 입력하지 않았습니다.')),
            );
          }
        },
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
              '결제 정보 확인하기',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TopBidderTextColor,
              ),
            ),
          ),
        ),
      );
    }

    // 즉시 구매 진행 중(1006)인 경우
    // - 즉시 구매를 건 사용자(현재 최고 입찰자)는 '결제하러 가기' 버튼 노출
    // - 그 외 사용자는 안내 문구만 노출
    if (isBuyNowInProgress && !isBuyNowCompleted) {
      if (isTopBidder) {
        // TODO: 사업자 인증 후 아래 주석 해제
        // return PrimaryButton(
        //   text: '결제하러 가기',
        //   onPressed: () async {
        //     const buyerTel = '01012345678';
        //     const appScheme = 'bidbird';
        //
        //     final request = ItemPaymentRequest(
        //       itemId: widget.item.itemId,
        //       itemTitle: widget.item.itemTitle,
        //       amount: widget.item.buyNowPrice,
        //       buyerTel: buyerTel,
        //       appScheme: appScheme,
        //     );
        //
        //     final result = await Navigator.push<bool>(
        //       context,
        //       MaterialPageRoute(
        //         builder: (_) => PortonePaymentScreen(request: request),
        //       ),
        //     );
        //
        //     if (!mounted) return;
        //
        //     if (result == true) {
        //       // 즉시 구매 결제 성공 시에도 결제 완료 화면으로 이동
        //       final bidWinEntity = ItemBidWinEntity.fromItemDetail(widget.item);
        //
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //           builder: (_) => PaymentCompleteScreen(item: bidWinEntity),
        //         ),
        //       );
        //     } else if (result == false) {
        //       showDialog<void>(
        //         context: context,
        //         barrierDismissible: true,
        //         builder: (dialogContext) {
        //           return AskPopup(
        //             content: '결제가 취소되었거나 실패했습니다.\n다시 시도하시겠습니까?',
        //             noText: '닫기',
        //             yesText: '확인',
        //             yesLogic: () async {
        //               Navigator.of(dialogContext).pop();
        //             },
        //           );
        //         },
        //       );
        //     }
        //   },
        //   width: double.infinity,
        // );
        
        // 임시: 판매자 결제정보 입력 대기 안내
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
              '판매자가 결제정보 입력 중입니다',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TopBidderTextColor,
              ),
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
      return SecondaryButton(
        text: '입찰하기',
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
        width: double.infinity,
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
        case AuctionStatusCode.ready:
          reason = '경매가 아직 시작되지 않았습니다';
          break;
        case AuctionStatusCode.bidWon:
        case AuctionStatusCode.failed:
          reason = '경매가 종료되었습니다.';
          break;
        case AuctionStatusCode.instantBuyPaymentPending:
          reason = '즉시 구매 결제 대기중입니다';
          break;
        case AuctionStatusCode.instantBuyCompleted:
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
    return PrimaryButton(
      text: '즉시 구매하기',
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
      width: double.infinity,
    );
  }
}
