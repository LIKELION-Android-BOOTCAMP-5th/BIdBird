import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/router/app_router.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/image_source_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/pop_up/check_confirm_popup.dart';
import 'package:bidbird/core/widgets/components/pop_up/trade_cancel_fault_popup.dart';
import 'package:bidbird/core/widgets/components/pop_up/trade_review_popup.dart';
import 'package:bidbird/features/chat/presentation/widgets/trade_cancel_reason_bottom_sheet.dart';
import 'package:bidbird/features/chat/presentation/widgets/trade_context_card.dart';
import 'package:bidbird/features/chat/presentation/viewmodels/chatting_room_viewmodel.dart';
import 'package:bidbird/features/chat/presentation/widgets/chat_input_area.dart';
import 'package:bidbird/features/chat/presentation/widgets/chat_message_list.dart';
import 'package:bidbird/features/chat/presentation/widgets/chat_room_header.dart';
import 'package:bidbird/features/chat/presentation/widgets/image_attachment_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ChattingRoomScreen extends StatefulWidget {
  final String itemId;
  final String? roomId;

  const ChattingRoomScreen({super.key, required this.itemId, this.roomId});

  @override
  State<ChattingRoomScreen> createState() => _ChattingRoomScreenState();
}

class _ChattingRoomScreenState extends State<ChattingRoomScreen>
    with RouteAware, WidgetsBindingObserver {
  final FocusNode _inputFocusNode = FocusNode();
  
  void _showImageSourceSheet(
    BuildContext context,
    ChattingRoomViewmodel viewModel,
  ) {
    ImageSourceBottomSheet.show(
      context,
      onGalleryTap: () async {
        await viewModel.pickImagesFromGallery();
      },
      onCameraTap: () async {
        await viewModel.pickImageFromCamera();
      },
      onVideoTap: () async {
        await viewModel.pickVideoFromGallery();
      },
    );
  }

  late ChattingRoomViewmodel viewModel;
  @override
  void initState() {
    super.initState();
    _inputFocusNode.addListener(() {
      setState(() {}); // 포커스 상태 변경 시 리빌드
    });
    WidgetsBinding.instance.addObserver(this);
    viewModel = ChattingRoomViewmodel(
      itemId: widget.itemId,
      roomId: widget.roomId,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    // 채팅방을 나갈 때 낙관적 업데이트로 읽음 처리
    if (viewModel.roomId != null && viewModel.isActive) {
      // disposeViewModel에서 낙관적으로 읽음 처리하고, 서버 통신은 백그라운드로 처리
      viewModel.disposeViewModel().catchError((e) {});
    }
    super.dispose();
  }

  // 화면에 들어왔을 때
  @override
  void didPush() {
    if (viewModel.roomId != null) {
      viewModel.enterRoom();
    }
  }

  // 뒤로가기(pop)했을 때
  @override
  void didPop() {
    if (viewModel.roomId != null) {
      // dispose에서도 disposeViewModel이 호출되지만, 명시적으로 호출하여 낙관적 읽음 처리 보장
      // disposeViewModel에서 낙관적으로 읽음 처리하고, 서버 통신은 백그라운드로 처리
      viewModel
          .leaveRoom()
          .then((_) {
            // disposeViewModel 완료
          })
          .catchError((e) {});
    }
  }

  // 화면이 비활성화될 때 (다른 화면으로 이동)
  @override
  void didPushNext() {
    if (viewModel.roomId != null) {
      // 다른 화면으로 이동할 때도 낙관적으로 읽음 처리
      viewModel.disposeViewModel();
    }
  }

  // 이전 화면에서 돌아왔을 때
  @override
  void didPopNext() {
    if (viewModel.roomId != null) {
      // 다시 돌아왔을 때 enterRoom 호출
      viewModel.enterRoom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<ChattingRoomViewmodel>(
        builder: (context, viewModel, child) {
          // 반응형: 큰 화면에서는 최대 너비 제한 및 중앙 정렬
          final screenWidth = MediaQuery.of(context).size.width;
          final isLargeScreen = screenWidth >= 800;
          final maxWidth = isLargeScreen ? 800.0 : double.infinity;
          
          return SafeArea(
            child: Scaffold(
              backgroundColor: chatBackgroundColor,
              appBar: ChatRoomHeader(viewModel: viewModel),
              body: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: [
                      // 거래 컨텍스트 카드
                      Builder(
                    builder: (context) {
                      // 현재 사용자가 판매자인지 구매자인지 확인
                      final currentUserId = SupabaseManager
                          .shared
                          .supabase
                          .auth
                          .currentUser
                          ?.id;
                      final isSeller = currentUserId != null &&
                          viewModel.itemInfo != null &&
                          viewModel.itemInfo!.sellerId == currentUserId;

                      // 거래 상태 텍스트 결정
                      String tradeStatusText = '거래 중';
                      if (viewModel.tradeInfo != null) {
                        switch (viewModel.tradeInfo!.tradeStatusCode) {
                          case 510:
                            tradeStatusText = '결제 대기';
                            break;
                          case 520:
                            tradeStatusText = '거래 중';
                            break;
                          case 550:
                            tradeStatusText = '거래 완료';
                            break;
                          default:
                            tradeStatusText = '거래 중';
                        }
                      } else if (viewModel.itemInfo != null) {
                        // tradeInfo가 없으면 auctionInfo 기반으로 판단
                        tradeStatusText = '거래 중';
                      }

                      // 거래 취소는 구매자(낙찰자)만 가능, 거래 완료/취소 상태에서는 불가
                      final canShowTradeCancel = viewModel.tradeInfo != null &&
                          viewModel.tradeInfo!.tradeStatusCode != 550 &&
                          viewModel.tradeInfo!.tradeStatusCode != 540 && // 이미 취소된 거래는 불가
                          viewModel.isTopBidder; // 구매자(낙찰자)만 가능

                      // 거래 현황 보기 / 거래 평가 버튼 표시 조건: 낙찰자 또는 판매자만, 그리고 tradeInfo가 있어야 함
                      // 거래 완료 상태(550)일 때는 평가를 작성하지 않았을 때만 표시
                      final canShowTradeStatus = viewModel.tradeInfo != null &&
                          (viewModel.isTopBidder || isSeller) &&
                          !(viewModel.tradeInfo?.tradeStatusCode == 550 && viewModel.hasSubmittedReview);

                      return TradeContextCard(
                        itemTitle: viewModel.itemInfo?.title ?? "",
                        itemThumbnail: viewModel.itemInfo?.thumbnailImage,
                        itemPrice: viewModel.auctionInfo?.currentPrice ?? 0,
                        isSeller: isSeller,
                        tradeStatus: tradeStatusText,
                        tradeStatusCode: viewModel.tradeInfo?.tradeStatusCode,
                        hasShippingInfo: viewModel.hasShippingInfo,
                        onItemTap: () {
                          if (viewModel.itemId.isNotEmpty) {
                            context.push('/item/${viewModel.itemId}');
                          }
                        },
                        onTradeStatusTap: canShowTradeStatus
                            ? () {
                                // 거래 완료 상태(550)일 때는 거래 평가 팝업 표시, 그 외에는 거래 현황 화면으로 이동
                                if (viewModel.itemId.isNotEmpty) {
                                  if (viewModel.tradeInfo?.tradeStatusCode == 550) {
                                    // 거래 평가 팝업 표시
                                    _showTradeReviewPopup(context, viewModel);
                                  } else {
                                    // 거래 현황 화면으로 이동
                                    context.push('/chat/room/trade-status?itemId=${viewModel.itemId}');
                                  }
                                }
                              }
                            : null,
                        onTradeComplete: viewModel.tradeInfo != null &&
                                viewModel.tradeInfo!.tradeStatusCode != 550 &&
                                viewModel.hasShippingInfo &&
                                viewModel.isTopBidder // 구매자(낙찰자)만 가능
                            ? () {
                                // 거래 완료 액션
                                _showTradeCompleteDialog(context, viewModel);
                              }
                            : null,
                        onTradeCancel: canShowTradeCancel && viewModel.hasShippingInfo
                            ? () {
                                // 거래 취소 액션 (사유 선택 포함)
                                _showTradeCancelWithReason(context, viewModel);
                              }
                            : null,
                      );
                    },
                  ),
                  Expanded(
                    child: ChatMessageList(viewModel: viewModel),
                  ),
                  // 이미지 첨부 바
                  ImageAttachmentBar(viewModel: viewModel),
                  // 입력창 영역
                  ChatInputArea(
                    viewModel: viewModel,
                    focusNode: _inputFocusNode,
                    onImageSourceSheet: () {
                      _showImageSourceSheet(context, viewModel);
                    },
                  ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 거래 완료 다이얼로그 표시
  void _showTradeCompleteDialog(
    BuildContext context,
    ChattingRoomViewmodel viewModel,
  ) {
    CheckConfirmPopup.show(
      context,
      title: '거래 완료',
      description: '거래를 완료하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
      checkLabel: '위 내용을 확인했습니다.',
      confirmText: '완료',
      cancelText: '취소',
      onConfirm: () async {
        // 로딩 표시
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('거래 완료 처리 중...'),
            duration: Duration(seconds: 1),
          ),
        );

        try {
          // 거래 완료 API 호출
          await viewModel.completeTrade();
          
          if (!context.mounted) return;
          
          // 성공 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('거래가 완료되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // 뷰모델 새로고침하여 UI 업데이트
          await viewModel.fetchRoomInfo();
        } catch (e) {
          if (!context.mounted) return;
          
          // 에러 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('거래 완료 처리 중 오류가 발생했습니다: ${e.toString()}'),
              backgroundColor: RedColor,
            ),
          );
        }
      },
    );
  }

  /// 거래 취소 사유 선택 후 확인 다이얼로그 표시
  void _showTradeCancelWithReason(
    BuildContext context,
    ChattingRoomViewmodel viewModel,
  ) {
    // 1단계: 귀책 사유 선택 팝업 (먼저)
    TradeCancelFaultPopup.show(
      context,
      onSelected: (isSellerFault) {
        // 2단계: 취소 사유 선택 바텀시트
        TradeCancelReasonBottomSheet.show(
          context,
          onReasonSelected: (reasonCode) {
            // 3단계: 체크박스 확인 팝업
            CheckConfirmPopup.show(
              context,
              title: '거래 취소',
              description: '거래를 취소하시겠습니까?\n취소 사유가 상대에게 전달됩니다.',
              checkLabel: '위 내용을 확인했습니다.',
              confirmText: '거래 취소',
              cancelText: '돌아가기',
              onConfirm: () {
                // 4단계: 최종 확인 및 처리
                _processTradeCancel(context, viewModel, reasonCode, isSellerFault);
              },
            );
          },
        );
      },
    );
  }

  /// 거래 취소 처리
  void _processTradeCancel(
    BuildContext context,
    ChattingRoomViewmodel viewModel,
    String reasonCode,
    bool isSellerFault,
  ) async {
    // 로딩 표시
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('거래 취소 처리 중...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // 거래 취소 API 호출
      await viewModel.cancelTrade(reasonCode, isSellerFault);
      
      if (!context.mounted) return;
      
      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('거래가 취소되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // 뷰모델 새로고침하여 UI 업데이트
      await viewModel.fetchRoomInfo();
    } catch (e) {
      if (!context.mounted) return;
      
      // 에러 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('거래 취소 처리 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: RedColor,
        ),
      );
    }
  }

  /// 거래 평가 팝업 표시
  void _showTradeReviewPopup(
    BuildContext context,
    ChattingRoomViewmodel viewModel,
  ) {
    TradeReviewPopup.show(
      context,
      onSubmit: (rating, review) async {
        // 로딩 표시
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('거래 평가 작성 중...'),
            duration: Duration(seconds: 1),
          ),
        );

        try {
          // 거래 평가 API 호출
          await viewModel.submitTradeReview(rating, review);
          
          if (!context.mounted) return;
          
          // 성공 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('거래 평가가 작성되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          
          // 에러 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('거래 평가 작성 중 오류가 발생했습니다: ${e.toString()}'),
              backgroundColor: RedColor,
            ),
          );
        }
      },
      onCancel: () {
        // 취소 시 아무 동작 없음
      },
    );
  }
}
