import 'package:bidbird/core/utils/extension/time_extension.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/fonts_style.dart';
import 'package:bidbird/core/utils/ui_set/icons_style.dart';
import 'package:bidbird/features/chat/viewmodel/chat_list_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatListViewmodel(context),
      child: Consumer<ChatListViewmodel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('채팅'),
                  Image.asset(
                    'assets/icons/alarm_icon.png',
                    width: iconSize.width,
                    height: iconSize.height,
                  ),
                ],
              ),
            ),
            backgroundColor: BackgroundColor,
            body: SafeArea(child: _buildBody(context, viewModel)),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ChatListViewmodel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    //
    // if (viewModel.error != null) {
    //   return Center(
    //     child: Text(viewModel.error!, style: const TextStyle(fontSize: 14)),
    //   );
    // }
    //
    if (viewModel.chattingRoomList.isEmpty) {
      return const Center(child: Text('참여 중인 채팅방이 없습니다.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: viewModel.chattingRoomList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final chattingRoom = viewModel.chattingRoomList[index];
        return GestureDetector(
          onTap: () {
            context.push('/chat/room?itemId=${chattingRoom.item_id}');
          },
          child: Container(
            decoration: BoxDecoration(
              color: BackgroundColor,
              border: Border.all(
                color: iconColor.withValues(alpha: 0.2),
                width: 1,
              ),
              borderRadius: defaultBorder,
              boxShadow: const [
                BoxShadow(
                  color: shadowHigh,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
                BoxShadow(
                  color: shadowLow,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              spacing: 8,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: yellowColor,
                  backgroundImage: chattingRoom.profile_image != null
                      ? NetworkImage(chattingRoom.profile_image!)
                      : null,
                  child: chattingRoom.profile_image != null
                      ? null
                      : SizedBox(
                          width: 35,
                          height: 35,
                          child: FittedBox(
                            child: Icon(Icons.person, color: BackgroundColor),
                          ),
                        ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "${chattingRoom.user_nickname ?? "사용자"}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            chattingRoom.last_message_send_at.toTimesAgo(),
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        chattingRoom.last_message,
                        style: contentFontStyle,
                        textAlign: TextAlign.left,
                      ),
                      Row(
                        children: [
                          IntrinsicWidth(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                spacing: 3,
                                children: [
                                  Text(
                                    "${chattingRoom.item_title}",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (chattingRoom.count! > 0)
                            Text('${chattingRoom.count}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
