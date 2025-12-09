import 'package:bidbird/core/managers/chatting_room_service.dart';
import 'package:bidbird/core/managers/heartbeat_manager.dart';
import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/data/repositories/chat_repositorie.dart';
import 'package:bidbird/features/chat/model/chat_message_entity.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum MessageType { text, image }

class ChattingRoomViewmodel extends ChangeNotifier {
  final ChattingRoomService _chattingRoomService = ChattingRoomService();
  String? roomId;
  String? itemId;
  bool isActive = false;
  XFile? image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController messageController = TextEditingController();
  List<ChatMessageEntity> messages = [];
  MessageType type = MessageType.text;

  ChatRepositorie _repository = ChatRepositorie();

  ChattingRoomViewmodel({required this.itemId}) {
    print("뷰모델 생성");
    fetchMessage();
  }

  RealtimeChannel? _subscribeMessageChannel;
  // RealtimeChannel? _itemsChannel;
  // RealtimeChannel? _bidLogChannel;

  Future<void> getRoomId() async {
    roomId = await _repository.getRoomId(itemId!);
  }

  Future<void> fetchMessage() async {
    roomId = await _repository.getRoomId(itemId!);
    print("뷰모델에서 채팅방 id = ${roomId}");
    print("뷰모델에서 메세지 fetch");
    if (roomId != null) {
      final chattings = await _repository.getMessages(roomId!);
      messages.addAll(chattings);
      notifyListeners();
      setupRealtimeSubscription();
      print("_subscribeMessageChannel 채널 연결 되었습니다");
      init();
    }
  }

  // Call when view appears
  Future<void> init() async {
    final thisRoomId = roomId;
    if (thisRoomId != null) {
      await chattingRoomService.enterRoom(thisRoomId);
      heartbeatManager.start(thisRoomId);
      isActive = true;
      notifyListeners();
    }
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
