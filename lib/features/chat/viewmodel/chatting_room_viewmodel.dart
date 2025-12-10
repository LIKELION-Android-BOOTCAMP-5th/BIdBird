import 'package:bidbird/core/managers/chatting_room_service.dart';
import 'package:bidbird/core/managers/cloudinary_manager.dart';
import 'package:bidbird/core/managers/heartbeat_manager.dart';
import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/data/repositories/chat_repositorie.dart';
import 'package:bidbird/features/chat/model/chat_message_entity.dart';
import 'package:bidbird/features/chat/model/room_info_entity.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MessageType { text, image }

class ChattingRoomViewmodel extends ChangeNotifier {
  final ChattingRoomService _chattingRoomService = ChattingRoomService();
  String? roomId;
  String itemId;
  bool isActive = false;
  XFile? image;
  RoomInfoEntity? roomInfo;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController messageController = TextEditingController();
  List<ChatMessageEntity> messages = [];
  MessageType type = MessageType.text;

  ChatRepositorie _repository = ChatRepositorie();

  ChattingRoomViewmodel({required this.itemId}) {
    print("뷰모델 생성");
    fetchRoomInfo();
    fetchMessage();
  }

  RealtimeChannel? _subscribeMessageChannel;
  // RealtimeChannel? _itemsChannel;
  // RealtimeChannel? _bidLogChannel;

  Future<void> getRoomId() async {
    roomId = await _repository.getRoomId(itemId);
  }

  Future<void> fetchRoomInfo() async {
    roomInfo = await _repository.fetchRoomInfo(itemId);
    notifyListeners();
  }

  Future<void> fetchMessage() async {
    roomId = await _repository.getRoomId(itemId);
    print("뷰모델에서 채팅방 id = ${roomId}");
    print("뷰모델에서 메세지 fetch");
    if (roomId != null) {
      final chattings = await _repository.getMessages(roomId!);
      messages.addAll(chattings);
      notifyListeners();
      setupRealtimeSubscription();
      init();
    }
  }

  Future<void> sendMessage() async {
    final currentRoomId = roomId;
    if (currentRoomId == null) {
      if (type == MessageType.text) {
        if (messageController.text.isEmpty) return;
        try {
          roomId = await _repository.firstMessage(
            itemId: itemId,
            messageType: type,
            message: messageController.text,
          );
        } catch (e) {
          print("메세지 전송 실패");
          return;
        }
        final chattings = await _repository.getMessages(roomId!);
        messages.addAll(chattings);
        messageController.text = "";
        notifyListeners();
        setupRealtimeSubscription();
        init();
      } else {
        final thisImage = image;
        if (thisImage == null) return;
        try {
          final imageUrl = await CloudinaryManager.shared
              .uploadImageToCloudinary(thisImage);
          if (imageUrl == null) return;
          roomId = await _repository.firstMessage(
            itemId: itemId,
            messageType: type,
            imageUrl: imageUrl,
          );
        } catch (e) {
          print("메세지 전송 실패");
          return;
        }
        final chattings = await _repository.getMessages(roomId!);
        messages.addAll(chattings);
        image = null;
        type = MessageType.text;
        notifyListeners();
        setupRealtimeSubscription();
        init();
      }
    } else {
      if (type == MessageType.text) {
        if (messageController.text.isEmpty) return;
        try {
          await _repository.sendTextMessage(
            currentRoomId,
            messageController.text,
          );
        } catch (e) {
          print('메세지 전송 실패 : ${e}');
          return;
        }
        messageController.text = "";
        notifyListeners();
      } else {
        final thisImage = image;
        if (thisImage == null) return;
        try {
          final imageUrl = await CloudinaryManager.shared
              .uploadImageToCloudinary(thisImage);
          if (imageUrl == null) return;
          await _repository.sendImageMessage(currentRoomId, imageUrl);
        } catch (e) {
          print('메세지 전송 실패 : ${e}');
          return;
        }
        image = null;
        type = MessageType.text;
        notifyListeners();
      }
    }
  }

  // Call when view appears
  Future<void> init() async {
    print("init");
    final thisRoomId = roomId;
    print("init roomId check : $thisRoomId");
    if (thisRoomId == null) return;
    await chattingRoomService.enterRoom(thisRoomId);

    heartbeatManager.start(thisRoomId);
    isActive = true;
    notifyListeners();
  }

  // Call when view disappears
  Future<void> disposeViewModel() async {
    final thisRoomId = roomId;
    if (thisRoomId != null) {
      await chattingRoomService.leaveRoom(thisRoomId);
      heartbeatManager.stop();

      isActive = false;
    }
  }

  Future<void> leaveRoom() async {
    await disposeViewModel();
    dispose();
  }

  Future<void> enterRoom() async {
    init();
    if (roomId != null && _subscribeMessageChannel == null) {
      setupRealtimeSubscription();
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isActive) return;
    final thisRoomId = roomId;
    if (thisRoomId == null) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      heartbeatManager.stop();
    } else if (state == AppLifecycleState.resumed) {
      heartbeatManager.start(thisRoomId);
    }
  }

  void setupRealtimeSubscription() {
    print("채널 구독 전 roomId 확인");
    print("roomId = ${roomId}");
    _subscribeMessageChannel = SupabaseManager.shared.supabase.channel(
      'chatting_message$roomId',
    );
    _subscribeMessageChannel!
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
            print("Change received : ${payload.toString()}");
            messages.add(newChattingMessage);
            notifyListeners();
          },
        )
        .subscribe();
    print("_subscribeMessageChannel 채널 연결 되었습니다");
  }

  // RealtimeChannel _subscribeMessageEvent() {
  //   return SupabaseManager.shared.supabase
  //       .channel('chatting_message$roomId')
  //       .onPostgresChanges(
  //         event: PostgresChangeEvent.insert,
  //         schema: 'public',
  //         table: 'chatting_message',
  //         filter: PostgresChangeFilter(
  //           type: PostgresChangeFilterType.eq,
  //           column: 'room_id',
  //           value: roomId,
  //         ),
  //         callback: (payload) {
  //           final newMessage = payload.newRecord;
  //           final ChatMessageEntity newChattingMessage =
  //               ChatMessageEntity.fromJson(newMessage);
  //           print("Change received : ${payload.toString()}");
  //           messages.add(newChattingMessage);
  //           notifyListeners();
  //         },
  //       );
  // }
  @override
  void dispose() {
    if (_subscribeMessageChannel != null)
      SupabaseManager.shared.supabase.removeChannel(_subscribeMessageChannel!);
    print("_subscribeMessageChannel 채널 닫혔습니다");
    // if (_itemsChannel != null) _supabase.removeChannel(_itemsChannel!);
    // if (_bidLogChannel != null) _supabase.removeChannel(_bidLogChannel!);
    super.dispose();
  }

  Future<void> pickImagesFromGallery() async {
    image = await _picker.pickImage(
      imageQuality: 80,
      source: ImageSource.gallery,
    );
    if (image == null) {
      return;
    }

    notifyListeners();
  }

  Future<void> pickImageFromCamera() async {
    image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image == null) return;

    notifyListeners();
  }
}
