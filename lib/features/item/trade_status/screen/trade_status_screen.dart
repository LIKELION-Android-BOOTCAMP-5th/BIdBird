import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/components/info_box.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/core/widgets/components/pop_up/shipping_info_input_popup.dart';
import 'package:bidbird/core/widgets/item/components/cards/trade_status_item_card.dart';
import 'package:bidbird/features/auth/viewmodel/auth_view_model.dart';
import 'package:bidbird/features/item/bid_win/model/item_bid_win_entity.dart';
import 'package:bidbird/features/item/shipping/data/repository/shipping_info_repository.dart';
import 'package:bidbird/features/item/trade_status/model/trade_status_entity.dart';
import 'package:bidbird/features/item/trade_status/viewmodel/trade_status_viewmodel.dart';
import 'package:bidbird/features/payment/payment_complete/screen/payment_complete_screen.dart';
import 'package:bidbird/features/payment/portone_payment/model/item_payment_request.dart';
import 'package:bidbird/features/payment/portone_payment/screen/portone_payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// 거래 현황 화면
/// 입찰→낙찰→결제→배송→완료 단계를 표시
class TradeStatusScreen extends StatelessWidget {
  final String itemId;

  const TradeStatusScreen({
    super.key,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TradeStatusViewModel(itemId: itemId)..loadData(),
      child: const _TradeStatusScreenContent(),
    );
  }
}

class _TradeStatusScreenContent extends StatelessWidget {
  const _TradeStatusScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TradeStatusViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('거래 현황'),
        centerTitle: true,
      ),
      backgroundColor: BackgroundColor,
      body: SafeArea(
        child: viewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : viewModel.error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '오류가 발생했습니다.',
                          style: TextStyle(color: RedColor),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            viewModel.loadData();
                          },
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  )
                : _buildContent(context, viewModel),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TradeStatusViewModel viewModel) {
    final currentStep = viewModel.currentStep;
    final tradeStatus = viewModel.tradeStatus;

    if (tradeStatus == null) {
      return const Center(child: Text('거래 정보를 불러올 수 없습니다.'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이템 카드
          if (tradeStatus.itemInfo != null) _buildItemCard(context, viewModel),
          const SizedBox(height: 20), // 카드 하단 margin: 20dp
          // 5단계 진행 표시
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildStepIndicator(currentStep),
          ),
          // 결제 기한 info_box (판매자일 경우)
          if (currentStep == TradeStep.payment && viewModel.isSeller)
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                viewModel.shouldShowActionButton() ? 12 : 8,
                16,
                0,
              ),
              child: InfoBox(
                paymentDeadline: viewModel.paymentDeadline,
                centerAlign: true,
                showIcon: false,
              ),
            ),
          // 액션 버튼
          if (viewModel.shouldShowActionButton()) ...[
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildActionButton(context, viewModel, currentStep),
            ),
          ],
          // 결제 기한 info_box (구매자일 경우 - 결제하기 버튼 밑)
          if (currentStep == TradeStep.payment && !viewModel.isSeller)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: InfoBox(
                paymentDeadline: viewModel.paymentDeadline,
                centerAlign: false,
                showIcon: true,
              ),
            ),
          // 배송 대기 메시지 (구매자일 경우)
          if (currentStep == TradeStep.shipping && !viewModel.isSeller)
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                viewModel.shouldShowActionButton() ? 12 : 8,
                16,
                0,
              ),
              child: InfoBox(
                message: '판매자의 배송 정보 입력 대기중 입니다.',
                centerAlign: false,
                showIcon: true,
              ),
            ),
          // 거래 기록
          const SizedBox(height: 12), // 기록 상단 margin: 12dp
          _buildTradeHistory(tradeStatus.historyEvents),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, TradeStatusViewModel viewModel) {
    final tradeStatus = viewModel.tradeStatus;
    if (tradeStatus?.itemInfo == null) {
      return const SizedBox.shrink();
    }

    final roleText = viewModel.isSeller ? '판매자' : '구매자';
    final statusText = viewModel.currentStatusText;

    return TradeStatusItemCard(
      title: tradeStatus!.itemInfo!.title,
      price: tradeStatus.auctionInfo?.currentPrice ?? 0,
      thumbnailUrl: tradeStatus.itemInfo!.thumbnailImage,
      roleText: roleText,
      statusText: statusText,
      onTap: () {
        // 매물 상세 화면으로 이동
        context.push('/item/${viewModel.itemId}');
      },
    );
  }

  Widget _buildStepIndicator(TradeStep currentStep) {
    final steps = [
      _StepData('입찰', TradeStep.bidding),
      _StepData('낙찰', TradeStep.won),
      _StepData('결제', TradeStep.payment),
      _StepData('배송', TradeStep.shipping),
      _StepData('완료', TradeStep.completed),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            // 연결선
            Positioned(
              left: 20,
              right: 20,
              top: 20,
              child: Row(
                children: List.generate(steps.length - 1, (index) {
                  final stepIndex = _getStepIndex(steps[index].step);
                  final currentIndex = _getStepIndex(currentStep);
                  final isCompleted = stepIndex < currentIndex;
                  final isCurrent = stepIndex == currentIndex;
                  
                  return Expanded(
                    child: Container(
                      height: 2,
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : 8,
                        right: index == steps.length - 2 ? 0 : 8,
                      ),
                      color: isCompleted
                          ? Colors.green
                          : isCurrent
                              ? blueColor
                              : Colors.grey[300],
                    ),
                  );
                }),
              ),
            ),
            // 단계 원과 이름
            Row(
              children: steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isActive = step.step == currentStep;
                final isCompleted = _isStepCompleted(step.step, currentStep);

                return Expanded(
                  child: Column(
                    children: [
                      // 단계 원
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? Colors.green
                              : isActive
                                  ? blueColor
                                  : Colors.grey[300],
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 단계 이름
                      Text(
                        step.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive || isCompleted
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isCompleted
                              ? Colors.green
                              : isActive || isCompleted
                                  ? blueColor
                                  : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  bool _isStepCompleted(TradeStep step, TradeStep currentStep) {
    final currentIndex = _getStepIndex(currentStep);
    final stepIndex = _getStepIndex(step);
    // 현재 단계가 completed이면 모든 단계가 완료된 것으로 표시
    if (currentStep == TradeStep.completed) {
      return stepIndex <= 4; // 완료까지 모두 완료
    }
    return stepIndex < currentIndex;
  }

  int _getStepIndex(TradeStep step) {
    switch (step) {
      case TradeStep.bidding:
        return 0;
      case TradeStep.won:
        return 1;
      case TradeStep.payment:
        return 2;
      case TradeStep.shipping:
        return 3;
      case TradeStep.completed:
        return 4;
    }
  }

  Widget _buildActionButton(
    BuildContext context,
    TradeStatusViewModel viewModel,
    TradeStep currentStep,
  ) {
    if (currentStep == TradeStep.payment) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            final tradeStatus = viewModel.tradeStatus;
            if (tradeStatus?.itemInfo == null ||
                tradeStatus?.auctionInfo == null) {
              return;
            }

            final authVM = context.read<AuthViewModel>();
            final String buyerTel = authVM.user?.phone_number ?? '';
            const appScheme = 'bidbird';

            final request = ItemPaymentRequest(
              itemId: viewModel.itemId,
              itemTitle: tradeStatus!.itemInfo!.title,
              amount: tradeStatus.auctionInfo!.currentPrice,
              buyerTel: buyerTel,
              appScheme: appScheme,
            );

            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => PortonePaymentScreen(request: request),
              ),
            );

            if (!context.mounted) return;

            if (result == true) {
              // 결제 성공 시 결제 완료 화면으로 이동
              final bidWinEntity = ItemBidWinEntity(
                itemId: viewModel.itemId,
                title: tradeStatus.itemInfo!.title,
                images: tradeStatus.itemInfo!.thumbnailImage != null
                    ? [tradeStatus.itemInfo!.thumbnailImage!]
                    : [],
                winPrice: tradeStatus.auctionInfo!.currentPrice,
                tradeStatusCode: tradeStatus.tradeInfo?.tradeStatusCode,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentCompleteScreen(item: bidWinEntity),
                ),
              );
            } else if (result == false) {
              // 결제 실패 시 에러 다이얼로그 표시
              showDialog<void>(
                context: context,
                barrierDismissible: true,
                builder: (dialogContext) {
                  return AskPopup(
                    content: '결제가 취소되었거나 실패했습니다.\n다시 시도하시겠습니까?',
                    noText: '닫기',
                    yesText: '확인',
                    yesLogic: () async {
                      Navigator.of(dialogContext).pop();
                    },
                  );
                },
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: blueColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                '결제하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      );
    }
    
    if (currentStep == TradeStep.shipping) {
      final shippingInfoRepository = ShippingInfoRepository();
      final tradeStatus = viewModel.tradeStatus;
      final shippingInfo = tradeStatus?.shippingInfo;

      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                // 송장 입력 팝업 표시
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (dialogContext) {
                    return ShippingInfoInputPopup(
                      initialCarrier: shippingInfo?['carrier'] as String?,
                      initialTrackingNumber:
                          shippingInfo?['tracking_number'] as String?,
                      onConfirm: (carrier, trackingNumber) async {
                        try {
                          if (shippingInfo != null) {
                            // 기존 정보가 있으면 택배사만 수정 (송장 번호는 수정 불가)
                            final existingTrackingNumber =
                                shippingInfo['tracking_number'] as String?;
                            await shippingInfoRepository.updateShippingInfo(
                              itemId: viewModel.itemId,
                              carrier: carrier,
                              trackingNumber:
                                  existingTrackingNumber ?? trackingNumber,
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
                              itemId: viewModel.itemId,
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
                          
                          // 송장 정보 다시 로드
                          await viewModel.refreshShippingInfo();
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: blueColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    '송장 입력',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }


  Widget _buildTradeHistory(List<TradeHistoryEvent> historyEvents) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20), // 좌우 16dp, 상단 12dp, 하단 20dp
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '거래 타임라인',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 12), // margin-bottom: 12dp
          if (historyEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Text(
                '거래 기록이 없습니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8A8D91),
                ),
              ),
            )
          else
            ...historyEvents.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              final isLast = index == historyEvents.length - 1;

              return Padding(
                padding: EdgeInsets.only(
                    bottom: index < historyEvents.length - 1 ? 16 : 0), // 아이템 간 간격: 16dp
                child: _buildHistoryItem(event, isLast),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(TradeHistoryEvent event, bool isLast) {
    final dateFormat = DateFormat('MM.dd HH:mm');
    final timeText = dateFormat.format(event.timestamp);
    
    // 거래 기록 영역에서는 색상 절제 - 모든 이벤트를 회색으로 표시
    const dotColor = Color(0xFFDADCE0);  // 회색 점
    const lineColor = Color(0xFFEDEFF2);  // 회색 선

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타임라인 점과 선
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: lineColor,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 12), // 타임라인 점 ↔ 텍스트 시작 간격: 12dp
        // 이벤트 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500, // Medium
                  color: Color(0xFF111111), // #111111
                ),
              ),
              // 설명 (subtitle이 있는 경우)
              if (event.subtitle != null) ...[
                const SizedBox(height: 8), // 아이콘 ↔ 텍스트 간격: 8dp
                Text(
                  event.subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal, // Regular
                    color: Color(0xFF8A8D91), // #8A8D91
                  ),
                ),
              ],
              const SizedBox(height: 8), // 텍스트 간 간격: 8dp
              // 시간
              Text(
                '$timeText · ${event.actorType}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF9AA0A6), // #9AA0A6
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepData {
  final String label;
  final TradeStep step;

  _StepData(this.label, this.step);
}

