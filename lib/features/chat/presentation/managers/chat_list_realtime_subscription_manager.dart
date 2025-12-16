import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 채팅 리스트 실시간 구독 관리자
class ChatListRealtimeSubscriptionManager {
  final _supabase = SupabaseManager.shared.supabase;

  RealtimeChannel? _buyerChannel;
  RealtimeChannel? _sellerChannel;
  RealtimeChannel? _roomUsersChannel;
  RealtimeChannel? _messageChannel;

  /// 실시간 구독 설정
  void setupSubscription({
    required void Function() onRoomListUpdate,
    required bool Function(Map<String, dynamic>) checkUpdate,
    void Function(String roomId)? onNewMessage,
  }) {
    final currentId = _supabase.auth.currentUser?.id;
    if (currentId == null) {
      return;
    }

    // 기존 채널 정리
    dispose();

    // 구매자 채널 구독
    _buyerChannel = _supabase.channel('chattingRoomByBuyer');
    _buyerChannel!
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
            onRoomListUpdate();
          },
        )
        .subscribe();

    // 판매자 채널 구독
    _sellerChannel = _supabase.channel('chattingRoomBySeller');
    _sellerChannel!
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
            onRoomListUpdate();
          },
        )
        .subscribe();

    // chatting_room_users 테이블의 unread_count 변경 감지
    _roomUsersChannel = _supabase.channel('chatting_room_users_list');
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
            if (!checkUpdate(data)) return;
          },
        )
        .subscribe();

    // 새 메시지 감지
    if (onNewMessage != null) {
      _messageChannel = _supabase.channel('chatting_message_list');
      _messageChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'chatting_message',
            callback: (payload) {
              final roomId = payload.newRecord['room_id'] as String?;
              if (roomId != null) {
                onNewMessage(roomId);
              }
            },
          )
          .subscribe();
    }
  }

  /// 모든 구독 해제
  void dispose() {
    if (_buyerChannel != null) {
      _supabase.removeChannel(_buyerChannel!);
      _buyerChannel = null;
    }
    if (_sellerChannel != null) {
      _supabase.removeChannel(_sellerChannel!);
      _sellerChannel = null;
    }
    if (_roomUsersChannel != null) {
      _supabase.removeChannel(_roomUsersChannel!);
      _roomUsersChannel = null;
    }
    if (_messageChannel != null) {
      _supabase.removeChannel(_messageChannel!);
      _messageChannel = null;
    }
  }
}

