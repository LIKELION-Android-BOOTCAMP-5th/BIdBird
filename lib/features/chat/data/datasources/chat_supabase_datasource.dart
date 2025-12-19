import 'package:bidbird/core/managers/network_api_manager.dart';
import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/data/managers/chat_message_cache_manager.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_notification_set_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';
import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 채팅 데이터 소스
class ChatSupabaseDatasource {
  ChatSupabaseDatasource({SupabaseClient? supabase})
    : _supabase = supabase ?? SupabaseManager.shared.supabase;

  static const String _chatRoomsTable = 'chatting_room';
  static const String _roomUserTable = 'chatting_room_users';

  final SupabaseClient _supabase;
  final _cacheManager = ChatMessageCacheManager();

  Future<List<ChatMessageEntity>> getMessages(
    String chattingRoomId, {
    bool forceRefresh = false,
  }) async {
    // 먼저 캐시에서 불러오기
    final cachedMessages = await _cacheManager.getCachedMessages(
      chattingRoomId,
    );

    // 강제 새로고침이 아니고 캐시가 있으면 마지막 메시지 시간 확인
    if (!forceRefresh && cachedMessages.isNotEmpty) {
      final cachedLastTime = await _cacheManager.getLastMessageTime(
        chattingRoomId,
      );
      if (cachedLastTime != null) {
        // 캐시된 마지막 메시지 시간과 현재 캐시의 마지막 메시지 시간 비교
        final cachedLastMessage = cachedMessages.isNotEmpty
            ? cachedMessages.first.createdAt
            : null;

        // 캐시된 시간과 일치하면 네트워크 호출 생략
        if (cachedLastMessage == cachedLastTime) {
          return cachedMessages;
        }
      }
    }

    try {
      // Edge Function 호출
      final response = await _supabase.functions.invoke(
        'get-messages',
        body: {'roomId': chattingRoomId, 'page': 1, 'limit': 20},
      );

      final data = response.data;
      if (data != null) {
        if (data is Map && data.containsKey('error')) {
          // 에러 발생 시 캐시 반환
          if (cachedMessages.isNotEmpty) {
            return cachedMessages;
          }
          return List.empty();
        }

        if (data is List) {
          final List<ChatMessageEntity> results = data.map((json) {
            return ChatMessageEntity.fromJson(json);
          }).toList();

          // 네트워크에서 가져온 메시지를 캐시에 저장
          await _cacheManager.saveMessagesToCache(chattingRoomId, results);

          // 마지막 메시지 시간 저장 (변경 감지용)
          if (results.isNotEmpty) {
            await _cacheManager.saveLastMessageTime(
              chattingRoomId,
              results.first.createdAt,
            );
          }

          return results;
        }
      }

      // 네트워크에서 메시지가 없으면 캐시 반환
      if (cachedMessages.isNotEmpty) {
        return cachedMessages;
      }
    } catch (e) {
      // 네트워크 오류 시 캐시 반환
      if (cachedMessages.isNotEmpty) {
        return cachedMessages;
      }
      return List.empty();
    }
    return List.empty();
  }

  Future<List<ChatMessageEntity>> getOlderMessages({
    required String roomId,
    required String beforeCreatedAtIso,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-older-messages',
        body: {
          'roomId': roomId,
          'beforeCreatedAt': beforeCreatedAtIso,
          'limit': limit,
        },
      );

      final data = response.data;
      if (data != null) {
        if (data is Map && data.containsKey('error')) {
          return List.empty();
        }

        if (data is List) {
          final List<ChatMessageEntity> results = data.map((json) {
            return ChatMessageEntity.fromJson(json);
          }).toList();
          return results;
        }
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
      await _supabase.from('chatting_message').insert({
        'room_id': roomId,
        'sender_id': currentUserId,
        'message_type': 'text',
        'text': message,
      });
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
      final response = await _supabase.functions.invoke(
        'get-chat-list',
        body: {'page': page, 'limit': limit},
      );

      final data = response.data;
      if (data == null) {
        return List.empty();
      }

      if (data is List) {
        final List<ChattingRoomEntity> results = data.map((json) {
          return ChattingRoomEntity.fromJson(json);
        }).toList();
        return results;
      }

      return List.empty();
    } catch (e) {
      return List.empty();
    }
  }

  Future<ChattingRoomEntity?> fetchNewChattingRoom(String roomId) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-new-chat-room',
        body: {'room_id': roomId},
      );
      final data = response.data;
      if (data == null) return null;
      final result = ChattingRoomEntity.fromJson(data);
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<RoomInfoEntity?> fetchRoomInfo(String itemId) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-room-info',
        body: {'itemId': itemId},
      );
      final data = response.data;
      final result = RoomInfoEntity.fromJson(data);
      return result;
    } catch (e) {
      return null;
    }
  }

  Future<RoomInfoEntity?> fetchRoomInfoWithRoomId(String roomId) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-room-info',
        body: {'roomId': roomId},
      );
      final data = response.data;
      final result = RoomInfoEntity.fromJson(data);
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
      final body = <String, dynamic>{
        'itemId': itemId,
        'message_type': messageType,
      };

      if (messageType == "text" && message != null) {
        body['message'] = message;
      } else if (messageType == "image" && imageUrl != null) {
        body['imageUrl'] = imageUrl;
      }

      final response = await _supabase.functions.invoke(
        'create-chat-room',
        body: body,
      );

      if (response.data == null) return null;
      final data = response.data['room_id'] as String;
      return data;
    } catch (e) {
      return null;
    }
  }

  /// 거래 완료 API 호출
  Future<void> completeTrade(String itemId) async {
    try {
      await SupabaseManager.shared.supabase.functions.invoke(
        'completeTrade',
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
        'cancelTrade',
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
