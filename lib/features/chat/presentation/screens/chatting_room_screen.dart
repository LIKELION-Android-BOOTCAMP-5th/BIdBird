import 'dart:io';

import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/router/app_router.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/components/bottom_sheet/image_source_bottom_sheet.dart';
import 'package:bidbird/core/widgets/components/role_badge.dart';
import 'package:bidbird/core/widgets/chat/trade_cancel_reason_bottom_sheet.dart';
import 'package:bidbird/core/widgets/chat/trade_context_card.dart';
import 'package:bidbird/core/widgets/video_player_widget.dart';
import 'package:bidbird/features/chat/presentation/viewmodels/chatting_room_viewmodel.dart';
import 'package:bidbird/features/chat/presentation/widgets/message_bubble.dart';
import 'package:bidbird/features/report/screen/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
      viewModel.disposeViewModel().catchError((e) {
        print("dispose에서 disposeViewModel 실패: $e");
      });
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
            // leaveRoom 완료 후 약간의 지연을 두고 실시간 업데이트가 반영되도록 함
            print("didPop: leaveRoom 완료");
          })
          .catchError((e) {
            print("didPop: leaveRoom 실패: $e");
          });
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
          return SafeArea(
            child: Scaffold(
              backgroundColor: chatBackgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0.5,
                titleSpacing: 0,
                title: Builder(
                  builder: (context) {
                    // 현재 사용자가 판매자인지 확인
                    final currentUserId = SupabaseManager
                        .shared
                        .supabase
                        .auth
                        .currentUser
                        ?.id;
                    final isSeller = currentUserId != null &&
                        viewModel.itemInfo != null &&
                        viewModel.itemInfo!.sellerId == currentUserId;
                    
                    // 낙찰자 여부 확인
                    final isTopBidder = viewModel.isTopBidder;
                    final isOpponentTopBidder = isSeller && !isTopBidder && viewModel.hasTopBidder;
                    
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            viewModel.roomInfo != null
                                ? viewModel.roomInfo?.opponent.nickName ?? "사용자"
                                : "로딩중",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isTopBidder || isOpponentTopBidder)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: RoleBadge(
                              isSeller: isSeller,
                              isTopBidder: isTopBidder,
                              isOpponentTopBidder: isOpponentTopBidder,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                actions: [
                  PopupMenuButton(
                    color: BorderColor,
                    iconColor: textColor,
                    itemBuilder: (context) => [
                      PopupMenuItem(onTap: () {}, child: Text("차단")),
                      PopupMenuItem(
                        onTap: () {
                          Navigator.of(context).pop();
                          if (viewModel.roomInfo != null) {
                            // 상대방 ID 찾기: itemInfo의 sellerId와 현재 사용자 비교
                            final currentUserId = SupabaseManager
                                .shared
                                .supabase
                                .auth
                                .currentUser
                                ?.id;
                            String? targetUserId;
                            
                            if (currentUserId != null && viewModel.itemInfo != null) {
                              // 현재 사용자가 판매자가 아니면 판매자를, 판매자면 buyer를 찾아야 함
                              // 일단 판매자를 상대방으로 가정 (채팅방에서는 보통 상대방이 판매자)
                              if (viewModel.itemInfo!.sellerId != currentUserId) {
                                targetUserId = viewModel.itemInfo!.sellerId;
                              } else {
                                // 현재 사용자가 판매자인 경우, buyer_id를 찾아야 함
                                // tradeInfo에서 buyerId를 가져올 수 있음
                                targetUserId = viewModel.tradeInfo?.buyerId;
                              }
                            }
                            
                            if (targetUserId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReportScreen(
                                    itemId: viewModel.itemId,
                                    itemTitle: viewModel.itemInfo?.title,
                                    targetUserId: targetUserId!,
                                    targetNickname: viewModel.roomInfo!.opponent.nickName,
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: Text("신고"),
                      ),
                      PopupMenuItem(
                        onTap: () {
                          if (viewModel.notificationSetting != null) {
                            viewModel.notificationToggle();
                          }
                        },
                        child: Text(
                          viewModel.notificationSetting != null
                              ? "알림 설정 : ${viewModel.notificationSetting?.isNotificationOn == true ? "ON" : "OFF"}"
                              : "알림 설정 불가능",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: Column(
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
                    child: AnimatedOpacity(
                      opacity: viewModel.isScrollPositionReady ? 1.0 : 0.0,
                      duration: const Duration(
                        milliseconds: 0,
                      ), // 즉시 표시 (애니메이션 없음)
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollEndNotification) {
                            // 초기 로드가 아닐 때만 스크롤 처리 (사용자가 수동으로 스크롤한 경우)
                            // 스크롤이 끝났을 때 roomInfo를 업데이트하여 unreadCount 변경 감지 (디바운스 적용)
                            viewModel.fetchRoomInfoDebounced();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: viewModel.scrollController,
                          itemCount: viewModel.messages.length,
                          reverse: false,
                          cacheExtent: 0,
                          padding: const EdgeInsets.only(bottom: 16),
                          physics:
                              viewModel.listViewPhysics ??
                              const ClampingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final message = viewModel.messages[index];
                            final userId = SupabaseManager
                                .shared
                                .supabase
                                .auth
                                .currentUser
                                ?.id;
                            final isCurrentUser = message.senderId == userId;

                            // 같은 사람이 연속해서 보낸 메시지 중 마지막인지 여부 (시간 표시용)
                            final bool isLastFromSameSender;
                            if (index == viewModel.messages.length - 1) {
                              isLastFromSameSender = true;
                            } else {
                              final nextMessage = viewModel.messages[index + 1];
                              isLastFromSameSender =
                                  nextMessage.senderId != message.senderId;
                            }

                            // 같은 사람이 연속해서 보낸 메시지 중 첫 번째인지 여부 (아바타 표시용)
                            final bool isFirstFromSameSender;
                            if (index == 0) {
                              isFirstFromSameSender = true;
                            } else {
                              final prevMessage = viewModel.messages[index - 1];
                              isFirstFromSameSender =
                                  prevMessage.senderId != message.senderId;
                            }

                            // 날짜 구분 표시 여부 계산
                            DateTime? currentDate;
                            DateTime? previousDate;
                            try {
                              currentDate = DateTime.parse(
                                message.createdAt,
                              ).toLocal();
                              if (index > 0) {
                                previousDate = DateTime.parse(
                                  viewModel.messages[index - 1].createdAt,
                                ).toLocal();
                              }
                            } catch (_) {
                              currentDate = null;
                              previousDate = null;
                            }

                            bool isSameDay(DateTime a, DateTime b) {
                              return a.year == b.year &&
                                  a.month == b.month &&
                                  a.day == b.day;
                            }

                            final bool showDateHeader;
                            if (currentDate == null) {
                              showDateHeader = false;
                            } else if (previousDate == null) {
                              // 첫 번째 메시지는 항상 날짜 표시
                              showDateHeader = true;
                            } else {
                              showDateHeader = !isSameDay(
                                currentDate,
                                previousDate,
                              );
                            }

                            Widget messageWidget;

                            // 메시지 읽음 여부 확인
                            bool isRead = false;
                            bool isUnread = false;

                            if (isCurrentUser && userId != null) {
                              // 내가 보낸 메시지: 상대방이 읽었는지 확인
                              // 가장 최근에 읽은 내 메시지 하나에만 읽음 표시
                              // 마지막 내 메시지가 아직 읽지 않았다면 안읽음 표시

                              // 마지막 내 메시지의 인덱스 찾기
                              int? lastMyMessageIndex;
                              for (
                                int i = viewModel.messages.length - 1;
                                i >= 0;
                                i--
                              ) {
                                if (viewModel.messages[i].senderId == userId) {
                                  lastMyMessageIndex = i;
                                  break;
                                }
                              }

                              // 상대방이 읽은 가장 최근 내 메시지의 인덱스 찾기
                              // 상대방이 메시지를 보낸 시점 이전의 마지막 내 메시지
                              int? lastReadMyMessageIndex;
                              for (
                                int i = viewModel.messages.length - 1;
                                i >= 0;
                                i--
                              ) {
                                // 상대방 메시지를 찾으면, 그 이전의 마지막 내 메시지가 가장 최근에 읽은 메시지
                                if (viewModel.messages[i].senderId != userId) {
                                  // 상대방 메시지 이전의 내 메시지 찾기
                                  for (int j = i - 1; j >= 0; j--) {
                                    if (viewModel.messages[j].senderId ==
                                        userId) {
                                      lastReadMyMessageIndex = j;
                                      break;
                                    }
                                  }
                                  break;
                                }
                              }

                              // 현재 메시지가 마지막 내 메시지인지 확인
                              final isLastMyMessage =
                                  lastMyMessageIndex != null &&
                                  index == lastMyMessageIndex;

                              if (isLastMyMessage) {
                                // 마지막 내 메시지인 경우
                                if (lastReadMyMessageIndex == null) {
                                  // 상대방이 아직 메시지를 보내지 않았거나, 모든 내 메시지가 읽지 않은 것
                                  isUnread = true;
                                } else if (lastReadMyMessageIndex < index) {
                                  // 마지막 내 메시지가 읽지 않은 것 (상대방이 읽은 마지막 메시지보다 나중)
                                  isUnread = true;
                                } else if (index == lastReadMyMessageIndex) {
                                  // 마지막 내 메시지가 가장 최근에 읽은 메시지
                                  isRead = true;
                                }
                              } else {
                                // 마지막 내 메시지가 아닌 경우
                                if (lastReadMyMessageIndex != null &&
                                    index == lastReadMyMessageIndex) {
                                  // 가장 최근에 읽은 내 메시지
                                  isRead = true;
                                }
                              }
                            }
                            // 상대방이 보낸 메시지는 읽음 표시 없음 (isRead는 이미 false)

                            // 같은 사람이 연속 보낸 경우 위 여백을 더 타이트하게
                            if (isCurrentUser) {
                              messageWidget = Padding(
                                padding: EdgeInsets.only(
                                  top: isFirstFromSameSender ? 10 : 4,
                                ),
                                child: MessageBubble(
                                  message: message,
                                  isCurrentUser: true,
                                  showTime: isLastFromSameSender,
                                  isRead: isRead,
                                  isUnread: isUnread,
                                ),
                              );
                            } else {
                              // 상대방 메시지: 왼쪽에 프로필, 오른쪽에 말풍선
                              const double avatarSize = 36;
                              final opponent = viewModel.roomInfo?.opponent;

                              Widget avatarWidget;
                              if (isFirstFromSameSender) {
                                final String? profileImageUrl =
                                    opponent?.profileImage;
                                avatarWidget = CircleAvatar(
                                  radius: avatarSize / 2,
                                  backgroundColor: BorderColor,
                                  backgroundImage:
                                      profileImageUrl != null &&
                                          profileImageUrl.isNotEmpty
                                      ? NetworkImage(profileImageUrl)
                                      : null,
                                  child:
                                      profileImageUrl != null &&
                                          profileImageUrl.isNotEmpty
                                      ? null
                                      : const Icon(
                                          Icons.person,
                                          color: BackgroundColor,
                                        ),
                                );
                              } else {
                                avatarWidget = const SizedBox(
                                  width: avatarSize,
                                  height: avatarSize,
                                );
                              }

                              messageWidget = Padding(
                                padding: EdgeInsets.only(
                                  left: 0,
                                  right: 8,
                                  top: isFirstFromSameSender ? 10 : 4,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    avatarWidget,
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: MessageBubble(
                                        message: message,
                                        isCurrentUser: false,
                                        showTime: isLastFromSameSender,
                                        isRead: isRead,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (showDateHeader && currentDate != null) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: _ChatDateSeparator(
                                      date: currentDate,
                                    ),
                                  ),
                                  messageWidget,
                                ],
                              );
                            }

                            return messageWidget;
                          },
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Builder(
                      builder: (context) {
                        // 거래 완료 상태 확인
                        final isTradeCompleted = viewModel.tradeInfo?.tradeStatusCode == 550;
                        final hasText = viewModel.messageController.text.trim().isNotEmpty;
                        
                        return Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFFFF), // 입력 영역 배경
                            border: Border(
                              top: BorderSide(
                                color: Color(0xFFE5E7EB), // 상단 divider
                                width: 1,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          child: Row(
                            children: [
                              // 왼쪽 + 버튼
                              InkWell(
                                onTap: isTradeCompleted ? null : () {
                                  _showImageSourceSheet(context, viewModel);
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isTradeCompleted
                                        ? const Color(0xFFE0E3E7)
                                        : const Color(0xFFF1F3F4),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: isTradeCompleted
                                        ? const Color(0xFF9AA0A6)
                                        : const Color(0xFF5F6368),
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 가운데 입력 필드
                              Expanded(
                                child: viewModel.image == null
                                    ? Builder(
                                        builder: (context) {
                                          final hasFocus = _inputFocusNode.hasFocus;
                                          
                                          return Container(
                                            constraints: const BoxConstraints(
                                              minHeight: 40,
                                              maxHeight: 96,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isTradeCompleted
                                                  ? const Color(0xFFF7F8FA)
                                                  : (hasFocus
                                                      ? const Color(0xFFFFFFFF)
                                                      : const Color(0xFFF5F6F8)),
                                              borderRadius: BorderRadius.circular(20),
                                              border: hasFocus
                                                  ? Border.all(
                                                      color: const Color(0xFFD0D5DD),
                                                      width: 1,
                                                    )
                                                  : null,
                                              boxShadow: hasFocus
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.06),
                                                        blurRadius: 2,
                                                        offset: const Offset(0, 1),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: TextField(
                                              focusNode: _inputFocusNode,
                                              minLines: 1,
                                              maxLines: 4,
                                              controller: viewModel.messageController,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF111111),
                                              ),
                                              textAlignVertical: TextAlignVertical.center,
                                              decoration: InputDecoration(
                                                hintText: isTradeCompleted
                                                    ? "거래 완료 후 메시지를 보낼 수 있습니다"
                                                    : "메시지를 입력하세요",
                                                hintStyle: const TextStyle(
                                                  color: Color(0xFF9AA0A6),
                                                  fontSize: 14,
                                                ),
                                                border: InputBorder.none,
                                                isCollapsed: true,
                                                contentPadding: const EdgeInsets.symmetric(
                                                  vertical: 10,
                                                ),
                                              ),
                                              onChanged: (value) {
                                                setState(() {}); // 전송 버튼 상태 업데이트
                                              },
                                              onTap: () {
                                                setState(() {}); // 포커스 상태 업데이트
                                              },
                                              onSubmitted: (value) {
                                                if (!viewModel.isSending &&
                                                    value.trim().isNotEmpty) {
                                                  // 키보드 닫기
                                                  _inputFocusNode.unfocus();
                                                  viewModel.sendMessage();
                                                  // 입력창 리셋
                                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                                    if (mounted) {
                                                      setState(() {});
                                                    }
                                                  });
                                                }
                                              },
                                            ),
                                          );
                                        },
                                      )
                                : Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(22),
                                        child: AspectRatio(
                                          aspectRatio:
                                              viewModel.imageAspectRatio ?? 1,
                                          child:
                                              isVideoFile(viewModel.image!.path)
                                              ? VideoPlayerWidget(
                                                  videoPath:
                                                      viewModel.image!.path,
                                                  autoPlay: false,
                                                  showControls: true,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.file(
                                                  File(viewModel.image!.path),
                                                  fit: BoxFit.cover,
                                                  width: 150,
                                                  height: 150,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          color:
                                                              Colors.grey[300],
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .error_outline,
                                                              color:
                                                                  Colors.grey,
                                                              size: 32,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: GestureDetector(
                                          onTap: () {
                                            viewModel.clearImage();
                                          },
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.5,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ),
                              const SizedBox(width: 8),
                              // 오른쪽 전송 버튼
                              InkWell(
                                onTap: (!hasText || viewModel.isSending)
                                    ? null
                                    : () {
                                        // 키보드 닫기
                                        FocusScope.of(context).unfocus();
                                        viewModel.sendMessage();
                                        // 입력창 리셋
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (mounted) {
                                            setState(() {});
                                          }
                                        });
                                      },
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: (!hasText || isTradeCompleted)
                                        ? const Color(0xFFE0E3E7) // Disabled
                                        : const Color(0xFF4F7CF5), // Enabled
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Center(
                                    child: viewModel.isSending
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.send,
                                            color: (!hasText || isTradeCompleted)
                                                ? const Color(0xFF9AA0A6) // Disabled
                                                : Colors.white, // Enabled
                                            size: 20,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('거래 완료'),
        content: const Text('거래를 완료하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // TODO: 거래 완료 API 호출
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('거래 완료 기능은 준비 중입니다.')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: roleSalePrimary,
            ),
            child: const Text('완료'),
          ),
        ],
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

class _ChatDateSeparator extends StatelessWidget {
  const _ChatDateSeparator({required this.date});

  final DateTime date;

  String _formatKoreanDate(DateTime dt) {
    // 예: 2025년 11월 7일 금요일
    final formatter = DateFormat('yyyy년 M월 d일 EEEE', 'ko');
    return formatter.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xffBDBDBD),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              _formatKoreanDate(date),
              style: TextStyle(color: Colors.black, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
