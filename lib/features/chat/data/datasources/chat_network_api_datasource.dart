import 'package:bidbird/core/managers/network_api_manager.dart';
import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';
import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatNetworkApiDatasource {
  final dio = Dio();
  ChatNetworkApiDatasource();
  Future<List<ChattingRoomEntity>> fetchChattingRoomList() async {
    final response = await SupabaseManager.shared.supabase.functions.invoke(
      'chatting/roomList',
      method: HttpMethod.get,
      headers: NetworkApiManager.headers,
    );
    if (response.data != null) {
      final List data = response.data;
      final List<ChattingRoomEntity> results = data.map((json) {
        return ChattingRoomEntity.fromJson(json);
      }).toList();

      return results;
    } else {
      return List.empty();
    }
  }

  Future<RoomInfoEntity?> fetchRoomInfo(String itemId) async {
    try {
      final response = await SupabaseManager.shared.supabase.functions.invoke(
        'chatting/roomInfo',
        method: HttpMethod.post,
        headers: NetworkApiManager.useThisHeaders(),
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
      final response = await SupabaseManager.shared.supabase.functions.invoke(
        'chatting/roomInfoWithRoomId',
        method: HttpMethod.post,
        headers: NetworkApiManager.useThisHeaders(),
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

      final response = await SupabaseManager.shared.supabase.functions.invoke(
        'chatting/creatChattingRoom',
        method: HttpMethod.post,
        headers: NetworkApiManager.useThisHeaders(),
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
  Future<void> cancelTrade(String itemId, String reasonCode, bool isSellerFault) async {
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
      final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
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
