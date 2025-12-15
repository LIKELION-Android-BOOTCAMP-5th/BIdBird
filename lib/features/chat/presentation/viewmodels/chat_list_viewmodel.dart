import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/data/repositories/chat_repository.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';
import 'package:bidbird/features/chat/domain/usecases/get_chatting_room_list_usecase.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatListViewmodel extends ChangeNotifier {
  final ChatRepositoryImpl _repository = ChatRepositoryImpl();
  late final GetChattingRoomListUseCase _getChattingRoomListUseCase;
  List<ChattingRoomEntity> chattingRoomList = [];
  bool isLoading = false;
  RealtimeChannel? _isBuyerChannel;
  RealtimeChannel? _isSellerChannel;
  RealtimeChannel? _roomUsersChannel;
  // itemId -> sellerId 매핑 캐시
  Map<String, String> _sellerIdCache = {};
  // itemId -> isTopBidder 매핑 캐시 (내가 낙찰자인지 여부)
  Map<String, bool> _topBidderCache = {};
  // itemId -> lastBidUserId 매핑 캐시 (낙찰자 ID 저장)
  Map<String, String?> _lastBidUserIdCache = {};

  // int inputCount = 0;

  // final TextEditingController textEditingController = TextEditingController();

  // 뷰모델 생성자, context를 통해 리포지토리를 받아올 수 있음.
  ChatListViewmodel(BuildContext context) {
    _getChattingRoomListUseCase = GetChattingRoomListUseCase(_repository);
    fetchChattingRoomList();
    setupRealtimeSubscription();
  }

  Future<void> fetchChattingRoomList() async {
    isLoading = true;
    notifyListeners();
    chattingRoomList = await _getChattingRoomListUseCase();
    await _loadSellerIds();
    await _loadTopBidders();
    isLoading = false;
    notifyListeners();
  }

  Future<void> reloadList() async {
    try {
      final newList = await _getChattingRoomListUseCase();
      chattingRoomList = newList;
      await _loadSellerIds();
      await _loadTopBidders();
      notifyListeners();
      print(
        "reloadList 완료: ${chattingRoomList.length}개 채팅방, unread_count 확인 중...",
      );
      for (var room in chattingRoomList) {
        if (room.count != null && room.count! > 0) {
          print("  - ${room.itemTitle}: unread_count=${room.count}");
        }
      }
    } catch (e) {
      print("reloadList 실패: $e");
    }
  }

  /// 모든 채팅방의 itemId에 대한 seller_id를 한 번에 가져와서 캐시에 저장
  Future<void> _loadSellerIds() async {
    try {
      final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // 중복 제거된 itemId 목록
      final itemIds = chattingRoomList.map((room) => room.itemId).toSet().toList();
      if (itemIds.isEmpty) return;

      // 캐시에 없는 itemId만 조회
      final uncachedItemIds = itemIds.where((itemId) => !_sellerIdCache.containsKey(itemId)).toList();
      if (uncachedItemIds.isEmpty) return;

      final response = await SupabaseManager.shared.supabase
          .from('items_detail')
          .select('item_id, seller_id')
          .inFilter('item_id', uncachedItemIds);

      if (response != null && response is List) {
        for (final row in response) {
          final itemId = row['item_id'] as String?;
          final sellerId = row['seller_id'] as String?;
          if (itemId != null && sellerId != null) {
            _sellerIdCache[itemId] = sellerId;
          }
        }
      }
    } catch (e) {
      print("seller_id 로드 실패: $e");
    }
  }

  /// 특정 itemId에 대해 현재 사용자가 판매자인지 확인
  bool isSeller(String itemId) {
    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;
    
    final sellerId = _sellerIdCache[itemId];
    return sellerId == currentUserId;
  }

  /// 특정 itemId에 대해 현재 사용자가 낙찰자인지 확인
  bool isTopBidder(String itemId) {
    return _topBidderCache[itemId] ?? false;
  }

  /// 특정 itemId에 대해 상대방(구매자)이 낙찰자인지 확인
  /// 내가 판매자인 경우에만 사용
  bool isOpponentTopBidder(String itemId) {
    // 내가 판매자가 아니면 false
    if (!isSeller(itemId)) {
      return false;
    }
    
    // 내가 판매자인 경우, 상대방(구매자)이 낙찰자인지 확인
    // last_bid_user_id가 존재하고, 내가 아니면 상대방이 낙찰자
    final lastBidUserId = _lastBidUserIdCache[itemId];
    if (lastBidUserId == null) return false; // 낙찰자가 없으면 false
    
    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;
    
    // 낙찰자가 존재하고 내가 낙찰자가 아니면 상대방이 낙찰자
    return lastBidUserId != currentUserId;
  }

  /// 모든 채팅방의 itemId에 대한 낙찰자 여부를 한 번에 가져와서 캐시에 저장
  Future<void> _loadTopBidders() async {
    try {
      final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // 중복 제거된 itemId 목록
      final itemIds = chattingRoomList.map((room) => room.itemId).toSet().toList();
      if (itemIds.isEmpty) return;

      // 캐시에 없는 itemId만 조회
      final uncachedItemIds = itemIds.where((itemId) => !_topBidderCache.containsKey(itemId)).toList();
      if (uncachedItemIds.isEmpty) return;

      final response = await SupabaseManager.shared.supabase
          .from('auctions')
          .select('item_id, last_bid_user_id')
          .inFilter('item_id', uncachedItemIds)
          .eq('round', 1);

      if (response != null && response is List) {
        for (final row in response) {
          final itemId = row['item_id'] as String?;
          final lastBidUserId = row['last_bid_user_id'] as String?;
          if (itemId != null) {
            // last_bid_user_id 저장
            _lastBidUserIdCache[itemId] = lastBidUserId;
            // 내가 낙찰자인지 확인
            _topBidderCache[itemId] = lastBidUserId != null && lastBidUserId == currentUserId;
          } else {
            _lastBidUserIdCache[itemId ?? ''] = null;
            _topBidderCache[itemId ?? ''] = false;
          }
        }
      }
    } catch (e) {
      print("top_bidder 로드 실패: $e");
    }
  }

  void setupRealtimeSubscription() {
    final currentId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentId == null) {
      print("실시간 구독 설정 실패: currentId가 null");
      return;
    }

    print("실시간 구독 설정 시작: currentId=$currentId");

    _isBuyerChannel = SupabaseManager.shared.supabase.channel(
      'chattingRoomByBuyer',
    );
    _isBuyerChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chatting_room',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'buyer_id',
            value: currentId,
          ),
          callback: (payload) {
            print("실시간 업데이트: chatting_room (buyer) 변경 감지");
            reloadList();
          },
        )
        .subscribe();

    _isSellerChannel = SupabaseManager.shared.supabase.channel(
      'chattingRoomBySeller',
    );
    _isSellerChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chatting_room',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'seller_id',
            value: currentId,
          ),
          callback: (payload) {
            print("실시간 업데이트: chatting_room (seller) 변경 감지");
            reloadList();
          },
        )
        .subscribe();

    // chatting_room_users 테이블의 unread_count 변경 감지
    // 현재 사용자의 unread_count가 변경되면 채팅 리스트 업데이트
    _roomUsersChannel = SupabaseManager.shared.supabase.channel(
      'chatting_room_users_list',
    );
    _roomUsersChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chatting_room_users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentId,
          ),
          callback: (payload) {
            print("실시간 업데이트: chatting_room_users 테이블 변경 감지");
            final data = payload.newRecord;
            final oldData = payload.oldRecord;
            if (data == null) {
              print("실시간 업데이트: newRecord가 null");
              return;
            }

            if (!checkUpdate(data)) return;

            // // unread_count가 변경되면 해당 채팅방의 정보만 업데이트
            // final roomId = data['room_id'] as String?;
            // final unreadCount = data['unread_count'] as int? ?? 0;
            // final oldUnreadCount = payload.oldRecord?['unread_count'] as int?;
            //
            // //
            // print(
            //   "실시간 업데이트 트리거: roomId=$roomId, oldCount=$oldUnreadCount, newCount=$unreadCount",
            // );
            //
            // if (roomId != null) {
            //   // oldRecord가 null이거나 unread_count가 변경되었을 때 업데이트
            //   // oldRecord가 null인 경우는 INSERT 이벤트이거나 oldRecord가 전달되지 않은 경우
            //   if (oldUnreadCount == null || unreadCount != oldUnreadCount) {
            //     //
            //     print(
            //       "unread_count 변경 감지: $oldUnreadCount -> $unreadCount, 리스트 새로고침 시작",
            //     );
            //
            //     // unread_count가 0이 되면 즉시 업데이트 (읽음 처리 완료)
            //     if (unreadCount == 0) {
            //       //
            //       print("unread_count가 0이 됨 - 즉시 리스트 새로고침");
            //       // 읽음 처리 완료 시 즉시 업데이트
            //       reloadList();
            //     } else {
            //       // unread_count가 증가한 경우 즉시 업데이트
            //       //
            //       print(
            //         "unread_count 증가: $oldUnreadCount -> $unreadCount - 즉시 리스트 새로고침",
            //       );
            //       reloadList();
            //     }
            //   } else {
            //     //
            //     print("unread_count 변경 없음: $oldUnreadCount == $unreadCount");
            //     // oldCount와 newCount가 같아도, unread_count가 0이고 oldRecord가 null이 아닌 경우
            //     // 이미 읽음 처리된 상태이므로 리스트를 새로고침하여 UI 업데이트 보장
            //     if (unreadCount == 0 && oldUnreadCount != null) {
            //       //
            //       print("unread_count가 이미 0이지만 리스트 새로고침 (UI 업데이트 보장)");
            //       reloadList();
            //     }
            //   }
            // } else {
            //   //
            //   print("실시간 업데이트: roomId가 null");
            // }
          },
        )
        .subscribe();

    print("실시간 구독 설정 완료: chatting_room_users 테이블 감시 시작 (user_id=$currentId)");
  }

  @override
  void dispose() {
    if (_isBuyerChannel != null) {
      SupabaseManager.shared.supabase.removeChannel(_isBuyerChannel!);
    }
    if (_isSellerChannel != null) {
      SupabaseManager.shared.supabase.removeChannel(_isSellerChannel!);
    }
    if (_roomUsersChannel != null) {
      SupabaseManager.shared.supabase.removeChannel(_roomUsersChannel!);
    }
    super.dispose();
  }

  bool checkUpdate(Map<String, dynamic> data) {
    final index = chattingRoomList.indexWhere(
      (e) => e.id == data["room_id"] as String,
    );
    final room = chattingRoomList[index];
    // 변동 사항이 있다면 true
    if (room.count != data['unread_count'] as int?) {
      print("변경 감지된 Room id : ${room.id}");
      print("unread_count : ${room.count} => ${data['unread_count']}");
      room.count = data['unread_count'] as int?;
      notifyListeners();
      return true;
    }
    return false;
  }

  // 입력한 글자 수를 받아오는 함수
  // void handleTextInput(String input) {
  //   inputCount = input.length;
  //   notifyListeners();
  // }

  // Future 함수는 API나 Supabase, 메소드 채널과 사용할 때,
  // 처리를 하는데 시간이 걸리는 작업을 할때 사용됨.
  // 아래 함수 안 에서는 시간이 필요한 작업은 await를 사용 해야함
  // Future<void> function() async {
  //   try {
  //
  //   } catch (e) {
  //
  //   }
  //
  //   // 리빌딩, 리콤포지션 진행
  //   notifyListeners();
  // }
  // Future<void> function1() async {
  //   // 시간 지연 코드
  //   await Future.delayed(const Duration(milliseconds: 1700));
  //   notifyListeners();
  // }
}
