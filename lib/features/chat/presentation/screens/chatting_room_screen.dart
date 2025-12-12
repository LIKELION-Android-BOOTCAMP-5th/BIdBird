import 'dart:io';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/router/app_router.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bidbird/features/chat/presentation/widgets/message_bubble.dart';
import 'package:bidbird/features/chat/presentation/viewmodels/chatting_room_viewmodel.dart';
import 'package:bidbird/features/item/detail/screen/item_detail_utils.dart';
import 'package:flutter/material.dart';
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

  void _showImageSourceSheet(
    BuildContext context,
    ChattingRoomViewmodel viewModel,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(defaultRadius),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('갤러리에서 선택'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await viewModel.pickImagesFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('사진 찍기'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await viewModel.pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  late ChattingRoomViewmodel viewModel;
  @override
  void initState() {
    super.initState();
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
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    // 채팅방을 나갈 때 읽음 처리를 위해 disposeViewModel 호출
    if (viewModel.roomId != null && viewModel.isActive) {
      // disposeViewModel에서 leaveRoom을 호출하여 읽음 처리
      // dispose는 동기 메서드이므로 Future를 기다릴 수 없지만, 
      // disposeViewModel 내부에서 leaveRoom이 완료될 때까지 기다리도록 처리
      viewModel.disposeViewModel().catchError((e) {
        // ignore: avoid_print
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
      viewModel.leaveRoom().then((_) {
        // leaveRoom 완료 후 약간의 지연을 두고 실시간 업데이트가 반영되도록 함
        // ignore: avoid_print
        print("didPop: leaveRoom 완료");
      }).catchError((e) {
        // ignore: avoid_print
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
                title: Text(
                  viewModel.roomInfo?.opponent.nickName ?? "로딩중",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  PopupMenuButton(
                    color: BorderColor,
                    iconColor: textColor,
                    itemBuilder: (context) => [
                      PopupMenuItem(onTap: () {}, child: Text("차단")),
                      PopupMenuItem(onTap: () {}, child: Text("신고")),
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
                  // 매물 정보 섹션
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: chatItemCardBackground,
                      boxShadow: const [
                        BoxShadow(
                          color: shadowLow,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      spacing: 16,
                      children: [
                        if (viewModel.itemInfo?.thumbnailImage != null &&
                            viewModel.itemInfo!.thumbnailImage!.isNotEmpty)
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: ImageBackgroundColor,
                              borderRadius: defaultBorder,
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: defaultBorder,
                                child: CachedNetworkImage(
                                  imageUrl:
                                      viewModel.itemInfo!.thumbnailImage!,
                                  cacheManager:
                                      ItemImageCacheManager.instance,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                color: ImageBackgroundColor,
                                borderRadius: defaultBorder,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                viewModel.itemInfo?.title ?? "로딩중",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: chatTextColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                viewModel.auctionInfo?.currentPrice == null
                                    ? "로딩중"
                                    : "${formatPrice(viewModel.auctionInfo!.currentPrice)}원",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: chatTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: viewModel.isScrollPositionReady ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 0), // 즉시 표시 (애니메이션 없음)
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
                          physics: viewModel.listViewPhysics ?? const ClampingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final message = viewModel.messages[index];
                        final userId = SupabaseManager.shared.supabase.auth.currentUser?.id;
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
                          currentDate =
                              DateTime.parse(message.createdAt).toLocal();
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
                          showDateHeader = !isSameDay(currentDate, previousDate);
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
                          for (int i = viewModel.messages.length - 1; i >= 0; i--) {
                            if (viewModel.messages[i].senderId == userId) {
                              lastMyMessageIndex = i;
                              break;
                            }
                          }
                          
                          // 상대방이 읽은 가장 최근 내 메시지의 인덱스 찾기
                          // 상대방이 메시지를 보낸 시점 이전의 마지막 내 메시지
                          int? lastReadMyMessageIndex;
                          for (int i = viewModel.messages.length - 1; i >= 0; i--) {
                            // 상대방 메시지를 찾으면, 그 이전의 마지막 내 메시지가 가장 최근에 읽은 메시지
                            if (viewModel.messages[i].senderId != userId) {
                              // 상대방 메시지 이전의 내 메시지 찾기
                              for (int j = i - 1; j >= 0; j--) {
                                if (viewModel.messages[j].senderId == userId) {
                                  lastReadMyMessageIndex = j;
                                  break;
                                }
                              }
                              break;
                            }
                          }
                          
                          // 현재 메시지가 마지막 내 메시지인지 확인
                          final isLastMyMessage = lastMyMessageIndex != null && index == lastMyMessageIndex;
                          
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
                            if (lastReadMyMessageIndex != null && index == lastReadMyMessageIndex) {
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
                            final String? profileImageUrl = opponent?.profileImage;
                              avatarWidget = CircleAvatar(
                                radius: avatarSize / 2,
                              backgroundColor: BorderColor,
                              backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                              child: profileImageUrl != null && profileImageUrl.isNotEmpty
                                  ? null
                                  : const Icon(Icons.person, color: BackgroundColor),
                              );
                          } else {
                            avatarWidget = const SizedBox(
                              width: avatarSize,
                              height: avatarSize,
                            );
                          }

                          messageWidget = Padding(
                            padding: EdgeInsets.only(
                              left: 8,
                              right: 8,
                              top: isFirstFromSameSender ? 10 : 4,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                avatarWidget,
                                const SizedBox(width: 0),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: _ChatDateSeparator(date: currentDate),
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
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: chatInputBackground,
                              borderRadius: defaultBorder,
                              border: Border.all(
                                color: chatPlusIconColor,
                                width: 1,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: shadowLow,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: viewModel.image == null
                                ? TextField(
                                    minLines: 1,
                                    maxLines: 1,
                                    controller: viewModel.messageController,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: chatTextColor,
                                    ),
                                    textAlignVertical: TextAlignVertical.center,
                                    decoration: InputDecoration(
                                      hintText: "메시지를 입력하세요",
                                      hintStyle: TextStyle(
                                        color: chatTimeTextColor,
                                      ),
                                      border: InputBorder.none,
                                      isCollapsed: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: const Icon(
                                          Icons.add,
                                          size: 20,
                                          color: chatPlusIconColor,
                                        ),
                                        onPressed: () {
                                          _showImageSourceSheet(
                                            context,
                                            viewModel,
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                : Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: defaultBorder,
                                        child: AspectRatio(
                                          aspectRatio:
                                              viewModel.imageAspectRatio ?? 1,
                                          child: Image.file(
                                            File(viewModel.image!.path),
                                            fit: BoxFit.cover,
                                            width: 150,
                                            height: 150,
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
                                              color: Colors.black
                                                  .withValues(alpha: 0.5),
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
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            if (!viewModel.isSending) {
                              viewModel.sendMessage();
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: brandBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: viewModel.isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ],
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
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
