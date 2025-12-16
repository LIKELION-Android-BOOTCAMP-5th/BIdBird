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

  // 뷰모델 생성자, context를 통해 리포지토리를 받아올 수 있음.
  ChatListViewmodel(BuildContext context) {
    _getChattingRoomListUseCase = GetChattingRoomListUseCase(_repository);
    _realtimeSubscriptionManager = ChatListRealtimeSubscriptionManager();
    _cacheManager = ChatListCacheManager();
    
    fetchChattingRoomList();
    _setupRealtimeSubscription();
  }

  Future<void> fetchChattingRoomList({bool forceRefresh = false}) async {
    // 캐시가 유효하고 강제 새로고침이 아니면 캐시 사용
    if (!forceRefresh && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration &&
        chattingRoomList.isNotEmpty) {
      return; // 캐시된 데이터 사용
    }
    
    isLoading = true;
    notifyListeners();
    
    try {
      chattingRoomList = await _getChattingRoomListUseCase();
      
      // loadSellerIds와 loadTopBidders를 병렬로 처리
      await Future.wait([
        _cacheManager.loadSellerIds(chattingRoomList),
        _cacheManager.loadTopBidders(chattingRoomList),
      ], eagerError: false);
      
      _lastFetchTime = DateTime.now();
    } catch (e) {
      // 에러 발생 시에도 캐시된 데이터는 유지
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadList() async {
    try {
      final newList = await _getChattingRoomListUseCase();
      chattingRoomList = newList;
      await _cacheManager.loadSellerIds(chattingRoomList);
      await _cacheManager.loadTopBidders(chattingRoomList);
      notifyListeners();
    } catch (e) {}
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
      onRoomListUpdate: () {
        reloadList();
      },
      checkUpdate: (data) {
        return checkUpdate(data);
      },
    );
  }

  @override
  void dispose() {
    _realtimeSubscriptionManager.dispose();
    super.dispose();
  }

  bool checkUpdate(Map<String, dynamic> data) {
    final index = chattingRoomList.indexWhere(
      (e) => e.id == data["room_id"] as String,
    );
    if (index == -1) return false;
    
    final room = chattingRoomList[index];
    // 변동 사항이 있다면 true
    if (room.count != data['unread_count'] as int?) {
      room.count = data['unread_count'] as int?;
      notifyListeners();
      return true;
    }
    return false;
  }
}
