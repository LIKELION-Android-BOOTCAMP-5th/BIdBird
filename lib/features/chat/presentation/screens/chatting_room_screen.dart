import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/router/app_router.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/image_source_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/core/widgets/chat/trade_cancel_reason_bottom_sheet.dart';
import 'package:bidbird/core/widgets/chat/trade_context_card.dart';
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
    // 채팅방을 나갈 때 읽음 처리를 위해 disposeViewModel 호출
    if (viewModel.roomId != null && viewModel.isActive) {
      // disposeViewModel에서 leaveRoom을 호출하여 읽음 처리
      // dispose는 동기 메서드이므로 Future를 기다릴 수 없지만,
      // disposeViewModel 내부에서 leaveRoom이 완료될 때까지 기다리도록 처리
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
      // dispose에서도 leaveRoom이 호출되지만, 명시적으로 호출하여 읽음 처리 보장
      // leaveRoom이 완료되도록 기다림 (비동기이지만 완료를 보장)
      viewModel
          .leaveRoom()
          .then((_) {
            // leaveRoom 완료
          })
          .catchError((e) {});
    }
  }

  // 화면이 비활성화될 때 (다른 화면으로 이동)
  @override
  void didPushNext() {
    if (viewModel.roomId != null) {
      // 다른 화면으로 이동할 때도 읽음 처리
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

                      // 거래 완료 상태에서는 거래 취소 옵션 제거
                      final canShowTradeCancel = viewModel.tradeInfo != null &&
                          viewModel.tradeInfo!.tradeStatusCode != 550;

                      return TradeContextCard(
                        itemTitle: viewModel.itemInfo?.title ?? "로딩중",
                        itemThumbnail: viewModel.itemInfo?.thumbnailImage,
                        itemPrice: viewModel.auctionInfo?.currentPrice ?? 0,
                        isSeller: isSeller,
                        tradeStatus: tradeStatusText,
                        tradeStatusCode: viewModel.tradeInfo?.tradeStatusCode,
                        hasShippingInfo: viewModel.hasShippingInfo,
                        onCardTap: () {
                          if (viewModel.itemId.isNotEmpty) {
                            context.push('/item/${viewModel.itemId}');
                          }
                        },
                        onTradeComplete: viewModel.tradeInfo != null &&
                                viewModel.tradeInfo!.tradeStatusCode != 550
                            ? () {
                                // 거래 완료 액션
                                _showTradeCompleteDialog(context, viewModel);
                              }
                            : null,
                        onTradeCancel: canShowTradeCancel
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
    showDialog(
      context: context,
      builder: (dialogContext) => AskPopup(
        content: '거래를 완료하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
        noText: '취소',
        yesText: '완료',
        yesLogic: () async {
          Navigator.of(dialogContext).pop();
          // TODO: 거래 완료 API 호출
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('거래 완료 기능은 준비 중입니다.')),
          );
        },
      ),
    );
  }

  /// 거래 취소 사유 선택 후 확인 다이얼로그 표시
  void _showTradeCancelWithReason(
    BuildContext context,
    ChattingRoomViewmodel viewModel,
  ) {
    // 1단계: 사유 선택 바텀시트
    TradeCancelReasonBottomSheet.show(
      context,
      onReasonSelected: (reasonCode) {
        // 2단계: 확인 다이얼로그
        _showTradeCancelConfirmDialog(context, viewModel, reasonCode);
      },
    );
  }

  /// 거래 취소 확인 다이얼로그 표시
  void _showTradeCancelConfirmDialog(
    BuildContext context,
    ChattingRoomViewmodel viewModel,
    String reasonCode,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('거래 취소'),
        content: const Text(
          '거래를 취소하시겠습니까?\n취소 사유가 상대에게 전달됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('돌아가기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // TODO: 거래 취소 API 호출 (reasonCode 포함)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('거래 취소 기능은 준비 중입니다. (사유: $reasonCode)'),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: RedColor,
            ),
            child: const Text('거래 취소'),
          ),
        ],
      ),
    );
  }
}
