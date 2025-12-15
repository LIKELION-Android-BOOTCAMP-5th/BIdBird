import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 채팅 리스트 실시간 구독 관리자
/// 채팅 리스트의 실시간 업데이트를 관리하는 클래스
class ChatListRealtimeSubscriptionManager {
  final _supabase = SupabaseManager.shared.supabase;

  RealtimeChannel? _buyerChannel;
  RealtimeChannel? _sellerChannel;
  RealtimeChannel? _roomUsersChannel;

  /// 실시간 구독 설정
  /// [onRoomListUpdate] 채팅방 리스트 업데이트 콜백
  /// [onUnreadCountUpdate] 읽지 않은 메시지 수 업데이트 콜백
  /// [checkUpdate] unread_count 변경 확인 함수
  void setupSubscription({
    required void Function() onRoomListUpdate,
    required bool Function(Map<String, dynamic>) checkUpdate,
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
  }
}

