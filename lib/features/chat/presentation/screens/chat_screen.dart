import 'dart:async';

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
  Timer? _periodicRefreshTimer;
  ChatListViewmodel? _viewModel;
  bool _isViewModelInitialized = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    
    // ViewModel을 한 번만 생성하여 실시간 구독이 끊기지 않도록 함
    if (!_isViewModelInitialized) {
      _viewModel = ChatListViewmodel(context);
      _isViewModelInitialized = true;
    }

    final currentRoute = GoRouterState.of(context).uri.toString();
    if (currentRoute == '/chat') {
      _startPeriodicRefresh();
    } else {
      _stopPeriodicRefresh();
    }
  }

  @override
  void dispose() {
    _stopPeriodicRefresh();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    // ViewModel dispose는 Provider가 자동으로 처리
    super.dispose();
  }

  void _startPeriodicRefresh() {
    _stopPeriodicRefresh();
    _periodicRefreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        _stopPeriodicRefresh();
        return;
      }
      // ignore: avoid_print
      print("주기적 리스트 새로고침 (2초마다)");
      _refreshListOnce();
    });
  }

  void _stopPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = null;
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
    print("didPopNext: 채팅방에서 나옴 - leaveRoom 완료 후 서버 업데이트 반영 대기");
    // leaveRoom()이 완료되고 서버에서 unread_count가 업데이트될 시간을 주기 위해
    // 지연 후 한 번만 새로고침 (서버 처리 지연 대비)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _refreshListOnce();
      }
    });
  }

  void _refreshListIfNeeded() {
    if (!mounted || !_isViewModelInitialized || _viewModel == null) return;

    final now = DateTime.now();
    if (_lastRefreshTime != null && 
        now.difference(_lastRefreshTime!).inMilliseconds < 500) {
      // ignore: avoid_print
      print("새로고침 스킵: 너무 최근에 새로고침됨");
      return;
    }
    _lastRefreshTime = now;
    
    _refreshListOnce();
  }

  void _refreshListOnce() {
    if (!mounted || !_isViewModelInitialized || _viewModel == null) return;
    
    // ignore: avoid_print
    print("채팅 리스트 새로고침 시작");
    _viewModel!.reloadList();
  }

  @override
  Widget build(BuildContext context) {
    // 경로 추적 (로깅용)
    final currentRoute = GoRouterState.of(context).uri.toString();
    _previousRoute = currentRoute;
    
    // ViewModel이 아직 초기화되지 않았으면 로딩 표시
    if (!_isViewModelInitialized || _viewModel == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // ViewModel을 한 번만 생성하여 실시간 구독이 끊기지 않도록 함
    return ChangeNotifierProvider.value(
      value: _viewModel!,
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
