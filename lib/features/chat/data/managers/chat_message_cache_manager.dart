import 'dart:convert';

import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 채팅 메시지 캐시 관리자
/// SharedPreferences를 사용한 메시지 캐싱 로직을 관리하는 클래스
class ChatMessageCacheManager {
  static const String _cachePrefix = 'chat_messages_cache_';
  static const String _lastMessageTimePrefix = 'chat_messages_last_time_';

  /// 캐시에서 메시지 불러오기
  Future<List<ChatMessageEntity>> getCachedMessages(String chattingRoomId) async {
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

  /// 마지막 메시지 시간 가져오기
  Future<String?> getLastMessageTime(String chattingRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeKey = '$_lastMessageTimePrefix$chattingRoomId';
      return prefs.getString(timeKey);
    } catch (e) {
      return null;
    }
  }

  /// 마지막 메시지 시간 저장
  Future<void> saveLastMessageTime(String chattingRoomId, String lastMessageTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeKey = '$_lastMessageTimePrefix$chattingRoomId';
      await prefs.setString(timeKey, lastMessageTime);
    } catch (e) {
      // 저장 실패 시 무시
    }
  }

  /// 메시지를 캐시에 저장
  Future<void> saveMessagesToCache(
    String chattingRoomId,
    List<ChatMessageEntity> messages,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$chattingRoomId';
      final jsonList = messages.map((msg) => msg.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(jsonList));
    } catch (e) {
      // 캐시 저장 실패 시 무시
    }
  }

  /// 특정 채팅방의 캐시 삭제
  Future<void> clearCache(String chattingRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$chattingRoomId';
      await prefs.remove(cacheKey);
    } catch (e) {
      // 캐시 삭제 실패 시 무시
    }
  }

  /// 모든 채팅 메시지 캐시 삭제
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => key.startsWith(_cachePrefix));
      for (final key in cacheKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      // 캐시 삭제 실패 시 무시
    }
  }
}

