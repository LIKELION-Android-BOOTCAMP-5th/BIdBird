import 'dart:convert';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_notification_set_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 채팅 데이터 소스
class ChatSupabaseDatasource {
  static const String _chatRoomsTable = 'chatting_room';
  static const String _messagesTable = 'chatting_message';
  static const String _roomUserTable = 'chatting_room_users';
  static const String _cachePrefix = 'chat_messages_cache_';

  final _supabase = SupabaseManager.shared.supabase;

  // 캐시에서 메시지 불러오기
  Future<List<ChatMessageEntity>> _getCachedMessages(String chattingRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$chattingRoomId';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList.map((json) => ChatMessageEntity.fromJson(json)).toList();
      }
    } catch (e) {
      // 캐시 불러오기 실패 시 빈 리스트 반환
    }
    return [];
  }

  // 메시지를 캐시에 저장
  Future<void> _saveMessagesToCache(String chattingRoomId, List<ChatMessageEntity> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$chattingRoomId';
      final jsonList = messages.map((msg) => msg.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));
    } catch (e) {
      // 캐시 저장 실패 시 무시
    }
  }

  Future<List<ChatMessageEntity>> getMessages(String chattingRoomId) async {
    // 먼저 캐시에서 불러오기
    final cachedMessages = await _getCachedMessages(chattingRoomId);
    
    try {
      final response = await SupabaseManager.shared.supabase
          .from(_messagesTable)
          .select('*')
          .eq('room_id', chattingRoomId)
          .order('created_at', ascending: false)
          .limit(50);
      
      if (response.isNotEmpty) {
        final List<dynamic> data = response;
        final List<ChatMessageEntity> results = data.map((json) {
          return ChatMessageEntity.fromJson(json);
        }).toList();

        // Supabase에서 최신 메시지 기준 내림차순으로 가져왔으므로
        // UI에서는 예전 -> 최신 순으로 보이도록 뒤집어서 반환
        final networkMessages = results.reversed.toList();
        
        // 네트워크에서 가져온 메시지를 캐시에 저장
        await _saveMessagesToCache(chattingRoomId, networkMessages);
        
        return networkMessages;
      } else {
        // 네트워크에서 메시지가 없으면 캐시 반환
        if (cachedMessages.isNotEmpty) {
          return cachedMessages;
        }
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
      final response = await SupabaseManager.shared.supabase.rpc(
        'get_chat_messages_before',
        params: <String, dynamic>{
          'p_room_id': roomId,
          'p_before': beforeCreatedAtIso,
          'p_limit': limit,
        },
      );

      if (response is! List) {
        return List.empty();
      }

      final data = response.cast<Map<String, dynamic>>();
      final results = data
          .map((json) => ChatMessageEntity.fromJson(json))
          .toList();

      // 함수에서 created_at desc 로 내려주므로, UI에서는 asc 로 보이게 뒤집기
      return results.reversed.toList();
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
}
