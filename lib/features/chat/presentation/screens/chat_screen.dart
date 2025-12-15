import 'dart:async';

import 'package:bidbird/core/router/app_router.dart';
import 'package:bidbird/core/utils/extension/time_extension.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/role_badge.dart';
import 'package:bidbird/core/widgets/notification_button.dart';
import 'package:bidbird/features/chat/presentation/viewmodels/chat_list_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with RouteAware, WidgetsBindingObserver {
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
  }

  @override
  void dispose() {
    _periodicRefreshTimer?.cancel();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    // ViewModel dispose는 Provider가 자동으로 처리
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
    _refreshListOnce();
  }

  void _refreshListIfNeeded() {
    if (!mounted || !_isViewModelInitialized || _viewModel == null) return;

    final now = DateTime.now();
    if (_lastRefreshTime != null &&
        now.difference(_lastRefreshTime!).inMilliseconds < 500) {
      return;
    }
    _lastRefreshTime = now;

    _refreshListOnce();
  }

  void _refreshListOnce() {
    if (!mounted || !_isViewModelInitialized || _viewModel == null) return;

    _viewModel!.reloadList();
  }

  @override
  Widget build(BuildContext context) {
    // 경로 변경 감지 (채팅방에서 나올 때)
    final currentRoute = GoRouterState.of(context).uri.toString();

    // 채팅 리스트 화면으로 돌아왔을 때 (채팅방에서 나왔을 때)
    if (currentRoute == '/chat') {
      final previousRoute = _previousRoute;
      if (previousRoute != null && previousRoute.startsWith('/chat/room')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // 즉시 한 번만 새로고침
            _refreshListOnce();
          }
        });
      }
    }

    _previousRoute = currentRoute;

    // ViewModel이 아직 초기화되지 않았으면 로딩 표시
    if (!_isViewModelInitialized || _viewModel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                children: [Text('채팅'), NotificationButton()],
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

    // 반응형: 큰 화면에서는 최대 너비 제한 및 중앙 정렬
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 800;
    final maxWidth = isLargeScreen ? 800.0 : double.infinity;
    final horizontalPadding = context.hPadding;
    final verticalPadding = context.vPadding;
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          itemCount: viewModel.chattingRoomList.length,
          separatorBuilder: (_, __) => SizedBox(height: context.spacingSmall),
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
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 좌측 역할 인디케이터 스트립
                  Builder(
                    builder: (context) {
                      final itemId = chattingRoom.itemId;
                      final isSeller = viewModel.isSeller(itemId);
                      final isTopBidder = viewModel.isTopBidder(itemId);
                      final isOpponentTopBidder = viewModel.isOpponentTopBidder(itemId);
                      
                      // 낙찰자/낙찰인 경우 노란색
                      final Color roleColor;
                      if ((!isSeller && isTopBidder) || (isSeller && isOpponentTopBidder)) {
                        roleColor = yellowColor;
                      } else {
                        roleColor = isSeller ? roleSalePrimary : rolePurchasePrimary;
                      }
                      
                      return Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: roleColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(defaultRadius),
                            bottomLeft: Radius.circular(defaultRadius),
                          ),
                        ),
                      );
                    },
                  ),
                  // 메인 컨텐츠
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(context.screenPadding),
                      child: Row(
                        spacing: context.spacingSmall,
                        children: [
                          CircleAvatar(
                            radius: context.isLargeScreen() ? 28 : 24,
                            backgroundColor: BorderColor,
                            backgroundImage:
                                chattingRoom.profileImage != null &&
                                    chattingRoom.profileImage!.isNotEmpty
                                ? NetworkImage(chattingRoom.profileImage!)
                                : null,
                            child:
                                chattingRoom.profileImage != null &&
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
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: Builder(
                                              builder: (context) {
                                                final itemId = chattingRoom.itemId;
                                                final isSeller = viewModel.isSeller(itemId);
                                                final isTopBidder = viewModel.isTopBidder(itemId);
                                                final isOpponentTopBidder = viewModel.isOpponentTopBidder(itemId);
                                                
                                                return RoleBadge(
                                                  isSeller: isSeller,
                                                  isTopBidder: isTopBidder,
                                                  isOpponentTopBidder: isOpponentTopBidder,
                                                );
                                              },
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              chattingRoom.itemTitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: context.fontSizeLarge,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      chattingRoom.lastMessageSendAt.toTimesAgo(),
                                      style: TextStyle(
                                        color: iconColor,
                                        fontSize: context.fontSizeSmall,
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
                                            chattingRoom.lastMessage.replaceAll(RegExp(r'\s*\(?\s*낙찰자\s*\)?\s*'), ''),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: context.fontSizeMedium,
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        if (chattingRoom.count! > 0)
                                          Padding(
                                            padding: EdgeInsets.only(left: context.spacingSmall),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: context.spacingSmall,
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
                                                  fontSize: context.fontSizeSmall,
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
        ),
      ),
    );
  }
}
