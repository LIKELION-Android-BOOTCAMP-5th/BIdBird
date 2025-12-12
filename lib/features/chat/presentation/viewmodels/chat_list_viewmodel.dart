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
    isLoading = false;
    notifyListeners();
  }

  Future<void> reloadList() async {
    try {
      final newList = await _getChattingRoomListUseCase();
      chattingRoomList = newList;
      notifyListeners();
      // ignore: avoid_print
      print("reloadList 완료: ${chattingRoomList.length}개 채팅방, unread_count 확인 중...");
      for (var room in chattingRoomList) {
        if (room.count != null && room.count! > 0) {
          // ignore: avoid_print
          print("  - ${room.itemTitle}: unread_count=${room.count}");
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print("reloadList 실패: $e");
    }
  }

  void setupRealtimeSubscription() {
    final currentId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentId == null) return;
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
            final data = payload.newRecord;
            if (data == null) return;
            
            // unread_count가 변경되면 해당 채팅방의 정보만 업데이트
            final roomId = data['room_id'] as String?;
            final unreadCount = data['unread_count'] as int? ?? 0;
            final oldUnreadCount = payload.oldRecord?['unread_count'] as int? ?? 0;
            
            // ignore: avoid_print
            print("실시간 업데이트 트리거: roomId=$roomId, oldCount=$oldUnreadCount, newCount=$unreadCount");
            
            if (roomId != null) {
              // unread_count가 변경되었을 때만 업데이트
              if (unreadCount != oldUnreadCount) {
                // ignore: avoid_print
                print("unread_count 변경 감지: $oldUnreadCount -> $unreadCount, 리스트 새로고침 시작");
                
                // unread_count가 0이 되면 즉시 업데이트 (읽음 처리 완료)
                if (unreadCount == 0) {
                  // 읽음 처리 완료 시 즉시 업데이트 (지연 없이)
                  reloadList();
                  // 추가로 200ms, 500ms, 1000ms 후에도 한 번 더 확인 (서버 처리 지연 대비)
                  Future.delayed(const Duration(milliseconds: 200), () {
                    // ignore: avoid_print
                    print("실시간 업데이트: 200ms 후 재확인");
                    reloadList();
                  });
                  Future.delayed(const Duration(milliseconds: 500), () {
                    // ignore: avoid_print
                    print("실시간 업데이트: 500ms 후 재확인");
                    reloadList();
                  });
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    // ignore: avoid_print
                    print("실시간 업데이트: 1000ms 후 재확인");
                    reloadList();
                  });
                } else {
                  // unread_count가 증가한 경우 즉시 업데이트
                  reloadList();
                }
              } else {
                // ignore: avoid_print
                print("unread_count 변경 없음: $oldUnreadCount == $unreadCount");
              }
            }
          },
        )
        .subscribe();
    
    // ignore: avoid_print
    print("실시간 구독 설정 완료: chatting_room_users 테이블 감시 시작");
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
