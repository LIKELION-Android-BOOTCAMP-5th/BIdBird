import 'package:bidbird/core/managers/network_api_manager.dart';
import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_notification_set_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';
import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 채팅 데이터 소스
class ChatSupabaseDatasource {
  ChatSupabaseDatasource({SupabaseClient? supabase})
    : _supabase = supabase ?? SupabaseManager.shared.supabase;

  static const String _chatRoomsTable = 'chatting_room';
  static const String _roomUserTable = 'chatting_room_users';

  final SupabaseClient _supabase;

  Future<List<ChatMessageEntity>> getMessages(
    String chattingRoomId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_messages_v2',
        params: {
          '_room_id': chattingRoomId,
          '_page': 1,
          '_limit': 20,
        },
      );

      if (response is Map && response.containsKey('error')) {
        return List.empty();
      }

      if (response is List) {
        final List<ChatMessageEntity> results = response.map((json) {
          return ChatMessageEntity.fromJson(json as Map<String, dynamic>);
        }).toList();
        return results;
      }

      return List.empty();
    } catch (e) {
      return List.empty();
    }
  }

  Future<List<ChatMessageEntity>> getOlderMessages({
    required String roomId,
    required String beforeCreatedAtIso,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_older_messages_v2',
        params: {
          '_room_id': roomId,
          '_before_created_at': beforeCreatedAtIso,
          '_limit': limit,
        },
      );

      if (response is Map && response.containsKey('error')) {
        return List.empty();
      }

      if (response is List) {
        final List<ChatMessageEntity> results = response.map((json) {
          return ChatMessageEntity.fromJson(json as Map<String, dynamic>);
        }).toList();
        return results;
      }

      return List.empty();
    } catch (e) {
      return List.empty();
    }
  }

  Future<String?> getRoomId(String itemId) async {
    final String? currentUserId =
        SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;
    try {
      final response = await SupabaseManager.shared.supabase
          .from(_chatRoomsTable)
          .select('id')
          .eq('item_id', itemId)
          .or('seller_id.eq.$currentUserId, buyer_id.eq.$currentUserId')
          .maybeSingle();
      if (response != null) {
        final data = response['id'] as String;
        return data;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> sendTextMessage(String roomId, String message) async {
    final String? currentUserId =
        SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    try {
      // 메시지 전송
      await _supabase.from('chatting_message').insert({
        'room_id': roomId,
        'sender_id': currentUserId,
        'message_type': 'text',
        'text': message,
      });

      // chatting_room 업데이트
      await _supabase.from('chatting_room').update({
        'last_message': message,
        'last_message_send_at': DateTime.now().toIso8601String(),
      }).eq('id', roomId);

      // 상대방의 unread_count 증가
      final roomData = await _supabase.from('chatting_room').select('seller_id, buyer_id').eq('id', roomId).single();
      final opponentId = roomData['seller_id'] == currentUserId ? roomData['buyer_id'] : roomData['seller_id'];
      final userRoomData = await _supabase.from('chatting_room_users').select('unread_count').eq('room_id', roomId).eq('user_id', opponentId).single();
      final currentUnread = (userRoomData['unread_count'] as int?) ?? 0;
      await _supabase.from('chatting_room_users').update({
        'unread_count': currentUnread + 1,
      }).eq('room_id', roomId).eq('user_id', opponentId);
    } catch (e) {
      // 메시지 전송 실패 시 무시
    }
  }

  Future<void> sendImageMessage(String roomId, String imageUrl) async {
    final String? currentUserId =
        SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    try {
      await _supabase.from('chatting_message').insert({
        'room_id': roomId,
        'sender_id': currentUserId,
        'message_type': 'image',
        'image_url': imageUrl,
      });

      // chatting_room 업데이트
      await _supabase.from('chatting_room').update({
        'last_message': '사진',
        'last_message_send_at': DateTime.now().toIso8601String(),
      }).eq('id', roomId);

      // 상대방의 unread_count 증가
      final roomData = await _supabase.from('chatting_room').select('seller_id, buyer_id').eq('id', roomId).single();
      final opponentId = roomData['seller_id'] == currentUserId ? roomData['buyer_id'] : roomData['seller_id'];
      final userRoomData = await _supabase.from('chatting_room_users').select('unread_count').eq('room_id', roomId).eq('user_id', opponentId).single();
      final currentUnread = (userRoomData['unread_count'] as int?) ?? 0;
      await _supabase.from('chatting_room_users').update({
        'unread_count': currentUnread + 1,
      }).eq('room_id', roomId).eq('user_id', opponentId);
    } catch (e) {
      // 메시지 전송 실패 시 무시
    }
  }

  Future<ChattingNotificationSetEntity?> getRoomNotificationSetting(
    String roomId,
  ) async {
    final String? currentUserId =
        SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;
    try {
      final response = await SupabaseManager.shared.supabase
          .from(_roomUserTable)
          .select('*')
          .eq('room_id', roomId)
          .eq('user_id', currentUserId)
          .maybeSingle();
      if (response != null) {
        final data = ChattingNotificationSetEntity.fromJson(response);
        return data;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> notificationOn(String roomId) async {
    final String? currentUserId =
        SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await _supabase
          .from(_roomUserTable)
          .update({'is_notification_on': true})
          .eq('room_id', roomId)
          .eq('user_id', currentUserId);
    } catch (e) {
      return;
    }
    return;
  }

  Future<void> notificationOff(String roomId) async {
    final String? currentUserId =
        SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await _supabase
          .from(_roomUserTable)
          .update({'is_notification_on': false})
          .eq('room_id', roomId)
          .eq('user_id', currentUserId);
    } catch (e) {
      return;
    }
    return;
  }

  Future<List<ChattingRoomEntity>> fetchChattingRoomList({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('🐛 [ChatSupabaseDatasource] fetchChattingRoomList params: page=$page, limit=$limit');
      
      final response = await _supabase.rpc(
        'get_chat_list_v2',
        params: {
          '_page': page,
          '_limit': limit,
        },
      );

      debugPrint('🐛 [ChatSupabaseDatasource] fetchChattingRoomList raw response type: ${response.runtimeType}');
      // debugPrint('🐛 [ChatSupabaseDatasource] fetchChattingRoomList raw response: $response');

      if (response is Map && response.containsKey('error')) {
        debugPrint('🐛 [ChatSupabaseDatasource] Error in response: ${response['error']}');
        return List.empty();
      }

      if (response is List) {
        debugPrint('🐛 [ChatSupabaseDatasource] Parsing ${response.length} items...');
        final List<ChattingRoomEntity> results = response.map((json) {
          try {
             return ChattingRoomEntity.fromJson(json as Map<String, dynamic>);
          } catch (e) {
             debugPrint('🐛 [ChatSupabaseDatasource] Parsing error for item: $json, error: $e');
             rethrow;
          }
        }).toList();
        debugPrint('🐛 [ChatSupabaseDatasource] Successfully parsed ${results.length} items.');
        return results;
      }

      debugPrint('🐛 [ChatSupabaseDatasource] Response is not a List or Map with error.');
      return List.empty();
    } catch (e) {
      debugPrint('🐛 [ChatSupabaseDatasource] Exception in fetchChattingRoomList: $e');
      return List.empty();
    }
  }

  Future<ChattingRoomEntity?> fetchNewChattingRoom(String roomId) async {
    try {
      final response = await _supabase.rpc(
        'get_new_chat_room_v2',
        params: {'_room_id': roomId},
      );

      if (response is Map && response.containsKey('error')) {
        return null;
      }

      final result = ChattingRoomEntity.fromJson(response as Map<String, dynamic>);
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<RoomInfoEntity?> fetchRoomInfo(String itemId) async {
    try {
      final response = await _supabase.rpc(
        'get_room_info_v2',
        params: {'_item_id': itemId},
      );

      if (response is Map && response.containsKey('error')) {
        return null;
      }

      final result = RoomInfoEntity.fromJson(response as Map<String, dynamic>);
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<RoomInfoEntity?> fetchRoomInfoWithRoomId(String roomId) async {
    try {
      final response = await _supabase.rpc(
        'get_room_info_v2',
        params: {'_room_id': roomId},
      );

      if (response is Map && response.containsKey('error')) {
        return null;
      }

      final result = RoomInfoEntity.fromJson(response as Map<String, dynamic>);
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<String?> firstMessage({
    required String itemId,
    String? message,
    required String messageType,
    String? imageUrl,
  }) async {
    if (messageType != "text" && messageType != "image") {
      return null;
    }

    try {
      final params = <String, dynamic>{
        '_item_id': itemId,
        '_message_type': messageType,
      };

      if (messageType == "text" && message != null) {
        params['_message'] = message;
      } else if (messageType == "image" && imageUrl != null) {
        params['_image_url'] = imageUrl;
      }

      final response = await _supabase.rpc(
        'create_chat_room_v2',
        params: params,
      );

      if (response is Map && response.containsKey('error')) {
        return null;
      }

      if (response is Map && response.containsKey('room_id')) {
        return response['room_id'] as String;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> leaveChatRoom(String roomId) async {
    try {
      await _supabase.rpc(
        'leave_chat_room_v2',
        params: {'_room_id': roomId},
      );
    } catch (e) {
      // 채팅방 나가기 실패 시 무시
    }
  }

  /// 거래 완료 API 호출 (임시)
  Future<void> completeTrade(String itemId) async {
    try {
      await SupabaseManager.shared.supabase.functions.invoke(
        'temporary_completeTrade',
        method: HttpMethod.post,
        headers: NetworkApiManager.useThisHeaders(),
        body: {'itemId': itemId},
      );
    } catch (e) {
      throw Exception('거래 완료 처리 중 오류가 발생했습니다: $e');
    }
  }

  /// 거래 취소 API 호출
  Future<void> cancelTrade(
    String itemId,
    String reasonCode,
    bool isSellerFault,
  ) async {
    try {
      await SupabaseManager.shared.supabase.functions.invoke(
        'temporary_cancelTrade',
        method: HttpMethod.post,
        headers: NetworkApiManager.useThisHeaders(),
        body: {
          'itemId': itemId,
          'reasonCode': reasonCode,
          'isSellerFault': isSellerFault,
        },
      );
    } catch (e) {
      throw Exception('거래 취소 처리 중 오류가 발생했습니다: $e');
    }
  }

  /// 거래 평가 작성 API 호출
  Future<void> submitTradeReview({
    required String itemId,
    required String toUserId,
    required String role,
    required double rating,
    required String comment,
  }) async {
    try {
      final response = await SupabaseManager.shared.supabase.functions.invoke(
        'submitTradeReview',
        method: HttpMethod.post,
        headers: NetworkApiManager.useThisHeaders(),
        body: {
          'itemId': itemId,
          'toUserId': toUserId,
          'role': role,
          'rating': rating,
          'comment': comment,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] != true) {
          final errorMessage = data['error'] ?? '거래 평가 작성에 실패했습니다.';
          throw Exception(errorMessage);
        }
      }
    } catch (e) {
      throw Exception('거래 평가 작성 중 오류가 발생했습니다: $e');
    }
  }

  /// 거래 평가 작성 여부 확인
  Future<bool> hasSubmittedReview(String itemId) async {
    try {
      final currentUserId =
          SupabaseManager.shared.supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        return false;
      }

      final response = await SupabaseManager.shared.supabase
          .from('user_review')
          .select('id')
          .eq('item_id', itemId)
          .eq('from_user_id', currentUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}
