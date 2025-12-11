import 'dart:async';

import 'package:bidbird/core/managers/chatting_room_service.dart';
import 'package:bidbird/core/managers/cloudinary_manager.dart';
import 'package:bidbird/core/managers/heartbeat_manager.dart';
import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/data/repositories/chat_repositorie.dart';
import 'package:bidbird/features/chat/model/chat_message_entity.dart';
import 'package:bidbird/features/chat/model/chatting_notification_set_entity.dart';
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
  ItemInfoEntity? itemInfo;
  AuctionInfoEntity? auctionInfo;
  TradeInfoEntity? tradeInfo;
  double? imageAspectRatio; // width / height
  final ImagePicker _picker = ImagePicker();
  final TextEditingController messageController = TextEditingController();
  List<ChatMessageEntity> messages = [];
  MessageType type = MessageType.text;
  bool isSending = false;
  final ScrollController scrollController = ScrollController();
  ChattingNotificationSetEntity? notificationSetting;
  bool isLoadingMore = false;
  bool hasMore = true;

  ChatRepositorie _repository = ChatRepositorie();

  ChattingRoomViewmodel({required this.itemId, required this.roomId}) {
    print("뷰모델 생성");
    fetchRoomInfo();
    fetchMessage();

    Timer? _debounce;
    scrollController.addListener(() async {
      if (_debounce?.isActive ?? false) _debounce!.cancel();

      // 리스트 상단 근처에 도달했을 때 이전 메시지 로딩 (디바운스 적용)
      _debounce = Timer(const Duration(milliseconds: 150), () {
        if (scrollController.offset <= 40) {
          loadMoreMessages();
        }
      });
    });
  }

  RealtimeChannel? _subscribeMessageChannel;
  RealtimeChannel? _itemsChannel;
  RealtimeChannel? _auctionsChannel;
  RealtimeChannel? _tradeChannel;
  // RealtimeChannel? _bidLogChannel;

  Future<void> fetchRoomInfo() async {
    final currentRoomId = roomId;
    if (currentRoomId != null) {
      roomInfo = await _repository.fetchRoomInfoWithRoomId(currentRoomId);
    } else {
      roomInfo = await _repository.fetchRoomInfo(itemId);
    }
    itemInfo = roomInfo?.item;
    auctionInfo = roomInfo?.auction;
    tradeInfo = roomInfo?.trade;
    setupRealtimeRoomInfoSubscription();
    notifyListeners();
  }

  Future<void> fetchMessage() async {
    final currentRoomId = roomId;
    if (currentRoomId != null) {
      final chattings = await _repository.getMessages(currentRoomId);
      messages.addAll(chattings);
      hasMore = chattings.length >= 50;
      notifyListeners();
      setupRealtimeSubscription();
      init();
    } else {
      print("불러오기 실패");
    }
  }

  Future<void> sendMessage() async {
    if (isSending == true) return;
    isSending = true;
    final currentRoomId = roomId;
    if (currentRoomId == null) {
      if (type == MessageType.text) {
        if (messageController.text.isEmpty) {
          isSending = false;
          notifyListeners();
          return;
        }
        try {
          roomId = await _repository.firstMessage(
            itemId: itemId,
            messageType: type,
            message: messageController.text,
          );
        } catch (e) {
          print("메세지 전송 실패");
          isSending = false;
          notifyListeners();
          return;
        }
        final chattings = await _repository.getMessages(roomId!);
        messages.addAll(chattings);
        messageController.text = "";
        notifyListeners();
        setupRealtimeSubscription();
        init();
        isSending = false;
        notifyListeners();
      } else {
        final thisImage = image;
        if (thisImage == null) {
          isSending = false;
          notifyListeners();
          return;
        }
        try {
          final imageUrl = await CloudinaryManager.shared
              .uploadImageToCloudinary(thisImage);
          if (imageUrl == null) {
            isSending = false;
            notifyListeners();
            return;
          }
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
        isSending = false;
        notifyListeners();
      }
    } else {
      if (type == MessageType.text) {
        if (messageController.text.isEmpty) {
          isSending = false;
          notifyListeners();
          return;
        }
        try {
          await _repository.sendTextMessage(
            currentRoomId,
            messageController.text,
          );
        } catch (e) {
          print('메세지 전송 실패 : ${e}');
          isSending = false;
          notifyListeners();
          return;
        }
        messageController.text = "";
        isSending = false;
        notifyListeners();
      } else {
        final thisImage = image;
        if (thisImage == null) {
          isSending = false;
          notifyListeners();
          return;
        }
        try {
          final imageUrl = await CloudinaryManager.shared
              .uploadImageToCloudinary(thisImage);
          if (imageUrl == null) {
            isSending = false;
            notifyListeners();
            return;
          }
          await _repository.sendImageMessage(currentRoomId, imageUrl);
        } catch (e) {
          print('메세지 전송 실패 : ${e}');
          isSending = false;
          notifyListeners();
          return;
        }
        image = null;
        type = MessageType.text;
        isSending = false;
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
    await getRoomNotificationSetting();
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

  Future<void> getRoomNotificationSetting() async {
    final thisRoomId = roomId;
    if (thisRoomId == null) return;
    notificationSetting = await _repository.getRoomNotificationSetting(
      thisRoomId,
    );
    notifyListeners();
  }

  Future<void> notificationToggle() async {
    final thisRoomId = roomId;
    if (thisRoomId == null || notificationSetting == null) return;
    if (notificationSetting?.is_notification_on == true) {
      await notificationOff();
    } else {
      await notificationOn();
    }
  }

  Future<void> notificationOff() async {
    final thisRoomId = roomId;
    if (thisRoomId == null || notificationSetting == null) return;
    notificationSetting?.is_notification_on = false;
    notifyListeners();
    try {
      _repository.notificationOff(thisRoomId);
    } catch (e) {
      notificationSetting?.is_notification_on = true;
      notifyListeners();
    }
  }

  Future<void> notificationOn() async {
    final thisRoomId = roomId;
    if (thisRoomId == null || notificationSetting == null) return;
    notificationSetting?.is_notification_on = true;
    notifyListeners();
    try {
      _repository.notificationOn(thisRoomId);
    } catch (e) {
      notificationSetting?.is_notification_on = false;
      notifyListeners();
    }
  }

  void setupRealtimeRoomInfoSubscription() {
    _itemsChannel = SupabaseManager.shared.supabase.channel(
      'items_detail$itemId',
    );
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
            final ItemInfoEntity updateItemInfo = ItemInfoEntity.fromJson(
              updateItem,
            );
            print("Change received : ${payload.toString()}");
            itemInfo = updateItemInfo;
            notifyListeners();
          },
        )
        .subscribe();
    print("_subscribeMessageChannel 채널 연결 되었습니다");

    _auctionsChannel = SupabaseManager.shared.supabase.channel(
      'auctions$itemId',
    );
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
            print("Change received : ${payload.toString()}");
            auctionInfo = updateAuctionInfo;
            notifyListeners();
          },
        )
        .subscribe();
    print("_auctionsChannel 채널 연결 되었습니다");
    _tradeChannel = SupabaseManager.shared.supabase.channel(
      'trade_status$itemId',
    );
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
            final data = payload.newRecord ?? payload.oldRecord;
            final userId = SupabaseManager.shared.supabase.auth.currentUser!.id;
            if (data == null) return;
            if (data['buyer_id'] != userId) {
              return; // 조건 안 맞으면 무시
            }
            switch (payload.eventType) {
              case PostgresChangeEvent.insert:
                tradeInfo = TradeInfoEntity.fromJson(payload.newRecord);
                break;

              case PostgresChangeEvent.update:
                tradeInfo = TradeInfoEntity.fromJson(payload.newRecord);
                break;

              case PostgresChangeEvent.delete:
                tradeInfo = null;
                break;
              case PostgresChangeEvent.all:
                break;
            }
            notifyListeners();
          },
        )
        .subscribe();
    print("_tradeChannel 채널 연결 되었습니다");
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
    if (_itemsChannel != null)
      SupabaseManager.shared.supabase.removeChannel(_itemsChannel!);
    print("_itemsChannel 채널 닫혔습니다");
    if (_auctionsChannel != null)
      SupabaseManager.shared.supabase.removeChannel(_auctionsChannel!);
    print("_auctionsChannel 채널 닫혔습니다");
    if (_tradeChannel != null)
      SupabaseManager.shared.supabase.removeChannel(_tradeChannel!);
    print("_tradeChannel 채널 닫혔습니다");
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
    final decoded = await decodeImageFromList(await image!.readAsBytes());
    imageAspectRatio = decoded.width / decoded.height;
    type = MessageType.image;
    notifyListeners();
  }

  Future<void> pickImageFromCamera() async {
    image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image == null) return;
    final decoded = await decodeImageFromList(await image!.readAsBytes());
    imageAspectRatio = decoded.width / decoded.height;
    type = MessageType.image;
    notifyListeners();
  }

  void clearImage() {
    image = null;
    imageAspectRatio = null;
    type = MessageType.text;
    notifyListeners();
  }

  Future<void> loadMoreMessages() async {
    if (!hasMore || isLoadingMore || messages.isEmpty) {
      return;
    }

    final currentRoomId = roomId;
    if (currentRoomId == null) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      final oldestMessage = messages.first;
      final beforeCreatedAtIso = oldestMessage.created_at;

      final olderMessages = await _repository.getOlderMessages(
        currentRoomId,
        beforeCreatedAtIso,
        limit: 50,
      );

      if (olderMessages.isEmpty) {
        hasMore = false;
      } else {
        messages.insertAll(0, olderMessages);
        if (olderMessages.length < 50) {
          hasMore = false;
        }
      }
    } catch (e) {
      print('이전 메시지 로딩 실패: $e');
    }

    isLoadingMore = false;
    notifyListeners();
  }
}
