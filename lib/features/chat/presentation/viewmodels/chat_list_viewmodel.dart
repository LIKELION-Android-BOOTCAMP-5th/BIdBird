import 'dart:async';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/event_bus/login_event_bus.dart';
import 'package:bidbird/features/chat/data/managers/chat_list_realtime_subscription_manager.dart';
import 'package:bidbird/features/chat/data/repositories/chat_repository.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';
import 'package:bidbird/features/chat/domain/usecases/fetch_chatting_room_list_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/fetch_new_chatting_room_usecase.dart';
import 'package:bidbird/main.dart';
import 'package:flutter/material.dart';

class ChatListViewmodel extends ChangeNotifier {
  StreamSubscription? _loginSubscription;

  final FetchChattingRoomListUseCase _fetchChattingRoomListUseCase;
  final FetchNewChattingRoomUseCase _fetchNewChattingRoomUseCase;

  // Manager 클래스들
  late final ChatListRealtimeSubscriptionManager _realtimeSubscriptionManager;

  List<ChattingRoomEntity> chattingRoomList = [];
  int get totalUnreadCount {
    return chattingRoomList.fold(0, (sum, room) => sum + (room.count ?? 0));
  }

  DateTime? _lastPausedAt;
  bool _initializedAfterLogin = false;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int _currentPage = 1;
  int _pageSize = 20;
  bool _isFetchingList = false; // 중복 요청 방지 플래그

  // 아이템 상태 정보 (캐시 없이 매번 로드)
  final Map<String, String> _sellerIdMap = {};
  final Map<String, bool> _topBidderMap = {};
  final Map<String, String?> _lastBidUserIdMap = {};
  final Map<String, int> _auctionStatusCodeMap = {};
  final Map<String, int?> _tradeStatusCodeMap = {};

  // 정적 인스턴스 (외부에서 접근 가능)
  static ChatListViewmodel? _instance;
  static ChatListViewmodel? get instance => _instance;

  ChatListViewmodel({
    FetchNewChattingRoomUseCase? fetchNewChattingRoomUseCase,
    FetchChattingRoomListUseCase? fetchChattingRoomListUseCase,
    int? initialLoadCount,
  }) : _fetchNewChattingRoomUseCase =
           fetchNewChattingRoomUseCase ??
           FetchNewChattingRoomUseCase(ChatRepositoryImpl()),
       _fetchChattingRoomListUseCase =
           fetchChattingRoomListUseCase ??
           FetchChattingRoomListUseCase(ChatRepositoryImpl()) {
    _realtimeSubscriptionManager = ChatListRealtimeSubscriptionManager();
    _instance = this;
    // 초기 로드는 화면 크기에 맞게 전달받은 개수만 로드
    _pageSize = initialLoadCount ?? 20;
    fetchChattingRoomList(visibleItemCount: _pageSize);
    _setupRealtimeSubscription();
    _loginSubscription = eventBus.on<LoginEventBus>().listen((event) async {
      switch (event.type) {
        case LoginEventType.login:
          if (_initializedAfterLogin) return; // 👈 중복 방지

          _initializedAfterLogin = true;
          final wasDisconnected = !_realtimeSubscriptionManager.isConnected;

          if (wasDisconnected) {
            await fetchChattingRoomList(visibleItemCount: _pageSize);
            _setupRealtimeSubscription();
            return;
          } else {
            await fetchChattingRoomList(visibleItemCount: _pageSize);
          }
          break;
        case LoginEventType.logout:
          _initializedAfterLogin = false;
          chattingRoomList.clear();
          _sellerIdMap.clear();
          _topBidderMap.clear();
          _lastBidUserIdMap.clear();
          _auctionStatusCodeMap.clear();
          _tradeStatusCodeMap.clear();
          _currentPage = 1;
          hasMore = true;
          _realtimeSubscriptionManager.dispose();
          notifyListeners();
          break;
      }
    });
  }

  void setPageSize(int initialLoadCount) {
    _pageSize = initialLoadCount;
  }

  void onAppPaused() {
    _lastPausedAt = DateTime.now();
  }

  Future<void> onAppResumed() async {
    final now = DateTime.now();
    final wasDisconnected = !_realtimeSubscriptionManager.isConnected;

    if (wasDisconnected) {
      await fetchChattingRoomList(visibleItemCount: _pageSize);
      _setupRealtimeSubscription();
      return;
    }

    // ⏱️ 오래 백그라운드였으면 보정
    if (_lastPausedAt != null &&
        now.difference(_lastPausedAt!) > const Duration(minutes: 2)) {
      await fetchChattingRoomList(visibleItemCount: _pageSize);
      return;
    }
  }

  /// 새 채팅방 조회
  Future<void> _fetchNewChattingRoom(String roodId) async {
    final newChattingRoom = await _fetchNewChattingRoomUseCase(roodId);
    if (newChattingRoom == null) return;
    chattingRoomList.insert(0, newChattingRoom);
    notifyListeners();
  }

  /// 채팅방 목록 조회 (초기 로드 시 사용)
  /// [visibleItemCount] 화면에 보이는 개수만큼만 로드
  Future<void> fetchChattingRoomList({
    bool forceRefresh = false,
    int? visibleItemCount,
  }) async {
    if (_isFetchingList) return; // 중복 호출 방지

    final userId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    if (forceRefresh) {
      chattingRoomList.clear();
      _currentPage = 1;
      hasMore = true;
    }
    _pageSize = visibleItemCount ?? _pageSize;
    await _loadChattingRoomList(
      forceRefresh: forceRefresh,
      showLoading: true,
      limit: _pageSize,
      page: 1,
    );
  }

  /// 채팅방 목록 새로고침 (실시간 업데이트 시 사용)
  Future<void> reloadList({
    bool forceRefresh = true,
    int? visibleItemCount,
  }) async {
    if (_isFetchingList) return; // 중복 호출 방지

    if (forceRefresh) {
      chattingRoomList.clear();
      _sellerIdMap.clear();
      _topBidderMap.clear();
      _lastBidUserIdMap.clear();
      _auctionStatusCodeMap.clear();
      _tradeStatusCodeMap.clear();
      _currentPage = 1;
      hasMore = true;
    }
    _pageSize = visibleItemCount ?? _pageSize;
    await _loadChattingRoomList(
      forceRefresh: forceRefresh,
      showLoading: false,
      limit: _pageSize,
      page: 1,
    );
  }

  /// 더 많은 채팅방 로드 (무한 스크롤)
  Future<void> loadMoreChattingRooms() async {
    if (isLoadingMore || !hasMore || isLoading) {
      return;
    }

    isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final newList = await _fetchChattingRoomListUseCase(
        page: _currentPage,
        limit: _pageSize,
      );

      if (newList.isEmpty) {
        hasMore = false;
      } else {
        chattingRoomList.addAll(newList);
        _sortRoomListByLastMessage();

        await _loadItemStatuses(newList);

        // 가져온 개수가 limit보다 적으면 더 이상 없음
        if (newList.length < _pageSize) {
          hasMore = false;
        }
      }
    } catch (e) {
      _currentPage--; // 에러 발생 시 페이지 롤백
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 채팅방 목록 로드 공통 로직
  Future<void> _loadChattingRoomList({
    required bool forceRefresh,
    required bool showLoading,
    required int limit,
    required int page,
  }) async {
    if (_isFetchingList) {
      return; // 중복 호출 방지
    }

    _isFetchingList = true;
    if (showLoading) {
      isLoading = true;
      notifyListeners();
    }

    try {
      final newList = await _fetchChattingRoomListUseCase(
        page: page,
        limit: limit,
      );

      chattingRoomList = newList;
      hasMore = newList.length >= limit;

      _sortRoomListByLastMessage();

      // 아이템 상태 정보 로드
      await _loadItemStatuses(chattingRoomList);
    } catch (e) {
    } finally {
      _isFetchingList = false;
      if (showLoading) {
        isLoading = false;
      }
      notifyListeners();
    }
  }

  /// 채팅방 목록의 아이템 상태 정보 로드
  Future<void> _loadItemStatuses(List<ChattingRoomEntity> chattingRoomList) async {
    final supabase = SupabaseManager.shared.supabase;
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null || chattingRoomList.isEmpty) return;

    final itemIds = chattingRoomList.map((room) => room.itemId).toSet().toList();

    try {
      // Seller IDs 로드
      final sellerResponse = await supabase
          .from('items_detail')
          .select('item_id, seller_id')
          .inFilter('item_id', itemIds);

      for (final row in sellerResponse) {
        final itemId = row['item_id'] as String?;
        final sellerId = row['seller_id'] as String?;
        if (itemId != null && sellerId != null) {
          _sellerIdMap[itemId] = sellerId;
        }
      }

      // Top bidder 정보 로드
      final bidderResponse = await supabase
          .from('bidding_history')
          .select('item_id, user_id')
          .inFilter('item_id', itemIds)
          .order('bid_price', ascending: false)
          .order('created_at', ascending: false)
          .limit(1);

      for (final row in bidderResponse) {
        final itemId = row['item_id'] as String?;
        final userId = row['user_id'] as String?;
        if (itemId != null) {
          _lastBidUserIdMap[itemId] = userId;
          _topBidderMap[itemId] = userId == currentUserId;
        }
      }

      // Auction status codes 로드
      final auctionResponse = await supabase
          .from('items_detail')
          .select('item_id, auction_status_code')
          .inFilter('item_id', itemIds);

      for (final row in auctionResponse) {
        final itemId = row['item_id'] as String?;
        final code = row['auction_status_code'] as int?;
        if (itemId != null && code != null) {
          _auctionStatusCodeMap[itemId] = code;
        }
      }

      // Trade status codes 로드 (items_trade에서)
      final tradeResponse = await supabase
          .from('items_trade')
          .select('item_id, trade_status_code')
          .inFilter('item_id', itemIds);

      for (final row in tradeResponse) {
        final itemId = row['item_id'] as String?;
        final code = row['trade_status_code'] as int?;
        if (itemId != null) {
          _tradeStatusCodeMap[itemId] = code;
        }
      }
    } catch (e) {
    }
  }

  /// 특정 itemId에 대해 현재 사용자가 판매자인지 확인
  bool isSeller(String itemId) {
    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    return _sellerIdMap[itemId] == currentUserId;
  }

  /// 특정 itemId에 대해 현재 사용자가 낙찰자인지 확인
  bool isTopBidder(String itemId) {
    return _topBidderMap[itemId] ?? false;
  }

  /// 특정 itemId에 대해 상대방(구매자)이 낙찰자인지 확인
  /// 내가 판매자인 경우에만 사용
  bool isOpponentTopBidder(String itemId) {
    final lastBidUserId = _lastBidUserIdMap[itemId];
    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    return lastBidUserId != null && lastBidUserId != currentUserId;
  }

  /// 특정 itemId에 대해 거래가 만료되었는지 확인
  bool isTradeExpired(String itemId) {
    final tradeStatusCode = _tradeStatusCodeMap[itemId];
    return tradeStatusCode == 550; // 거래 완료
  }

  /// 특정 itemId의 거래 상태 코드 가져오기
  int? getTradeStatusCode(String itemId) {
    return _tradeStatusCodeMap[itemId];
  }

  /// chattingRoomList의 각 itemId에 대한 상태 정보를 Map으로 제공 (itemBuilder 최적화용)
  Map<
    String,
    ({
      bool isExpired,
      bool isSeller,
      bool isTopBidder,
      bool isOpponentTopBidder,
    })
  >
  get itemStatusMap {
    final Map<
      String,
      ({
        bool isExpired,
        bool isSeller,
        bool isTopBidder,
        bool isOpponentTopBidder,
      })
    >
    statusMap = {};

    for (final room in chattingRoomList) {
      final itemId = room.itemId;
      final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
      final isSeller = _sellerIdMap[itemId] == currentUserId;
      final isTopBidder = _topBidderMap[itemId] ?? false;
      final lastBidUserId = _lastBidUserIdMap[itemId];
      final isOpponentTopBidder = lastBidUserId != null && lastBidUserId != currentUserId;
      final tradeStatusCode = _tradeStatusCodeMap[itemId];
      final isExpired = tradeStatusCode == 550; // 거래 완료

      statusMap[itemId] = (
        isExpired: isExpired,
        isSeller: isSeller,
        isTopBidder: isTopBidder,
        isOpponentTopBidder: isOpponentTopBidder,
      );
    }

    return statusMap;
  }

  void _setupRealtimeSubscription() {
    _realtimeSubscriptionManager.setupSubscription(
      onRoomListUpdate: () {
        // DELETE 등 전체 업데이트가 필요한 경우에만 호출
        // 최소화: 5초 이내에 여러 번 호출되면 마지막 것만 실행
        _debounceFullReload();
      },
      checkUpdate: checkUpdate,
      onNewMessage: _handleNewMessage,
      onRoomAdded: _handleRoomAdded,
      onRoomUpdated: _handleRoomUpdated,
      onNewChatRoom: _fetchNewChattingRoom,
    );
  }

  Timer? _fullReloadDebounceTimer;
  static const Duration _fullReloadDebounceDuration = Duration(seconds: 5);

  void _debounceFullReload() {
    _fullReloadDebounceTimer?.cancel();
    _fullReloadDebounceTimer = Timer(_fullReloadDebounceDuration, () {
      reloadList(forceRefresh: true);
    });
  }

  /// 새 방 추가 처리 (부분 업데이트)
  void _handleRoomAdded(Map<String, dynamic> roomData) {
    try {
      final newRoom = ChattingRoomEntity.fromJson(roomData);

      // 이미 존재하는 방이면 무시
      if (chattingRoomList.any((room) => room.id == newRoom.id)) {
        return;
      }

      // 새 방을 목록에 추가하고 정렬
      chattingRoomList.insert(0, newRoom);
      _sortRoomListByLastMessage();

      // 캐시 업데이트 (비동기, 에러 무시)
      _loadItemStatuses([newRoom]).catchError((_) => null);

      notifyListeners();
    } catch (e) {
      // 파싱 실패 시 전체 리로드
      _debounceFullReload();
    }
  }

  /// 기존 방 업데이트 처리 (부분 업데이트)
  /// 새 메시지가 올 때도 이 메서드가 호출되어 방 정보가 업데이트되고 정렬됨
  void _handleRoomUpdated(Map<String, dynamic> roomData) {
    try {
      final updatedRoom = ChattingRoomEntity.fromJson(roomData);
      final index = chattingRoomList.indexWhere(
        (room) => room.id == updatedRoom.id,
      );

      if (index != -1) {
        // 기존 방 정보 업데이트
        chattingRoomList[index] = updatedRoom;
        // 정렬하여 최신 메시지가 있는 방이 최상단으로 이동
        _sortRoomListByLastMessage();
        notifyListeners();
      } else {
        // 목록에 없으면 추가
        _handleRoomAdded(roomData);
      }
    } catch (e) {
      // 파싱 실패 시 로그만 남기고 전체 리로드 대신 해당 방만 무시
      // 전체 리로드는 성능에 영향을 주므로 최소화
      final roomId = roomData['id'] as String?;
      if (roomId != null) {
        // 파싱 실패한 방이 있으면 해당 방만 제거하지 않고 무시
        // 대신 나중에 전체 리로드가 필요할 수 있으므로 디바운싱된 리로드 예약
        _debounceFullReload();
      }
    }
  }

  @override
  void dispose() {
    if (_instance == this) {
      _instance = null;
    }
    _loginSubscription?.cancel();
    _fullReloadDebounceTimer?.cancel();
    _realtimeSubscriptionManager.dispose();
    super.dispose();
  }

  /// 실시간 unread_count 변경 감지
  bool checkUpdate(Map<String, dynamic> data) {
    final roomId = data["room_id"] as String?;
    if (roomId == null) return false;

    final index = chattingRoomList.indexWhere((e) => e.id == roomId);
    if (index == -1) return false;

    final newUnreadCount = data['unread_count'] as int? ?? 0;
    final String? newLastMessage = data['last_message'] as String?;

    final String? newLastMessageSendAt =
        data['last_message_send_at'] as String?;
    if (chattingRoomList[index].lastMessage != newLastMessage) {
      if (newLastMessage != null)
        chattingRoomList[index].lastMessage = newLastMessage;
      if (newLastMessageSendAt != null)
        chattingRoomList[index].lastMessageSendAt =
            data['last_message_send_at'] as String;
      if (chattingRoomList[index].count != newUnreadCount) {
        chattingRoomList[index].count = newUnreadCount;
      }
      final room = chattingRoomList.removeAt(index);
      chattingRoomList.insert(0, room);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 새 메시지 수신/전송 시 처리
  /// 실제 방 정보 업데이트는 onRoomUpdated에서 처리되므로 여기서는 아무것도 하지 않음
  void _handleNewMessage(String roomId) {
    // onRoomUpdated가 호출되어 방 정보가 업데이트되고 정렬되므로
    // 여기서는 별도 처리가 필요 없음
  }

  /// 방을 최상단으로 이동 (외부에서 사용)
  void moveRoomToTop(String roomId) {
    final index = chattingRoomList.indexWhere((room) => room.id == roomId);
    if (index != -1 && index != 0) {
      final room = chattingRoomList.removeAt(index);
      chattingRoomList.insert(0, room);
      notifyListeners();
    }
  }

  /// 방 진입 시 로컬에서 즉시 unreadCount를 0으로 변경
  void markRoomAsReadLocally(String roomId) {
    final index = chattingRoomList.indexWhere((room) => room.id == roomId);
    if (index != -1 &&
        chattingRoomList[index].count != null &&
        chattingRoomList[index].count! > 0) {
      chattingRoomList[index].count = 0;
      notifyListeners();
    }
  }

  /// lastMessageSendAt desc 기준으로 목록 정렬
  void _sortRoomListByLastMessage() {
    chattingRoomList.sort((a, b) {
      try {
        final aTime = DateTime.parse(a.lastMessageSendAt);
        final bTime = DateTime.parse(b.lastMessageSendAt);
        return bTime.compareTo(aTime);
      } catch (e) {
        return 0;
      }
    });
  }
}
