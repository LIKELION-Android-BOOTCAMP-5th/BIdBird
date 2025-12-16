import 'package:bidbird/features/chat/data/repositories/chat_repository.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';
import 'package:bidbird/features/chat/domain/usecases/get_chatting_room_list_usecase.dart';
import 'package:bidbird/features/chat/presentation/managers/chat_list_cache_manager.dart';
import 'package:bidbird/features/chat/presentation/managers/chat_list_realtime_subscription_manager.dart';
import 'package:flutter/material.dart';

class ChatListViewmodel extends ChangeNotifier {
  final ChatRepositoryImpl _repository = ChatRepositoryImpl();
  late final GetChattingRoomListUseCase _getChattingRoomListUseCase;
  
  // Manager 클래스들
  late final ChatListRealtimeSubscriptionManager _realtimeSubscriptionManager;
  late final ChatListCacheManager _cacheManager;
  
  List<ChattingRoomEntity> chattingRoomList = [];
  bool isLoading = false;
  
  // 캐싱 관련
  DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 2);

  // 정적 인스턴스 (외부에서 접근 가능)
  static ChatListViewmodel? _instance;
  static ChatListViewmodel? get instance => _instance;

  ChatListViewmodel(BuildContext context) {
    _getChattingRoomListUseCase = GetChattingRoomListUseCase(_repository);
    _realtimeSubscriptionManager = ChatListRealtimeSubscriptionManager();
    _cacheManager = ChatListCacheManager();
    
    _instance = this;
    
    fetchChattingRoomList();
    _setupRealtimeSubscription();
  }

  /// 채팅방 목록 조회 (초기 로드 시 사용)
  Future<void> fetchChattingRoomList({bool forceRefresh = false}) async {
    await _loadChattingRoomList(forceRefresh: forceRefresh, showLoading: true);
  }

  /// 채팅방 목록 새로고침 (실시간 업데이트 시 사용)
  Future<void> reloadList({bool forceRefresh = false}) async {
    await _loadChattingRoomList(forceRefresh: forceRefresh, showLoading: false);
  }

  /// 채팅방 목록 로드 공통 로직
  Future<void> _loadChattingRoomList({
    required bool forceRefresh,
    required bool showLoading,
  }) async {
    // 캐시 검증 (forceRefresh가 아니고 캐시가 유효한 경우)
    if (!forceRefresh && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration &&
        chattingRoomList.isNotEmpty) {
      return;
    }
    
    if (showLoading) {
      isLoading = true;
      notifyListeners();
    }
    
    try {
      final newList = await _getChattingRoomListUseCase();
      chattingRoomList = newList;
      
      _sortRoomListByLastMessage();
      
      await Future.wait([
        _cacheManager.loadSellerIds(chattingRoomList),
        _cacheManager.loadTopBidders(chattingRoomList),
      ], eagerError: false);
      
      _lastFetchTime = DateTime.now();
    } catch (e) {
      // 에러 발생 시에도 기존 데이터 유지
    } finally {
      if (showLoading) {
        isLoading = false;
      }
      notifyListeners();
    }
  }

  /// 특정 itemId에 대해 현재 사용자가 판매자인지 확인
  bool isSeller(String itemId) {
    return _cacheManager.isSeller(itemId);
  }

  /// 특정 itemId에 대해 현재 사용자가 낙찰자인지 확인
  bool isTopBidder(String itemId) {
    return _cacheManager.isTopBidder(itemId);
  }

  /// 특정 itemId에 대해 상대방(구매자)이 낙찰자인지 확인
  /// 내가 판매자인 경우에만 사용
  bool isOpponentTopBidder(String itemId) {
    return _cacheManager.isOpponentTopBidder(itemId);
  }

  void _setupRealtimeSubscription() {
    _realtimeSubscriptionManager.setupSubscription(
      onRoomListUpdate: reloadList,
      checkUpdate: checkUpdate,
      onNewMessage: _handleNewMessage,
    );
  }

  @override
  void dispose() {
    if (_instance == this) {
      _instance = null;
    }
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
    if (chattingRoomList[index].count != newUnreadCount) {
      chattingRoomList[index].count = newUnreadCount;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// 새 메시지 수신/전송 시 해당 방을 최상단으로 이동
  void _handleNewMessage(String roomId) {
    moveRoomToTop(roomId);
  }

  /// 방을 최상단으로 이동
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
    if (index != -1 && chattingRoomList[index].count != null && chattingRoomList[index].count! > 0) {
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
