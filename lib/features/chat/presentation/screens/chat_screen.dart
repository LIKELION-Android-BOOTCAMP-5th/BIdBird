import 'package:bidbird/core/router/app_router.dart';
import 'package:bidbird/core/utils/extension/time_extension.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/visible_item_calculator.dart';
import 'package:bidbird/core/widgets/components/default_profile_avatar.dart';
import 'package:bidbird/core/widgets/components/role_badge.dart';
import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:bidbird/core/widgets/notification_button.dart';
import 'package:bidbird/core/widgets/unified_empty_state.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';
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
    with RouteAware, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late ChatListViewmodel? _viewModel;
  bool _isViewModelInitialized = false;
  final ScrollController _scrollController = ScrollController();
  bool _isListenerAttached = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_viewModel == null) return;

    if (state == AppLifecycleState.resumed) {
      debugPrint("📱 ChatScreen resumed");

      // ✅ 포그라운드 복귀 시
      _viewModel!.onAppResumed();
    }

    if (state == AppLifecycleState.paused) {
      debugPrint("📱 ChatScreen paused");

      // ✅ 백그라운드 진입 시
      _viewModel!.onAppPaused();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _viewModel = context.read<ChatListViewmodel>();

    if (!_isViewModelInitialized) {
      final loadCount = VisibleItemCalculator.calculateChatListVisibleCount(
        context,
      );

      _viewModel!.setPageSize(loadCount);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _viewModel!.fetchChattingRoomList(visibleItemCount: loadCount);
        }
      });

      _isViewModelInitialized = true;
    }

    if (!_isListenerAttached) {
      _scrollController.addListener(_scrollListener);
      _isListenerAttached = true;
    }
  }

  void _scrollListener() {
    final viewModel = context.read<ChatListViewmodel>();

    // 스크롤이 하단 근처(200px 이내)에 도달하면 더 많은 데이터 로드
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      viewModel.loadMoreChattingRooms();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 👈 추가
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
    // 스크롤 초기화 방지를 위해 자동 새로고침 제거
    // Socket 연결이 유지되어 있다면 실시간으로 업데이트됨
    /*
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _viewModel != null) {
        // 화면 크기에 맞는 개수만 다시 로드 (코어 유틸리티 사용)
        final context = this.context;
        if (context.mounted) {
          final loadCount = VisibleItemCalculator.calculateChatListVisibleCount(
            context,
          );
          _viewModel!.reloadList(
            forceRefresh: true,
            visibleItemCount: loadCount,
          );
        }
      }
    });
    */
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_isViewModelInitialized) {
      return const Scaffold(body: SizedBox.shrink());
    }
    // ViewModel을 한 번만 생성하여 실시간 구독이 끊기지 않도록 함
    return Selector<
      ChatListViewmodel,
      ({
        bool isLoading,
        List<ChattingRoomEntity> chattingRoomList,
        bool isLoadingMore,
        Map<
          String,
          ({
            bool isExpired,
            bool isSeller,
            bool isTopBidder,
            bool isOpponentTopBidder,
            bool isTradeComplete,
          })
        >
        itemStatusMap,
      })
    >(
      selector: (_, vm) => (
        isLoading: vm.isLoading,
        chattingRoomList: vm.chattingRoomList,
        isLoadingMore: vm.isLoadingMore,
        itemStatusMap: vm.itemStatusMap,
      ),
      builder: (context, data, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [const Text('채팅'), NotificationButton()],
            ),
          ),
          backgroundColor: BackgroundColor,
          body: SafeArea(child: _buildBody(context, data)),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ({
      bool isLoading,
      List<ChattingRoomEntity> chattingRoomList,
      bool isLoadingMore,
      Map<
        String,
        ({
          bool isExpired,
          bool isSeller,
          bool isTopBidder,
          bool isOpponentTopBidder,
          bool isTradeComplete,
        })
      >
      itemStatusMap,
    })
    data,
  ) {
    if (data.chattingRoomList.isEmpty) {
      if (data.isLoading) {
        return const SizedBox.shrink();
      }
      return UnifiedEmptyState(
        title: '채팅방이 없습니다',
        subtitle: '새로운 상품을 등록하거나 입찰에 참여해보세요!',
        onRefresh: () =>
            context.read<ChatListViewmodel>().reloadList(forceRefresh: true),
      );
    }

    // ViewModel 참조 (메서드 호출용)
    final viewModel = context.read<ChatListViewmodel>();

    // 반응형: 큰 화면에서는 최대 너비 제한 및 중앙 정렬
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 800;
    final maxWidth = isLargeScreen ? 800.0 : double.infinity;
    final horizontalPadding = context.hPadding;
    final verticalPadding = context.vPadding;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: TransparentRefreshIndicator(
          onRefresh: () => viewModel.reloadList(forceRefresh: true),
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            itemCount:
                data.chattingRoomList.length + (data.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => SizedBox(height: context.spacingSmall),
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            itemBuilder: (context, index) {
              // 로딩 인디케이터 표시
              if (index == data.chattingRoomList.length) {
                return const SizedBox.shrink();
              }

              final chattingRoom = data.chattingRoomList[index];
              final itemId = chattingRoom.itemId;
              // itemStatusMap에서 상태 정보 가져오기 (메서드 호출 대신 Map 조회로 최적화)
              final status = data.itemStatusMap[itemId];
              final isExpired = status?.isExpired ?? false;
              final isSeller = status?.isSeller ?? false;
              final isTopBidder = status?.isTopBidder ?? false;
              final isOpponentTopBidder = status?.isOpponentTopBidder ?? false;
              final isTradeComplete = status?.isTradeComplete ?? false;

              // 1. 거래 완료(550)인 경우 모두 노란색
              // 2. 경매 종료(230 등)인 경우에만 낙찰자(및 판매자에게 보이는 낙찰자) 노란색
              // 진행 중(310)인 경우에는 낙찰자라도 노란색 아님 (파란색/녹색)
              final isBidderRole =
                  isTradeComplete ||
                  (isExpired &&
                      ((!isSeller && isTopBidder) ||
                          (isSeller && isOpponentTopBidder)));

              // 만료된 거래만 회색으로 표시 (노란색 대상 제외)
              final shouldShowGray = isExpired && !isBidderRole;

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
                              roleColor = isSeller
                                  ? roleSalePrimary
                                  : rolePurchasePrimary;
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
                                        radius: context.isLargeScreen()
                                            ? 28
                                            : 24,
                                        backgroundColor: BorderColor,
                                        backgroundImage: NetworkImage(
                                          chattingRoom.profileImage!,
                                        ),
                                      )
                                    : DefaultProfileAvatar(
                                        radius: context.isLargeScreen()
                                            ? 28
                                            : 24,
                                      ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 매물 제목과 시간을 같은 줄에 수평 정렬
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 6,
                                                      ),
                                                  child: RoleBadge(
                                                    isSeller: isSeller,
                                                    isTopBidder:
                                                        isTopBidder &&
                                                        isExpired,
                                                    isOpponentTopBidder:
                                                        isOpponentTopBidder &&
                                                        isExpired,
                                                    isExpired: shouldShowGray,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    chattingRoom.itemTitle,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          context.fontSizeLarge,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            (chattingRoom.lastMessageSendAt !=
                                                        null &&
                                                    chattingRoom
                                                        .lastMessageSendAt!
                                                        .isNotEmpty)
                                                ? chattingRoom
                                                      .lastMessageSendAt!
                                                      .toTimesAgo()
                                                : '',
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
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  chattingRoom.lastMessage
                                                      .replaceAll(
                                                        RegExp(
                                                          r'\s*\(?\s*낙찰자\s*\)?\s*',
                                                        ),
                                                        '',
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize:
                                                        context.fontSizeMedium,
                                                  ),
                                                  textAlign: TextAlign.left,
                                                ),
                                              ),
                                              if (chattingRoom.count! > 0)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    left: context.spacingSmall,
                                                  ),
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: context
                                                              .spacingSmall,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            15,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      "${chattingRoom.count ?? 0}",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: context
                                                            .fontSizeSmall,
                                                        fontWeight:
                                                            FontWeight.w600,
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
      ),
    );
  }
}
