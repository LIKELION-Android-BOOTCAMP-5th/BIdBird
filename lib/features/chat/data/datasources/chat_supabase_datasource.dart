import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/model/chat_message_entity.dart';
import 'package:bidbird/features/chat/model/chatting_notification_set_entity.dart';

/// 채팅 데이터 소스
class ChatSupabaseDatasource {
  static const String _chatRoomsTable = 'chatting_room';
  static const String _messagesTable = 'chatting_message';
  static const String _roomUserTable = 'chatting_room_users';

  final _supabase = SupabaseManager.shared.supabase;

  Future<List<ChatMessageEntity>> getMessages(String chattingRoomId) async {
    print("SupabaseChatDatasource 에서 메세지 fetch");
    try {
      final response = await SupabaseManager.shared.supabase
          .from(_messagesTable)
          .select('*')
          .eq('room_id', chattingRoomId)
          .order('created_at', ascending: true);
      print("data 데이터 타입: ${response.runtimeType}");
      print("$response");
      if (response.isNotEmpty) {
        final List<dynamic> data = response;
        print("data 데이터 타입: ${data.runtimeType}");
        final List<ChatMessageEntity> results = data.map((json) {
          return ChatMessageEntity.fromJson(json);
        }).toList();
        return results;
      }
    } catch (e) {
      print("불러오기 실패 : ${e}");
      return List.empty();
    }
    return List.empty();
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
      print("data 데이터 타입: ${response.runtimeType}");
      print("$response");
      if (response != null) {
        final data = response['id'] as String;
        return data;
      }
    } catch (e) {
      print("불러오기 실패 : ${e}");
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
      print('메시지 전송에 실패했습니다 : ${e}');
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
      print('메시지 전송에 실패했습니다 : ${e}');
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
      print("알림 셋팅 불러오기 실패 : ${e}");
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
      print('푸시알림 키는데 실패했습니다 : ${e}');
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
      print('푸시알림 키는데 실패했습니다 : ${e}');
      return;
    }
    return;
  }

  /// 채팅방 목록 조회
  // Future<Result<List<ChattingRoomEntity>>> getChatRooms(String userId) async {
  //   try {
  //     final response = await SupabaseManager.shared.supabase
  //         .from(_chatRoomsTable)
  //         .select('*')
  //         .or('user1_id.eq."$userId",user2_id.eq."$userId"')
  //         .order('updated_at', ascending: false);
  //
  //     if (response is! List) {
  //       return Success<List<ChattingRoomEntity>>([]);
  //     }
  //
  //     final chatRooms = <ChattingRoomEntity>[];
  //     for (final json in response) {
  //       final data = Map<String, dynamic>.from(json);
  //
  //       // 상대방 정보 추출
  //       String? otherUserId;
  //       if (data['user1_id'] == userId) {
  //         otherUserId = data['user2_id'] as String;
  //       } else {
  //         otherUserId = data['user1_id'] as String;
  //       }
  //
  //       // 상대방 프로필 조회
  //       String? otherUserName;
  //       String? otherUserImageUrl;
  //       try {
  //         final profileResponse = await SupabaseManager.shared.supabase
  //             .from('user_profiles')
  //             .select('name, profile_image_url')
  //             .eq('user_id', otherUserId)
  //             .maybeSingle();
  //
  //         if (profileResponse != null) {
  //           final profile = Map<String, dynamic>.from(profileResponse);
  //           otherUserName = profile['name'] as String?;
  //           otherUserImageUrl = profile['profile_image_url'] as String?;
  //         }
  //       } catch (e) {
  //         debugPrint('프로필 조회 실패: $e');
  //       }
  //
  //       // 마지막 메시지 조회
  //       Message? lastMessage;
  //       try {
  //         final lastMessageResponse = await SupabaseManager.shared.supabase
  //             .from(_messagesTable)
  //             .select(
  //               'id, chat_room_id, content, created_at, sender_id, is_read, is_system_message',
  //             )
  //             .eq('chat_room_id', data['id'])
  //             .order('created_at', ascending: false)
  //             .limit(1)
  //             .maybeSingle();
  //
  //         if (lastMessageResponse != null) {
  //           lastMessage = ChatMessageEntity.fromJson(lastMessageResponse);
  //         }
  //       } catch (e) {
  //         debugPrint('마지막 메시지 조회 실패: $e');
  //       }
  //
  //       // 읽지 않은 메시지 수 조회
  //       int unreadCount = 0;
  //       try {
  //         final unreadResponse = await SupabaseManager.shared.supabase
  //             .from(_messagesTable)
  //             .select('id')
  //             .eq('chat_room_id', data['id'])
  //             .eq('is_read', false)
  //             .neq('sender_id', userId);
  //         unreadCount = (unreadResponse as List).length;
  //       } catch (e) {
  //         debugPrint('읽지 않은 메시지 수 조회 실패: $e');
  //       }
  //
  //       chatRooms.add(
  //         ChattingRoomEntity.fromJson({
  //           ...data,
  //           'other_user_name': otherUserName,
  //           'other_user_image_url': otherUserImageUrl,
  //           'last_message': lastMessage?.toJson(),
  //           'unread_count': unreadCount,
  //         }),
  //       );
  //     }
  //
  //     return Success(chatRooms);
  //   } catch (e) {
  //     debugPrint('채팅방 목록 조회 실패: $e');
  //     return Failure('채팅방 목록을 불러올 수 없습니다: $e');
  //   }
  // }
  //
  // /// 채팅방 생성 또는 조회
  // Future<Result<ChatRoom>> getOrCreateChatRoom({
  //   required String user1Id,
  //   required String user2Id,
  // }) async {
  //   try {
  //     debugPrint(
  //       '[SupabaseChatDatasource] getOrCreateChatRoom 시작 - user1Id: $user1Id, user2Id: $user2Id',
  //     );
  //
  //     final sortedUserIds = [user1Id, user2Id]..sort();
  //     final sortedUser1Id = sortedUserIds[0];
  //     final sortedUser2Id = sortedUserIds[1];
  //
  //     debugPrint(
  //       '[SupabaseChatDatasource] 정렬된 ID - sortedUser1Id: $sortedUser1Id, sortedUser2Id: $sortedUser2Id',
  //     );
  //
  //     debugPrint('[SupabaseChatDatasource] 기존 채팅방 조회 시작');
  //     final existingResponse = await SupabaseService.client
  //         .from(_chatRoomsTable)
  //         .select()
  //         .eq('user1_id', sortedUser1Id)
  //         .eq('user2_id', sortedUser2Id)
  //         .maybeSingle();
  //
  //     debugPrint(
  //       '[SupabaseChatDatasource] 기존 채팅방 조회 완료 - existingResponse: ${existingResponse != null ? "있음" : "없음"}',
  //     );
  //
  //     if (existingResponse != null) {
  //       debugPrint('[SupabaseChatDatasource] 기존 채팅방 발견 - 데이터 변환 시작');
  //       final chatRoom = ChatRoom.fromJson(existingResponse);
  //       debugPrint(
  //         '[SupabaseChatDatasource] Entity 변환 완료 - id: ${chatRoom.id}',
  //       );
  //       return Success(chatRoom);
  //     }
  //
  //     debugPrint('[SupabaseChatDatasource] 새 채팅방 생성 시작');
  //     final insertResponse = await SupabaseService.client
  //         .from(_chatRoomsTable)
  //         .insert({
  //           'user1_id': sortedUser1Id,
  //           'user2_id': sortedUser2Id,
  //           'created_at': DateTime.now().toIso8601String(),
  //           'updated_at': DateTime.now().toIso8601String(),
  //         })
  //         .select()
  //         .single();
  //
  //     debugPrint('[SupabaseChatDatasource] 새 채팅방 생성 완료');
  //     final chatRoom = ChatRoom.fromJson(insertResponse);
  //     debugPrint('[SupabaseChatDatasource] Entity 변환 완료 - id: ${chatRoom.id}');
  //     return Success(chatRoom);
  //   } catch (e, stackTrace) {
  //     debugPrint('[SupabaseChatDatasource] 채팅방 생성/조회 실패: $e');
  //     debugPrint('[SupabaseChatDatasource] 스택 트레이스: $stackTrace');
  //     return Failure('채팅방을 생성할 수 없습니다: $e');
  //   }
  // }
  //
  // /// 메시지 전송
  // Future<Result<Message>> sendMessage({
  //   required String chatRoomId,
  //   required String senderId,
  //   required String content,
  // }) async {
  //   try {
  //     final insertResponse = await SupabaseService.client
  //         .from(_messagesTable)
  //         .insert({
  //           'chat_room_id': chatRoomId,
  //           'sender_id': senderId,
  //           'content': content,
  //           'is_read': false,
  //           'created_at': DateTime.now().toIso8601String(),
  //         })
  //         .select()
  //         .single();
  //
  //     await SupabaseService.client
  //         .from(_chatRoomsTable)
  //         .update({'updated_at': DateTime.now().toIso8601String()})
  //         .eq('id', chatRoomId);
  //
  //     return Success(Message.fromJson(insertResponse));
  //   } catch (e) {
  //     debugPrint('메시지 전송 실패: $e');
  //     return Failure('메시지를 전송할 수 없습니다: $e');
  //   }
  // }
  //
  // /// 메시지 Realtime 리스닝
  // Stream<List<Message>> watchMessages(String chatRoomId) {
  //   return SupabaseService.client
  //       .from(_messagesTable)
  //       .stream(primaryKey: ['id'])
  //       .eq('chat_room_id', chatRoomId)
  //       .order('created_at', ascending: true)
  //       .map((data) {
  //         return data.map((json) => Message.fromJson(json)).toList();
  //       });
  // }
  //
  // /// 채팅방 목록 Realtime 리스닝
  // Stream<List<ChatRoom>> watchChatRooms(String userId) {
  //   // stream에서는 .or()가 지원되지 않으므로 두 개의 스트림을 합침
  //   final stream1 = SupabaseService.client
  //       .from(_chatRoomsTable)
  //       .stream(primaryKey: ['id'])
  //       .eq('user1_id', userId)
  //       .order('updated_at', ascending: false);
  //
  //   final stream2 = SupabaseService.client
  //       .from(_chatRoomsTable)
  //       .stream(primaryKey: ['id'])
  //       .eq('user2_id', userId)
  //       .order('updated_at', ascending: false);
  //
  //   // messages 테이블의 변경도 감지하여 읽지 않은 메시지 수 업데이트
  //   final messagesStream = SupabaseService.client
  //       .from(_messagesTable)
  //       .stream(primaryKey: ['id']);
  //
  //   // 두 스트림을 합치고 중복 제거
  //   final controller = StreamController<List<ChatRoom>>();
  //   final allChatRooms = <String, ChatRoom>{};
  //
  //   Future<void> updateStream() async {
  //     // 모든 채팅방의 읽지 않은 메시지 수와 마지막 메시지를 다시 계산
  //     for (final chatRoomId in allChatRooms.keys.toList()) {
  //       try {
  //         // 읽지 않은 메시지 수 조회
  //         final unreadResponse = await SupabaseService.client
  //             .from(_messagesTable)
  //             .select('id')
  //             .eq('chat_room_id', chatRoomId)
  //             .eq('is_read', false)
  //             .neq('sender_id', userId);
  //         final unreadCount = (unreadResponse as List).length;
  //
  //         // 마지막 메시지 조회
  //         Message? lastMessage;
  //         try {
  //           final lastMessageResponse = await SupabaseService.client
  //               .from(_messagesTable)
  //               .select(
  //                 'id, chat_room_id, content, created_at, sender_id, is_read',
  //               )
  //               .eq('chat_room_id', chatRoomId)
  //               .order('created_at', ascending: false)
  //               .limit(1)
  //               .maybeSingle();
  //
  //           if (lastMessageResponse != null) {
  //             try {
  //               lastMessage = Message.fromJson(lastMessageResponse);
  //             } catch (e) {
  //               debugPrint('마지막 메시지 파싱 실패: $e');
  //             }
  //           }
  //         } catch (e) {
  //           debugPrint('마지막 메시지 조회 실패: $e');
  //         }
  //
  //         final chatRoom = allChatRooms[chatRoomId];
  //         if (chatRoom != null) {
  //           // ChatRoom 객체 재생성 (copyWith가 없으므로)
  //           final updatedChatRoom = ChatRoom.fromJson({
  //             'id': chatRoom.id,
  //             'user1_id': chatRoom.user1Id,
  //             'user2_id': chatRoom.user2Id,
  //             'created_at': chatRoom.createdAt.toIso8601String(),
  //             'updated_at': chatRoom.updatedAt.toIso8601String(),
  //             'other_user_name': chatRoom.otherUserName,
  //             'other_user_image_url': chatRoom.otherUserImageUrl,
  //             'last_message': lastMessage?.toJson(),
  //             'unread_count': unreadCount,
  //           });
  //           allChatRooms[chatRoomId] = updatedChatRoom;
  //         }
  //       } catch (e) {
  //         debugPrint('채팅방 업데이트 실패: $e');
  //       }
  //     }
  //
  //     final sortedRooms = allChatRooms.values.toList()
  //       ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  //     controller.add(sortedRooms);
  //   }
  //
  //   StreamSubscription? sub1;
  //   StreamSubscription? sub2;
  //   StreamSubscription? sub3;
  //
  //   sub1 = stream1.listen((data) {
  //     Future.wait(
  //       data.map((json) async {
  //         final chatRoomData = Map<String, dynamic>.from(json);
  //         final chatRoom = await _processChatRoomData(chatRoomData, userId);
  //         allChatRooms[chatRoom.id] = chatRoom;
  //       }),
  //     ).then((_) => updateStream());
  //   }, onError: (error) => controller.addError(error));
  //
  //   sub2 = stream2.listen((data) {
  //     Future.wait(
  //       data.map((json) async {
  //         final chatRoomData = Map<String, dynamic>.from(json);
  //         final chatRoom = await _processChatRoomData(chatRoomData, userId);
  //         allChatRooms[chatRoom.id] = chatRoom;
  //       }),
  //     ).then((_) => updateStream());
  //   }, onError: (error) => controller.addError(error));
  //
  //   // messages 테이블 변경 감지하여 읽지 않은 메시지 수 업데이트
  //   sub3 = messagesStream.listen(
  //     (data) {
  //       // 메시지가 변경되면 해당 채팅방의 읽지 않은 메시지 수를 다시 계산
  //       final chatRoomIds = <String>{};
  //       for (final messageData in data) {
  //         final chatRoomId = messageData['chat_room_id'] as String?;
  //         if (chatRoomId != null) {
  //           chatRoomIds.add(chatRoomId);
  //         }
  //       }
  //
  //       // 해당 채팅방들의 읽지 않은 메시지 수와 마지막 메시지 업데이트
  //       Future.wait(
  //         chatRoomIds.map((chatRoomId) async {
  //           if (allChatRooms.containsKey(chatRoomId)) {
  //             try {
  //               // 읽지 않은 메시지 수 조회
  //               final unreadResponse = await SupabaseService.client
  //                   .from(_messagesTable)
  //                   .select('id')
  //                   .eq('chat_room_id', chatRoomId)
  //                   .eq('is_read', false)
  //                   .neq('sender_id', userId);
  //               final unreadCount = (unreadResponse as List).length;
  //
  //               // 마지막 메시지 조회
  //               Message? lastMessage;
  //               try {
  //                 final lastMessageResponse = await SupabaseService.client
  //                     .from(_messagesTable)
  //                     .select(
  //                       'id, chat_room_id, content, created_at, sender_id, is_read, is_system_message',
  //                     )
  //                     .eq('chat_room_id', chatRoomId)
  //                     .order('created_at', ascending: false)
  //                     .limit(1)
  //                     .maybeSingle();
  //
  //                 if (lastMessageResponse != null) {
  //                   try {
  //                     lastMessage = Message.fromJson(lastMessageResponse);
  //                   } catch (e) {
  //                     debugPrint('마지막 메시지 파싱 실패: $e');
  //                   }
  //                 }
  //               } catch (e) {
  //                 debugPrint('마지막 메시지 조회 실패: $e');
  //               }
  //
  //               final chatRoom = allChatRooms[chatRoomId];
  //               if (chatRoom != null) {
  //                 // ChatRoom 객체 재생성 (copyWith가 없으므로)
  //                 final updatedChatRoom = ChatRoom.fromJson({
  //                   'id': chatRoom.id,
  //                   'user1_id': chatRoom.user1Id,
  //                   'user2_id': chatRoom.user2Id,
  //                   'created_at': chatRoom.createdAt.toIso8601String(),
  //                   'updated_at': chatRoom.updatedAt.toIso8601String(),
  //                   'other_user_name': chatRoom.otherUserName,
  //                   'other_user_image_url': chatRoom.otherUserImageUrl,
  //                   'last_message': lastMessage?.toJson(),
  //                   'unread_count': unreadCount,
  //                 });
  //                 allChatRooms[chatRoomId] = updatedChatRoom;
  //               }
  //             } catch (e) {
  //               debugPrint('채팅방 업데이트 실패: $e');
  //             }
  //           }
  //         }),
  //       ).then((_) {
  //         final sortedRooms = allChatRooms.values.toList()
  //           ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  //         controller.add(sortedRooms);
  //       });
  //     },
  //     onError: (error) {
  //       debugPrint('메시지 스트림 오류: $error');
  //     },
  //   );
  //
  //   controller.onCancel = () {
  //     sub1?.cancel();
  //     sub2?.cancel();
  //     sub3?.cancel();
  //   };
  //
  //   return controller.stream;
  // }
  //
  // /// 채팅방 데이터 처리 헬퍼 메서드
  // Future<ChatRoom> _processChatRoomData(
  //   Map<String, dynamic> chatRoomData,
  //   String userId,
  // ) async {
  //   String? otherUserId;
  //   if (chatRoomData['user1_id'] == userId) {
  //     otherUserId = chatRoomData['user2_id'] as String;
  //   } else {
  //     otherUserId = chatRoomData['user1_id'] as String;
  //   }
  //
  //   String? otherUserName;
  //   String? otherUserImageUrl;
  //   try {
  //     final profileResponse = await SupabaseService.client
  //         .from('user_profiles')
  //         .select('name, profile_image_url')
  //         .eq('id', otherUserId)
  //         .maybeSingle();
  //
  //     if (profileResponse != null) {
  //       final profile = Map<String, dynamic>.from(profileResponse);
  //       otherUserName = profile['name'] as String?;
  //       otherUserImageUrl = profile['profile_image_url'] as String?;
  //     }
  //   } catch (e) {
  //     debugPrint('프로필 조회 실패: $e');
  //   }
  //
  //   Message? lastMessage;
  //   try {
  //     final lastMessageResponse = await SupabaseService.client
  //         .from(_messagesTable)
  //         .select(
  //           'id, chat_room_id, content, created_at, sender_id, is_read, is_system_message',
  //         )
  //         .eq('chat_room_id', chatRoomData['id'])
  //         .order('created_at', ascending: false)
  //         .limit(1)
  //         .maybeSingle();
  //
  //     if (lastMessageResponse != null) {
  //       try {
  //         lastMessage = Message.fromJson(lastMessageResponse);
  //       } catch (e) {
  //         debugPrint('마지막 메시지 파싱 실패: $e');
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint('마지막 메시지 조회 실패: $e');
  //   }
  //
  //   int unreadCount = 0;
  //   try {
  //     final unreadResponse = await SupabaseService.client
  //         .from(_messagesTable)
  //         .select('id')
  //         .eq('chat_room_id', chatRoomData['id'])
  //         .eq('is_read', false)
  //         .neq('sender_id', userId);
  //     unreadCount = (unreadResponse as List).length;
  //   } catch (e) {
  //     debugPrint('읽지 않은 메시지 수 조회 실패: $e');
  //   }
  //
  //   return ChatRoom.fromJson({
  //     ...chatRoomData,
  //     'other_user_name': otherUserName,
  //     'other_user_image_url': otherUserImageUrl,
  //     'last_message': lastMessage?.toJson(),
  //     'unread_count': unreadCount,
  //   });
  // }
  //
  // /// 메시지 읽음 처리
  // Future<Result<void>> markMessagesAsRead({
  //   required String chatRoomId,
  //   required String userId,
  // }) async {
  //   try {
  //     await SupabaseService.client
  //         .from(_messagesTable)
  //         .update({'is_read': true})
  //         .eq('chat_room_id', chatRoomId)
  //         .neq('sender_id', userId)
  //         .eq('is_read', false);
  //
  //     return const Success(null);
  //   } catch (e) {
  //     debugPrint('메시지 읽음 처리 실패: $e');
  //     return Failure('메시지 읽음 처리를 할 수 없습니다: $e');
  //   }
  // }
}
