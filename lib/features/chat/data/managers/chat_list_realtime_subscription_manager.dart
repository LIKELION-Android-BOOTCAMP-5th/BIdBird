import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 채팅 리스트 실시간 구독 관리자
/// Data Layer: Supabase와 직접 통신하는 데이터 소스 역할
class ChatListRealtimeSubscriptionManager {
  final _supabase = SupabaseManager.shared.supabase;

  // RealtimeChannel? _buyerChannel;
  // RealtimeChannel? _sellerChannel;
  RealtimeChannel? _roomUsersChannel;

  /// 실시간 구독 설정
  void setupSubscription({
    required void Function() onRoomListUpdate,
    required bool Function(Map<String, dynamic>) checkUpdate,
    required Future<void> Function(String roomId) onNewChatRoom,
    void Function(String roomId)? onNewMessage,
    void Function(Map<String, dynamic>)? onRoomAdded,
    void Function(Map<String, dynamic>)? onRoomUpdated,
  }) {
    final currentId = _supabase.auth.currentUser?.id;
    if (currentId == null) {
      return;
    }

    // 기존 채널 정리
    dispose();

    // 구매자 채널 구독
    // _buyerChannel = _supabase.channel('chattingRoomByBuyer');
    // _buyerChannel!
    //     .onPostgresChanges(
    //       event: PostgresChangeEvent.all,
    //       schema: 'public',
    //       table: 'chatting_room',
    //       filter: PostgresChangeFilter(
    //         type: PostgresChangeFilterType.eq,
    //         column: 'buyer_id',
    //         value: currentId,
    //       ),
    //       callback: (payload) {
    //         final newRecord = payload.newRecord;
    //         final oldRecord = payload.oldRecord;
    //
    //         // INSERT: 새 방 추가
    //         if (payload.eventType == PostgresChangeEvent.insert &&
    //             onRoomAdded != null) {
    //           onRoomAdded(newRecord);
    //         }
    //         // UPDATE: 기존 방 업데이트 (새 메시지가 올 때도 여기서 처리)
    //         else if (payload.eventType == PostgresChangeEvent.update &&
    //             onRoomUpdated != null) {
    //           onRoomUpdated(newRecord);
    //           // UPDATE 이벤트는 새 메시지가 올 때 발생하므로 onNewMessage도 호출
    //           if (onNewMessage != null) {
    //             final roomId = newRecord['id'] as String?;
    //             if (roomId != null) {
    //               onNewMessage(roomId);
    //             }
    //           }
    //         }
    //         // DELETE 또는 기타: 전체 업데이트 (최소화)
    //         else {
    //           onRoomListUpdate();
    //         }
    //       },
    //     )
    //     .subscribe();
    //
    // // 판매자 채널 구독
    // _sellerChannel = _supabase.channel('chattingRoomBySeller');
    // _sellerChannel!
    //     .onPostgresChanges(
    //       event: PostgresChangeEvent.all,
    //       schema: 'public',
    //       table: 'chatting_room',
    //       filter: PostgresChangeFilter(
    //         type: PostgresChangeFilterType.eq,
    //         column: 'seller_id',
    //         value: currentId,
    //       ),
    //       callback: (payload) {
    //         final newRecord = payload.newRecord;
    //         final oldRecord = payload.oldRecord;
    //
    //         // INSERT: 새 방 추가
    //         if (payload.eventType == PostgresChangeEvent.insert &&
    //             onRoomAdded != null) {
    //           onRoomAdded(newRecord);
    //         }
    //         // UPDATE: 기존 방 업데이트 (새 메시지가 올 때도 여기서 처리)
    //         else if (payload.eventType == PostgresChangeEvent.update &&
    //             onRoomUpdated != null) {
    //           onRoomUpdated(newRecord);
    //           // UPDATE 이벤트는 새 메시지가 올 때 발생하므로 onNewMessage도 호출
    //           if (onNewMessage != null) {
    //             final roomId = newRecord['id'] as String?;
    //             if (roomId != null) {
    //               onNewMessage(roomId);
    //             }
    //           }
    //         }
    //         // DELETE 또는 기타: 전체 업데이트 (최소화)
    //         else {
    //           onRoomListUpdate();
    //         }
    //       },
    //     )
    //     .subscribe();

    // chatting_room_users 테이블의 unread_count 변경 감지
    _roomUsersChannel = _supabase.channel('chatting_room_users_list');
    _roomUsersChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chatting_room_users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            final String? roomId = data['room_id'] as String?;
            // 새 방 추가(확인 완료)
            if (payload.eventType == PostgresChangeEvent.insert &&
                roomId != null) {
              onNewChatRoom(roomId);
            }
            // 새 메세지 추적
            if (payload.eventType == PostgresChangeEvent.update) {
              print("새 매시지 입니다");
              if (!checkUpdate(data)) return;
            }
          },
        )
        .subscribe();
  }

  /// 모든 구독 해제
  void dispose() {
    // if (_buyerChannel != null) {
    //   _supabase.removeChannel(_buyerChannel!);
    //   _buyerChannel = null;
    // }
    // if (_sellerChannel != null) {
    //   _supabase.removeChannel(_sellerChannel!);
    //   _sellerChannel = null;
    // }
    if (_roomUsersChannel != null) {
      _supabase.removeChannel(_roomUsersChannel!);
      _roomUsersChannel = null;
    }
  }
}
