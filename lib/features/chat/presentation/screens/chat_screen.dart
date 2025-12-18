import 'package:bidbird/core/router/app_router.dart';
import 'package:bidbird/core/utils/extension/time_extension.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/visible_item_calculator.dart';
import 'package:bidbird/core/widgets/components/default_profile_avatar.dart';
import 'package:bidbird/core/widgets/components/loading_indicator.dart';
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

class _ChatScreenState extends State<ChatScreen> with RouteAware {
  ChatListViewmodel? _viewModel;
  bool _isViewModelInitialized = false;
  final ScrollController _scrollController = ScrollController();
  bool _isListenerAttached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);

    if (!_isViewModelInitialized) {
      // 화면 크기에 맞는 개수 계산 (코어 유틸리티 사용)
      final loadCount = VisibleItemCalculator.calculateChatListVisibleCount(context);
      
      _viewModel = ChatListViewmodel(initialLoadCount: loadCount);
      _isViewModelInitialized = true;
    }

    // 스크롤 리스너 추가 (한 번만)
    if (!_isListenerAttached && _viewModel != null) {
      _scrollController.addListener(_scrollListener);
      _isListenerAttached = true;
    }
  }

  void _scrollListener() {
    if (_viewModel == null) return;
    
    // 스크롤이 하단 근처(200px 이내)에 도달하면 더 많은 데이터 로드
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _viewModel!.loadMoreChattingRooms();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    if (_isListenerAttached) {
      _scrollController.removeListener(_scrollListener);
    }
    _scrollController.dispose();
    super.dispose();
  }

  /// 채팅방에서 돌아왔을 때 목록 새로고침
  /// 실시간 구독이 자동으로 처리하지만, 읽음 처리 후 즉시 반영을 위해 새로고침
  @override
  void didPopNext() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _viewModel != null) {
        // 화면 크기에 맞는 개수만 다시 로드 (코어 유틸리티 사용)
        final context = this.context;
        if (context.mounted) {
          final loadCount = VisibleItemCalculator.calculateChatListVisibleCount(context);
          _viewModel!.reloadList(forceRefresh: true, visibleItemCount: loadCount);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
      return const CenteredLoadingIndicator();
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
          controller: _scrollController,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          itemCount: viewModel.chattingRoomList.length + (viewModel.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, __) => SizedBox(height: context.spacingSmall),
      itemBuilder: (context, index) {
        // 로딩 인디케이터 표시
        if (index == viewModel.chattingRoomList.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        final chattingRoom = viewModel.chattingRoomList[index];
        final itemId = chattingRoom.itemId;
        final isExpired = viewModel.isTradeExpired(itemId);
        final isSeller = viewModel.isSeller(itemId);
        final isTopBidder = viewModel.isTopBidder(itemId);
        final isOpponentTopBidder = viewModel.isOpponentTopBidder(itemId);
        
        // 낙찰 물품/낙찰자는 거래 완료(550)여도 노란색 유지
        final isBidderRole = (!isSeller && isTopBidder) || (isSeller && isOpponentTopBidder);
        
        // 만료된 거래만 회색으로 표시 (낙찰 물품/낙찰자 거래 완료는 제외)
        final shouldShowGray = isExpired;
        
        return GestureDetector(
          onTap: () {
            viewModel.markRoomAsReadLocally(chattingRoom.id);
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
                      // 만료된 거래는 회색으로 표시 (단, 낙찰 물품/낙찰자 거래 완료는 제외)
                      final Color roleColor;
                      if (shouldShowGray) {
                        roleColor = iconColor;
                      } else if (isBidderRole) {
                        // 낙찰자/낙찰인 경우 노란색
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
                          chattingRoom.profileImage != null &&
                                  chattingRoom.profileImage!.isNotEmpty
                              ? CircleAvatar(
                                  radius: context.isLargeScreen() ? 28 : 24,
                                  backgroundColor: BorderColor,
                                  backgroundImage:
                                      NetworkImage(chattingRoom.profileImage!),
                                )
                              : DefaultProfileAvatar(
                                  radius: context.isLargeScreen() ? 28 : 24,
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
                                            child: RoleBadge(
                                              isSeller: isSeller,
                                              isTopBidder: isTopBidder,
                                              isOpponentTopBidder: isOpponentTopBidder,
                                              isExpired: shouldShowGray,
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
                                            maxLines: 1,
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
