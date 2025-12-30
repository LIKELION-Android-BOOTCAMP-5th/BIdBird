import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/router/app_router.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/image_source_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/pop_up/check_confirm_popup.dart';
import 'package:bidbird/core/widgets/components/pop_up/trade_cancel_fault_popup.dart';
import 'package:bidbird/core/widgets/components/pop_up/trade_review_popup.dart';
import 'package:bidbird/features/chat/presentation/viewmodels/chatting_room_viewmodel.dart';
import 'package:bidbird/features/chat/presentation/widgets/chat_input_area.dart';
import 'package:bidbird/features/chat/presentation/widgets/chat_message_list.dart';
import 'package:bidbird/features/chat/presentation/widgets/chat_room_header.dart';
import 'package:bidbird/features/chat/presentation/widgets/image_attachment_bar.dart';
import 'package:bidbird/features/chat/presentation/widgets/trade_cancel_reason_bottom_sheet.dart';
import 'package:bidbird/features/chat/presentation/widgets/trade_context_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ChattingRoomScreen extends StatefulWidget {
  final String itemId;
  final String? roomId;
  final String? itemTitle; // 상품명
  final String? sellerName; // 판매자명
  final String? sellerImage; // 판매자 이미지
  final int? itemPrice; // 상품 가격
  final String? sellerUserId; // 판매자 ID
  final bool isSellerMode; // 판매자 모드 여부 (판매자가 구매자에게 연락할 때 true)

  const ChattingRoomScreen({
    super.key,
    required this.itemId,
    this.roomId,
    this.itemTitle,
    this.sellerUserId,
    this.sellerName,
    this.sellerImage,
    this.itemPrice,
    this.isSellerMode = false,
  });

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
    
    // viewModel 생성
    viewModel = ChattingRoomViewmodel(
      itemId: widget.itemId,
      roomId: widget.roomId,
    );
    
    // 전달받은 item 정보를 viewModel에 설정 (roomInfo 없이도 표시할 수 있도록)
    if (widget.itemTitle != null) {
      // 현재 사용자 기준으로 상대방 이름을 낙관적으로 결정
      final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
      
      // isSellerMode가 true이거나, sellerId가 내 ID와 같으면 판매자로 간주
      final isCurrentUserSeller = widget.isSellerMode ||
          (currentUserId != null && widget.sellerUserId != null && widget.sellerUserId == currentUserId);

      viewModel.setInitialItemInfo(
        itemTitle: widget.itemTitle!,
        // 판매자인 경우엔 상대가 구매자이므로 내 이름이 아닌 '구매자'로 표시
        sellerName: isCurrentUserSeller ? '구매자' : widget.sellerName,
        sellerImage: widget.sellerImage,
        itemPrice: widget.itemPrice,
      );

      // 판매자라면, 방 정보가 오기 전이라도 구매자 닉네임을 비동기로 채워 넣기
      if (isCurrentUserSeller) {
        // 실패해도 조용히 무시
        viewModel.fetchFallbackOpponentNameIfNeeded(isCurrentUserSeller: true);
      }
    }
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
    print("채팅방 퇴장");
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

  bool _hasAutoShownTradeCompleteDialog = false;

  void _checkAndShowAutoTradeCompleteDialog() {
    // 이미 보여줬으면 스킵
    if (_hasAutoShownTradeCompleteDialog) return;

    // 1. 내가 낙찰자인지 확인
    if (!viewModel.isTopBidder) return;

    // 2. 거래가 완료되지 않았는지 확인 (550: 완료)
    // tradeInfo가 null이면 아직 거래 전이거나 로딩 중이므로 완료되지 않은 것으로 간주
    if (viewModel.tradeInfo != null && viewModel.tradeInfo!.tradeStatusCode == 550) return;

    // 3. 내가 채팅을 했는지 확인 (내가 보낸 메시지가 하나라도 있는지)
    // 현재 사용자의 ID
    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final hasSentMessage = viewModel.messages.any((msg) => msg.senderId == currentUserId);
    
    // 조건 만족 시 다이얼로그 표시
    if (hasSentMessage) {
      _hasAutoShownTradeCompleteDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showTradeActionBottomSheet(context, viewModel);
        }
      });
    }
  }

  /// 거래 상태 변경 선택 바텀시트 (자동 팝업용)
  void _showTradeActionBottomSheet(
    BuildContext context,
    ChattingRoomViewmodel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text(
                '거래 상태 변경',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '원하는 작업을 선택해주세요.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text('거래 완료'),
                subtitle: const Text('물품을 수령했고 거래를 완료합니다.'),
                onTap: () {
                  Navigator.pop(sheetContext); // 시트 닫기
                  _showTradeCompleteDialog(context, viewModel);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                title: const Text('거래 취소'),
                subtitle: const Text('사유를 선택하고 거래를 취소합니다.'),
                onTap: () {
                  Navigator.pop(sheetContext); // 시트 닫기
                  _showTradeCancelWithReason(context, viewModel);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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
                          // viewModel 데이터가 없을 때는 위젯 파라미터로 대체 판단
                          final isSeller =
                              currentUserId != null &&
                              (
                                (viewModel.itemInfo != null && viewModel.itemInfo!.sellerId == currentUserId) ||
                                (viewModel.itemInfo == null && widget.sellerUserId != null && widget.sellerUserId == currentUserId)
                              );

                          // 거래 상태 코드 결정 (tradeInfo가 우선, 없으면 auctionInfo)
                          int? tradeStatusCode = viewModel.tradeInfo?.tradeStatusCode ?? viewModel.auctionInfo?.tradeStatusCode;

                          // 거래 상태 텍스트 결정
                          String tradeStatusText = '거래 중';
                          if (tradeStatusCode != null) {
                            switch (tradeStatusCode) {
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
                          }

                          // 거래 현황 보기 / 거래 평가 버튼 표시 조건: 낙찰자 또는 판매자만
                          // 거래 완료 상태(550)일 때만 평가 버튼 표시 (일반 거래 현황 보기는 숨김)
                          final canShowTradeStatus =
                              (viewModel.isTopBidder || isSeller) &&
                              tradeStatusCode == 550 &&
                              !viewModel.hasSubmittedReview;

                          return TradeContextCard(
                            itemTitle: viewModel.itemInfo?.title ?? widget.itemTitle ?? "",
                            itemThumbnail: viewModel.itemInfo?.thumbnailImage,
                            itemPrice: viewModel.auctionInfo?.currentPrice ?? widget.itemPrice ?? 0,
                            isSeller: isSeller,
                            tradeStatus: tradeStatusText,
                            tradeStatusCode: tradeStatusCode,
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
                                      if (tradeStatusCode == 550) {
                                        // 거래 평가 팝업 표시
                                        _showTradeReviewPopup(
                                          context,
                                          viewModel,
                                        );
                                      } else {
                                        // 거래 현황 화면으로 이동
                                        context.push(
                                          '/chat/room/trade-status?itemId=${viewModel.itemId}',
                                        );
                                      }
                                    }
                                  }
                                : null,
                            onTradeResultTap:
                                viewModel.isTopBidder &&
                                        (tradeStatusCode != 550)
                                    ? () {
                                        // 거래 결과 (완료/취소) 선택 바텀시트
                                        _showTradeActionBottomSheet(
                                          context,
                                          viewModel,
                                        );
                                      }
                                    : null,
                          );
                        },
                      ),
                      Expanded(child: ChatMessageList(viewModel: viewModel)),
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
        debugPrint('[ChattingRoomScreen] User confirmed trade completion');
        // 로딩 표시
        if (!context.mounted) return;
        debugPrint('[ChattingRoomScreen] Showing snackbar');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('거래 완료 처리 중...'),
            duration: Duration(seconds: 1),
          ),
        );
        debugPrint('[ChattingRoomScreen] SnackBar shown, calling completeTrade');

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
          debugPrint('[ChattingRoomScreen] completeTrade caught error: $e');
          if (!context.mounted) return;

          String errorMessage = '거래 완료 처리 중 오류가 발생했습니다: ${e.toString()}';
          if (e.toString().contains('Cannot complete') || e.toString().contains('already')) {
             errorMessage = '이미 완료되었거나 취소된 거래입니다.';
          }

          // 에러 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
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
                _processTradeCancel(
                  context,
                  viewModel,
                  reasonCode,
                  isSellerFault,
                );
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
    debugPrint('[ChattingRoomScreen] _processTradeCancel called reason=$reasonCode fault=$isSellerFault');
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

      String errorMessage = '거래 취소 처리 중 오류가 발생했습니다: ${e.toString()}';
      if (e.toString().contains('Cannot cancel completed trade')) {
         errorMessage = '이미 완료된 거래입니다.';
      }

      // 에러 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
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
