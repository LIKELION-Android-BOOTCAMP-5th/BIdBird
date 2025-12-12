import 'package:bidbird/core/router/app_router.dart';
import 'package:bidbird/core/utils/extension/time_extension.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/icons_style.dart';
import 'package:bidbird/features/chat/presentation/viewmodels/chat_list_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with RouteAware, WidgetsBindingObserver {
  String? _previousRoute;
  DateTime? _lastRefreshTime;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 다시 활성화될 때 리스트 새로고침
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshListIfNeeded();
    }
  }

  // 이전 화면에서 돌아왔을 때 (채팅방에서 돌아올 때)
  @override
  void didPopNext() {
    // ignore: avoid_print
    print("didPopNext: 채팅 리스트 새로고침 시작");
    _refreshListIfNeeded();
  }

  void _refreshListIfNeeded() {
    if (!mounted) return;
    
    // 너무 자주 새로고침하지 않도록 제한 (500ms 이내 중복 방지)
    final now = DateTime.now();
    if (_lastRefreshTime != null && 
        now.difference(_lastRefreshTime!).inMilliseconds < 500) {
      // ignore: avoid_print
      print("새로고침 스킵: 너무 최근에 새로고침됨");
      return;
    }
    _lastRefreshTime = now;
    
    final viewModel = context.read<ChatListViewmodel>();
    
    // ignore: avoid_print
    print("채팅 리스트 새로고침 시작");
    
    // 즉시 한 번 업데이트 (실시간 업데이트와 함께)
    viewModel.reloadList();
    
    // 첫 번째 재시도: 200ms 후
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        // ignore: avoid_print
        print("채팅 리스트 새로고침: 첫 번째 재시도 (200ms)");
        viewModel.reloadList();
      }
    });
    
    // 두 번째 재시도: 500ms 후
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // ignore: avoid_print
        print("채팅 리스트 새로고침: 두 번째 재시도 (500ms)");
        viewModel.reloadList();
      }
    });
    
    // 세 번째 재시도: 1000ms 후 (서버 처리 지연 대비)
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        // ignore: avoid_print
        print("채팅 리스트 새로고침: 세 번째 재시도 (1000ms)");
        viewModel.reloadList();
      }
    });
    
    // 네 번째 재시도: 2000ms 후 (서버 처리 지연 대비)
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        // ignore: avoid_print
        print("채팅 리스트 새로고침: 네 번째 재시도 (2000ms)");
        viewModel.reloadList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 경로 변경 감지 (build에서 확인)
    final currentRoute = GoRouterState.of(context).uri.toString();
    if (_previousRoute != null && 
        _previousRoute!.startsWith('/chat/room') && 
        currentRoute == '/chat') {
      // 채팅방에서 채팅 리스트로 돌아왔을 때
      // ignore: avoid_print
      print("경로 변경 감지 (build): 채팅방 -> 채팅 리스트, 리스트 새로고침 시작");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshListIfNeeded();
        }
      });
    }
    _previousRoute = currentRoute;
    
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
            context.push(
              '/chat/room?itemId=${chattingRoom.itemId}&roomId=${chattingRoom.id}',
            );
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
                  radius: 24,
                  backgroundColor: BorderColor,
                  backgroundImage: chattingRoom.profileImage != null &&
                          chattingRoom.profileImage!.isNotEmpty
                      ? NetworkImage(chattingRoom.profileImage!)
                      : null,
                  child: chattingRoom.profileImage != null &&
                          chattingRoom.profileImage!.isNotEmpty
                      ? null
                      : const Icon(Icons.person, color: BackgroundColor),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 매물 제목과 시간을 같은 줄에 수평 정렬
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              chattingRoom.itemTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            chattingRoom.lastMessageSendAt.toTimesAgo(),
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      // 메시지 내용과 안 읽은 메시지 수를 같은 줄에 수평 정렬
                      if (chattingRoom.lastMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  chattingRoom.lastMessage,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              if (chattingRoom.count! > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: blueColor,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Text(
                                      "${chattingRoom.count ?? 0}",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
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
              ],
            ),
          ),
        );
      },
    );
  }
}
