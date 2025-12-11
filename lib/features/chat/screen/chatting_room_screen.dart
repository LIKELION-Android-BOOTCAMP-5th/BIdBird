import 'dart:io';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/router/app_router.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bidbird/features/chat/screen/widgets/message_bubble.dart';
import 'package:bidbird/features/chat/viewmodel/chatting_room_viewmodel.dart';
import 'package:bidbird/features/item/detail/screen/item_detail_utils.dart';
import 'package:flutter/material.dart';
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
    // Provider가 만들어졌다면 leaveRoom 실행

    if (viewModel.roomId != null) {
      viewModel.leaveRoom();
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
      viewModel.leaveRoom();
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
              backgroundColor: BackgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0.5,
                titleSpacing: 0,
                title: Row(
                  children: [
                    const SizedBox(width: 4),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: yellowColor,
                      child: Text(
                        (viewModel.roomInfo?.opponent.nickName ?? '로딩중')
                            .substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        viewModel.roomInfo?.opponent.nickName ?? "로딩중",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
                              ? "알림 설정 : ${viewModel.notificationSetting?.is_notification_on == true ? "ON" : "OFF"}"
                              : "알림 설정 불가능",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: defaultBorder,
                        boxShadow: const [
                          BoxShadow(
                            color: shadowLow,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        spacing: 16,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              border: Border.all(
                                color: iconColor.withValues(alpha: 0.2),
                                width: 1,
                              ),
                              borderRadius: defaultBorder,
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: defaultBorder,
                                child:
                                    viewModel.itemInfo?.thumbnailImage != null
                                    ? CachedNetworkImage(
                                        imageUrl: viewModel
                                                .itemInfo?.thumbnailImage ??
                                            "",
                                        cacheManager:
                                            ItemImageCacheManager.instance,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  viewModel.itemInfo?.title ?? "로딩중",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  viewModel.auctionInfo?.currentPrice == null
                                      ? "로딩중"
                                      : "${formatPrice(viewModel.auctionInfo!.currentPrice)}원",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: viewModel.scrollController,
                      itemCount: viewModel.messages.length,
                      itemBuilder: (context, index) {
                        final message = viewModel.messages[index];
                        final userId = SupabaseManager
                            .shared
                            .supabase
                            .auth
                            .currentUser
                            ?.id;
                        final isCurrentUser = message.sender_id == userId;

                        // 같은 사람이 연속해서 보낸 메시지 중 마지막인지 여부
                        final bool isLastFromSameSender;
                        if (index == viewModel.messages.length - 1) {
                          isLastFromSameSender = true;
                        } else {
                          final nextMessage = viewModel.messages[index + 1];
                          isLastFromSameSender =
                              nextMessage.sender_id != message.sender_id;
                        }

                        return MessageBubble(
                          message: message,
                          isCurrentUser: isCurrentUser,
                          showTime: isLastFromSameSender,
                        );
                      },
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
                              color: Colors.grey[300],
                              borderRadius: defaultBorder,
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
                                    ),
                                    textAlignVertical: TextAlignVertical.center,
                                    decoration: const InputDecoration(
                                      hintText: "메시지를 입력하세요",
                                      border: InputBorder.none,
                                      isCollapsed: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      suffixIcon: Icon(
                                        Icons.add,
                                        size: 20,
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
                              color: blueColor,
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
