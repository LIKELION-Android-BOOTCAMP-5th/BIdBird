import 'dart:io';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/router/app_router.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/chat/screen/widgets/message_bubble.dart';
import 'package:bidbird/features/chat/viewmodel/chatting_room_viewmodel.dart';
import 'package:bidbird/features/item/detail/screen/item_detail_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChattingRoomScreen extends StatefulWidget {
  final String itemId;

  const ChattingRoomScreen({super.key, required this.itemId});

  @override
  State<ChattingRoomScreen> createState() => _ChattingRoomScreenState();
}

class _ChattingRoomScreenState extends State<ChattingRoomScreen>
    with RouteAware, WidgetsBindingObserver {
  bool _fabMenuOpen = false;

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
    viewModel = ChattingRoomViewmodel(itemId: widget.itemId);
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
              appBar: AppBar(
                title: Text(viewModel.roomInfo?.seller.nickName ?? "로딩중"),
                actions: [
                  PopupMenuButton(
                    color: BorderColor,
                    iconColor: textColor,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: () {
                          // viewModel.startEdit(commentIndex);
                        },
                        child: Text("수정"),
                      ),
                      PopupMenuItem(onTap: () {}, child: Text("삭제")),
                    ],
                  ),
                ],
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      child: Row(
                        spacing: 16,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: BackgroundColor,
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
                                    ? Image.network(
                                        viewModel.itemInfo?.thumbnailImage ??
                                            "",
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
                        return MessageBubble(
                          message: message,
                          isCurrentUser: isCurrentUser,
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: BorderColor,
                              borderRadius: defaultBorder,
                            ),
                            child: viewModel.image == null
                                ? TextField(
                                    minLines: 1,
                                    maxLines: null,
                                    controller: viewModel.messageController,
                                    decoration: InputDecoration(
                                      hintText: "메시지를 입력하세요",
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          _showImageSourceSheet(
                                            context,
                                            viewModel,
                                          );
                                        },
                                        icon: Icon(Icons.add),
                                      ),
                                    ),
                                  )
                                : Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: defaultBorder,
                                        child: AspectRatio(
                                          aspectRatio:
                                              viewModel.imageAspectRatio ??
                                              1, // 동적으로 계산됨
                                          child: Image.file(
                                            File(viewModel.image!.path),
                                            fit: BoxFit.cover,
                                            width: 150,
                                            height: 150,
                                          ),
                                        ),
                                      ),
                                      // 삭제 버튼 (오른쪽 상단)
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: GestureDetector(
                                          onTap: () {
                                            viewModel
                                                .clearImage(); // ViewModel 기능 추가해야 함
                                          },
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.5,
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
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (!viewModel.isSending) {
                            viewModel.sendMessage();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: blueColor,
                              borderRadius: defaultBorder,
                            ),
                            child: viewModel.isSending
                                ? CircularProgressIndicator()
                                : Icon(Icons.send, color: BackgroundColor),
                          ),
                        ),
                      ),
                    ],
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
