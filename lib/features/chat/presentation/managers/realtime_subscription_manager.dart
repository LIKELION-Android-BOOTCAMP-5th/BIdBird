import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/domain/entities/auction_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/features/chat/domain/entities/item_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/trade_info_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 실시간 구독 관리자
/// 채팅방의 실시간 업데이트를 관리하는 클래스
class RealtimeSubscriptionManager {
  final _supabase = SupabaseManager.shared.supabase;

  RealtimeChannel? _messageChannel;
  RealtimeChannel? _itemsChannel;
  RealtimeChannel? _auctionsChannel;
  RealtimeChannel? _tradeChannel;
  RealtimeChannel? _roomUsersChannel;

  /// 메시지 구독 설정
  /// [roomId] 채팅방 ID
  /// [onNewMessage] 새 메시지 수신 시 콜백
  void subscribeToMessages(
    String roomId,
    void Function(ChatMessageEntity) onNewMessage,
    void Function() onNotifyListeners,
  ) {
    // 기존 채널 정리 (중복 구독 방지)
    if (_messageChannel != null) {
      _supabase.removeChannel(_messageChannel!);
      _messageChannel = null;
    }

    _messageChannel = _supabase.channel('chatting_message$roomId');
    _messageChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chatting_message',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;
            final ChatMessageEntity newChattingMessage =
                ChatMessageEntity.fromJson(newMessage);
            onNewMessage(newChattingMessage);
            onNotifyListeners();
          },
        )
        .subscribe();
  }

  /// 방 정보 구독 설정
  /// 
  /// [itemId] 아이템 ID
  /// [roomId] 채팅방 ID (nullable)
  /// [onItemUpdate] 아이템 정보 업데이트 콜백
  /// [onAuctionUpdate] 경매 정보 업데이트 콜백
  /// [onTradeUpdate] 거래 정보 업데이트 콜백
  /// [onUnreadCountUpdate] 읽지 않은 메시지 수 업데이트 콜백
  /// [onNotifyListeners] UI 업데이트 콜백
  void subscribeToRoomInfo({
    required String itemId,
    String? roomId,
    void Function(ItemInfoEntity)? onItemUpdate,
    void Function(AuctionInfoEntity)? onAuctionUpdate,
    void Function(TradeInfoEntity?)? onTradeUpdate,
    void Function(int)? onUnreadCountUpdate,
    required void Function() onNotifyListeners,
  }) {
    // 기존 채널 정리
    _disposeRoomInfoChannels();

    // 아이템 정보 구독
    if (onItemUpdate != null) {
      _itemsChannel = _supabase.channel('items_detail$itemId');
      _itemsChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'items_detail',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'item_id',
              value: itemId,
            ),
            callback: (payload) {
              final updateItem = payload.newRecord;
              final ItemInfoEntity updateItemInfo =
                  ItemInfoEntity.fromJson(updateItem);
              onItemUpdate(updateItemInfo);
              onNotifyListeners();
            },
          )
          .subscribe();
    }

    // 경매 정보 구독
    if (onAuctionUpdate != null) {
      _auctionsChannel = _supabase.channel('auctions$itemId');
      _auctionsChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'auctions',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'item_id',
              value: itemId,
            ),
            callback: (payload) {
              final updateAuction = payload.newRecord;
              final AuctionInfoEntity updateAuctionInfo =
                  AuctionInfoEntity.fromJson(updateAuction);
              onAuctionUpdate(updateAuctionInfo);
              onNotifyListeners();
            },
          )
          .subscribe();
    }

    // 거래 정보 구독
    if (onTradeUpdate != null) {
      _tradeChannel = _supabase.channel('trade_status$itemId');
      _tradeChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            table: 'trade_info',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'item_id',
              value: itemId,
            ),
            callback: (payload) {
              final data = payload.newRecord;
              final userId = _supabase.auth.currentUser?.id;
              if (userId == null || data['buyer_id'] != userId) {
                return; // 조건 안 맞으면 무시
              }
              switch (payload.eventType) {
                case PostgresChangeEvent.insert:
                  onTradeUpdate(TradeInfoEntity.fromJson(payload.newRecord));
                  break;
                case PostgresChangeEvent.update:
                  onTradeUpdate(TradeInfoEntity.fromJson(payload.newRecord));
                  break;
                case PostgresChangeEvent.delete:
                  onTradeUpdate(null);
                  break;
                case PostgresChangeEvent.all:
                  break;
              }
              onNotifyListeners();
            },
          )
          .subscribe();
    }

    // 읽지 않은 메시지 수 구독
    if (onUnreadCountUpdate != null && roomId != null) {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        _roomUsersChannel = _supabase.channel('chatting_room_users$roomId');
        _roomUsersChannel!
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'chatting_room_users',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'room_id',
                value: roomId,
              ),
              callback: (payload) {
                final data = payload.newRecord;

                // 현재 사용자의 unread_count만 확인
                if (data['user_id'] == userId) {
                  final newUnreadCount = data['unread_count'] as int? ?? 0;
                  onUnreadCountUpdate(newUnreadCount);
                }
              },
            )
            .subscribe();
      }
    }
  }

  /// 방 정보 구독 채널 정리
  void _disposeRoomInfoChannels() {
    if (_itemsChannel != null) {
      _supabase.removeChannel(_itemsChannel!);
      _itemsChannel = null;
    }
    if (_auctionsChannel != null) {
      _supabase.removeChannel(_auctionsChannel!);
      _auctionsChannel = null;
    }
    if (_tradeChannel != null) {
      _supabase.removeChannel(_tradeChannel!);
      _tradeChannel = null;
    }
    if (_roomUsersChannel != null) {
      _supabase.removeChannel(_roomUsersChannel!);
      _roomUsersChannel = null;
    }
  }

  /// 메시지 구독 해제
  void unsubscribeFromMessages() {
    if (_messageChannel != null) {
      _supabase.removeChannel(_messageChannel!);
      _messageChannel = null;
    }
  }

  /// 방 정보 구독 해제
  void unsubscribeFromRoomInfo() {
    _disposeRoomInfoChannels();
  }

  /// 모든 구독 해제
  void dispose() {
    unsubscribeFromMessages();
    unsubscribeFromRoomInfo();
  }
}

