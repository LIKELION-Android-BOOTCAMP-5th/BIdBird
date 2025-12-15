import 'dart:async';

import 'package:bidbird/core/managers/chatting_room_service.dart';
import 'package:bidbird/core/managers/heartbeat_manager.dart';
import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/data/repositories/chat_repository.dart';
import 'package:bidbird/features/item/shipping/data/repository/shipping_info_repository.dart';
import 'package:bidbird/features/chat/domain/entities/auction_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_notification_set_entity.dart';
import 'package:bidbird/features/chat/domain/entities/item_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/trade_info_entity.dart';
import 'package:bidbird/features/chat/domain/usecases/get_messages_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/get_older_messages_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/get_room_id_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/get_room_info_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/get_room_info_with_room_id_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/get_room_notification_setting_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/message_type.dart';
import 'package:bidbird/features/chat/domain/usecases/send_first_message_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/send_image_message_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/send_text_message_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/turn_off_notification_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/turn_on_notification_usecase.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/features/chat/presentation/managers/image_picker_manager.dart';
import 'package:bidbird/features/chat/presentation/managers/message_send_manager.dart';
import 'package:bidbird/features/chat/presentation/managers/message_sender.dart';
import 'package:bidbird/features/chat/presentation/managers/read_status_manager.dart';
import 'package:bidbird/features/chat/presentation/managers/realtime_subscription_manager.dart';
import 'package:bidbird/features/chat/presentation/managers/room_info_manager.dart';
import 'package:bidbird/features/chat/presentation/managers/scroll_manager.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChattingRoomViewmodel extends ChangeNotifier {
  String? roomId;
  String itemId;
  bool isActive = false;
  List<XFile> images = []; // 여러 이미지 지원
  RoomInfoEntity? roomInfo;
  ItemInfoEntity? itemInfo;
  AuctionInfoEntity? auctionInfo;
  TradeInfoEntity? tradeInfo;
  bool _hasShippingInfo = false;
  bool get hasShippingInfo => _hasShippingInfo;
  final TextEditingController messageController = TextEditingController();
  List<ChatMessageEntity> messages = [];
  MessageType type = MessageType.text;
  bool isSending = false;
  ChattingNotificationSetEntity? notificationSetting;
  bool isLoadingMore = false;
  bool hasMore = false;

  int? previousUnreadCount; // 이전 unreadCount 값을 저장

  // Manager 클래스들
  late final ScrollManager _scrollManager;
  late final RealtimeSubscriptionManager _subscriptionManager;
  late final ReadStatusManager _readStatusManager;
  late final MessageSendManager _messageSendManager;
  late final RoomInfoManager _roomInfoManager;
  late final ImagePickerManager _imagePickerManager;

  // ScrollManager의 getter들
  ScrollController get scrollController => _scrollManager.scrollController;
  ScrollPhysics? get listViewPhysics => _scrollManager.listViewPhysics;
  bool get isScrollPositionReady => _scrollManager.isScrollPositionReady;
  bool get hasScrolledToUnread => _scrollManager.hasScrolledToUnread;
  bool get isInitialLoad => _scrollManager.isInitialLoad;
  bool get isUserScrolling => _scrollManager.isUserScrolling;

  /// 현재 사용자가 낙찰자인지 확인
  bool get isTopBidder {
    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null || auctionInfo == null) return false;
    
    return auctionInfo!.lastBidUserId == currentUserId;
  }

  /// 낙찰자가 존재하는지 확인 (last_bid_user_id가 null이 아닌지)
  bool get hasTopBidder {
    return auctionInfo?.lastBidUserId != null && auctionInfo!.lastBidUserId!.isNotEmpty;
  }

  final ChatRepositoryImpl _repository = ChatRepositoryImpl();

  // UseCases - 생성자에서 직접 초기화
  late final GetMessagesUseCase _getMessagesUseCase = GetMessagesUseCase(
    _repository,
  );
  late final GetOlderMessagesUseCase _getOlderMessagesUseCase =
      GetOlderMessagesUseCase(_repository);
  late final GetRoomIdUseCase _getRoomIdUseCase = GetRoomIdUseCase(_repository);
  late final GetRoomInfoUseCase _getRoomInfoUseCase = GetRoomInfoUseCase(
    _repository,
  );
  late final GetRoomInfoWithRoomIdUseCase _getRoomInfoWithRoomIdUseCase =
      GetRoomInfoWithRoomIdUseCase(_repository);
  late final GetRoomNotificationSettingUseCase
  _getRoomNotificationSettingUseCase = GetRoomNotificationSettingUseCase(
    _repository,
  );
  late final SendTextMessageUseCase _sendTextMessageUseCase =
      SendTextMessageUseCase(_repository);
  late final SendImageMessageUseCase _sendImageMessageUseCase =
      SendImageMessageUseCase(_repository);
  late final SendFirstMessageUseCase _sendFirstMessageUseCase =
      SendFirstMessageUseCase(_repository);
  late final TurnOnNotificationUseCase _turnOnNotificationUseCase =
      TurnOnNotificationUseCase(_repository);
  late final TurnOffNotificationUseCase _turnOffNotificationUseCase =
      TurnOffNotificationUseCase(_repository);


  ChattingRoomViewmodel({
    required this.itemId,
    required this.roomId,
    ScrollManager? scrollManager,
    RealtimeSubscriptionManager? subscriptionManager,
    ReadStatusManager? readStatusManager,
    MessageSendManager? messageSendManager,
    RoomInfoManager? roomInfoManager,
    ImagePickerManager? imagePickerManager,
  }) {
    // Manager 클래스 초기화
    _scrollManager = scrollManager ?? ScrollManager(ScrollController());
    _subscriptionManager = subscriptionManager ?? RealtimeSubscriptionManager();
    _readStatusManager = readStatusManager ?? ReadStatusManager();
    _messageSendManager = messageSendManager ??
        MessageSendManager(
          sendFirstMessageUseCase: _sendFirstMessageUseCase,
          sendTextMessageUseCase: _sendTextMessageUseCase,
          sendImageMessageUseCase: _sendImageMessageUseCase,
        );
    _roomInfoManager = roomInfoManager ??
        RoomInfoManager(
          getRoomInfoUseCase: _getRoomInfoUseCase,
          getRoomInfoWithRoomIdUseCase: _getRoomInfoWithRoomIdUseCase,
        );
    _imagePickerManager = imagePickerManager ?? ImagePickerManager();

    // 더 많은 메시지 로드 리스너 설정
    _scrollManager.setupLoadMoreListener(() {
      loadMoreMessages();
    });

    // roomInfo와 messages를 모두 로드
    fetchRoomInfo();
    fetchMessage();
  }


  Future<void> fetchRoomInfo() async {
    final result = await _roomInfoManager.fetchRoomInfo(
      roomId: roomId,
      itemId: itemId,
    );

    final newUnreadCount = result.unreadCount;

    // unread_count를 기반으로 마지막으로 본 메시지까지 읽음 처리
    if (messages.isNotEmpty) {
      _markMessagesAsReadUpToLastViewed(newUnreadCount);
    }

    // unreadCount 변경 감지: 이전에 읽지 않은 메시지가 있었는데 지금 0이 되면 하단으로 스크롤
    // 단, 사용자가 수동으로 스크롤 중이 아니고, 초기 로드가 아닐 때만
    if (previousUnreadCount != null &&
        previousUnreadCount! > 0 &&
        newUnreadCount == 0 &&
        !isUserScrolling &&
        !isInitialLoad) {
      // 강제로 하단으로 스크롤
      scrollToBottom(force: true);
    }

    previousUnreadCount = newUnreadCount;
    roomInfo = result.roomInfo;
    itemInfo = result.itemInfo;
    auctionInfo = result.auctionInfo;
    tradeInfo = result.tradeInfo;
    _hasShippingInfo = result.hasShippingInfo;
    
    setupRealtimeRoomInfoSubscription();
    notifyListeners();
  }

  // 디바운스를 적용한 fetchRoomInfo 호출
  void fetchRoomInfoDebounced() {
    _roomInfoManager.fetchRoomInfoDebounced(
      roomId: roomId,
      itemId: itemId,
      callback: (result) async {
        final newUnreadCount = result.unreadCount;

        // unread_count를 기반으로 마지막으로 본 메시지까지 읽음 처리
        if (messages.isNotEmpty) {
          _markMessagesAsReadUpToLastViewed(newUnreadCount);
        }

        // unreadCount 변경 감지
        if (previousUnreadCount != null &&
            previousUnreadCount! > 0 &&
            newUnreadCount == 0 &&
            !isUserScrolling &&
            !isInitialLoad) {
          scrollToBottom(force: true);
        }

        previousUnreadCount = newUnreadCount;
        roomInfo = result.roomInfo;
        itemInfo = result.itemInfo;
        auctionInfo = result.auctionInfo;
        tradeInfo = result.tradeInfo;
        _hasShippingInfo = result.hasShippingInfo;
        
        setupRealtimeRoomInfoSubscription();
        notifyListeners();
      },
    );
  }

  // 하단으로 스크롤하는 메서드
  void scrollToBottom({bool force = false, bool instant = false}) {
    if (messages.isEmpty) return;
    _scrollManager.scrollToBottom(force: force, instant: instant);
  }

  // unread_count를 기반으로 마지막으로 본 메시지까지 읽음 처리
  void _markMessagesAsReadUpToLastViewed(int unreadCount) {
    _readStatusManager.markMessagesAsReadUpToLastViewed(
      messages,
      unreadCount,
      onMarkAsRead: (message) {
        // 읽음 처리 로그 (필요시)
        // 실제 읽음 처리는 서버에서 처리되므로 여기서는 로그만 남김
      },
    );

    // roomInfo의 lastMessageAt을 마지막으로 본 메시지 시간으로 업데이트
    if (roomInfo != null) {
      // roomInfo는 immutable이므로 직접 업데이트할 수 없음
      // 대신 fetchRoomInfo를 호출하여 최신 정보를 가져옴
      // 하지만 무한 루프를 방지하기 위해 디바운스 적용
      fetchRoomInfoDebounced();
    }
  }

  // 읽지 않은 메시지가 있는지 확인하고 첫 번째 읽지 않은 메시지의 인덱스를 반환
  int findFirstUnreadMessageIndex() {
    if (roomInfo == null || messages.isEmpty) return -1;
    return _readStatusManager.findFirstUnreadMessageIndex(
      messages,
      roomInfo!.unreadCount,
      roomInfo!.lastMessageAt,
    );
  }

  // 첫 번째 읽지 않은 메시지로 스크롤
  void scrollToFirstUnreadMessage({bool instant = false}) {
    if (messages.isEmpty) return;
    final index = findFirstUnreadMessageIndex();
    _scrollManager.scrollToUnreadOrBottom(index, instant: instant);
  }

  Future<void> fetchMessage() async {
    try {
      final currentRoomId = roomId;
      if (currentRoomId != null) {
        final chattings = await _getMessagesUseCase(currentRoomId);

        messages.clear(); // 기존 메시지 초기화
        messages.addAll(chattings);
        hasMore = chattings.length >= 50;

        // 스크롤 위치 초기화 (항상 하단으로)
        _scrollManager.initializeScrollPosition(
          shouldScrollToBottom: true,
          messagesCount: messages.length,
        );
        notifyListeners();

        setupRealtimeSubscription();
        init();
      } else {
        // roomId가 없으면 itemId로 roomId를 먼저 가져오기 시도
        final fetchedRoomId = await _getRoomIdUseCase(itemId);

        if (fetchedRoomId != null) {
          roomId = fetchedRoomId;
          await fetchMessage(); // 재귀 호출로 다시 시도
        } else {
          notifyListeners();
        }
      }
    } catch (e, stackTrace) {
      notifyListeners();
    }
  }

  // 에러 처리 헬퍼 메서드
  void _handleSendError(String error, [Object? e]) {
    isSending = false;
    notifyListeners();
  }


  // 첫 메시지 전송 후 처리 헬퍼 메서드
  Future<void> _handleFirstMessageSent() async {
    try {
      // 메시지 전송 후 DB 반영을 위해 잠시 대기
      await Future.delayed(const Duration(milliseconds: 500));
      
      // fetchMessage를 호출하여 메시지 리스트를 다시 불러오기
      // fetchMessage 내부에서 setupRealtimeSubscription()과 init()을 호출하므로 여기서는 호출하지 않음
      await fetchMessage();
      
      // fetchMessage 내부에서 이미 setupRealtimeSubscription()과 init()을 호출하지만,
      // roomInfo는 별도로 업데이트 필요
      await fetchRoomInfo();
      
      isSending = false;
      notifyListeners();
      scrollToBottom(force: true);
    } catch (e) {
      isSending = false;
      notifyListeners();
    }
  }

  // 기존 채팅방에서 메시지 전송 후 최신 메시지 불러오기 헬퍼 메서드
  Future<void> _refreshLatestMessage(String roomId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final latestMessages = await _repository.getMessages(roomId);
      if (latestMessages.isNotEmpty) {
        final latestMessage = latestMessages.last;
        final exists = messages.any((msg) => msg.id == latestMessage.id);
        if (!exists) {
          messages.add(latestMessage);
        }
      }
    } catch (e) {
    }
  }

  Future<void> sendMessage() async {
    if (isSending == true) return;
    isSending = true;
    notifyListeners();

    final currentRoomId = roomId;
    final messageText = messageController.text;
    final imagesToSend = List<XFile>.from(images);

    // MessageSendManager를 통해 메시지 전송
    final result = await _messageSendManager.sendMessage(
      roomId: currentRoomId,
      itemId: itemId,
      messageText: messageText,
      images: imagesToSend,
      messageType: type,
      onError: _handleSendError,
    );

    if (!result.success) {
      _handleSendError(result.errorMessage ?? "메시지 전송 실패");
      isSending = false;
      notifyListeners();
      return;
    }

    // 전송 성공 후 상태 업데이트
    if (result.isFirstMessage && result.roomId != null) {
      // 첫 메시지 전송 성공
      roomId = result.roomId;
      messageController.text = "";
      images.clear();
      type = MessageType.text;
      notifyListeners();
      await _handleFirstMessageSent();
      
      // 여러 이미지 전송 후 최신 메시지 새로고침
      if (imagesToSend.length > 1) {
        await _refreshLatestMessage(result.roomId!);
        scrollToBottom(force: true);
      }
    } else if (currentRoomId != null) {
      // 기존 채팅방에서 메시지 전송 성공
      messageController.text = "";
      images.clear();
      type = MessageType.text;
      setupRealtimeSubscription();
      await _refreshLatestMessage(currentRoomId);
      isSending = false;
      notifyListeners();
      scrollToBottom(force: true);
    } else {
      // 예상치 못한 경우
      isSending = false;
      notifyListeners();
    }
  }

  // Call when view appears
  Future<void> init() async {
    final thisRoomId = roomId;
    if (thisRoomId == null) return;

    // enterRoom을 호출하여 읽음 처리 초기화
    try {
      await chattingRoomService.enterRoom(thisRoomId);
    } catch (e) {
    }

    await getRoomNotificationSetting();
    heartbeatManager.start(thisRoomId);
    isActive = true;
    notifyListeners();
  }

  // Call when view disappears
  Future<void> disposeViewModel() async {
    final thisRoomId = roomId;
    if (thisRoomId != null && isActive) {
      // 채팅방을 나갈 때 읽음 처리
      // leaveRoom이 읽음 처리를 하므로 먼저 호출
      try {
        await chattingRoomService.leaveRoom(thisRoomId);
      } catch (e) {
      }
      heartbeatManager.stop();
      isActive = false;
    }
  }

  Future<void> leaveRoom() async {
    // disposeViewModel에서 leaveRoom이 호출되므로 여기서는 disposeViewModel만 호출
    // dispose는 자동으로 호출되므로 여기서 호출하지 않음
    if (isActive && roomId != null) {
      await disposeViewModel();
    }
  }

  Future<void> enterRoom() async {
    init();
    if (roomId != null) {
      setupRealtimeSubscription();
    }
    notifyListeners();
  }

  Future<void> getRoomNotificationSetting() async {
    final thisRoomId = roomId;
    if (thisRoomId == null) return;
    notificationSetting = await _getRoomNotificationSettingUseCase(thisRoomId);
    notifyListeners();
  }

  Future<void> notificationToggle() async {
    final thisRoomId = roomId;
    if (thisRoomId == null || notificationSetting == null) return;
    if (notificationSetting?.isNotificationOn == true) {
      await notificationOff();
    } else {
      await notificationOn();
    }
  }

  Future<void> notificationOff() async {
    final thisRoomId = roomId;
    if (thisRoomId == null || notificationSetting == null) return;
    notificationSetting?.isNotificationOn = false;
    notifyListeners();
    try {
      _turnOffNotificationUseCase(thisRoomId);
    } catch (e) {
      notificationSetting?.isNotificationOn = true;
      notifyListeners();
    }
  }

  Future<void> notificationOn() async {
    final thisRoomId = roomId;
    if (thisRoomId == null || notificationSetting == null) return;
    notificationSetting?.isNotificationOn = true;
    notifyListeners();
    try {
      _turnOnNotificationUseCase(thisRoomId);
    } catch (e) {
      notificationSetting?.isNotificationOn = false;
      notifyListeners();
    }
  }

  void setupRealtimeRoomInfoSubscription() {
    _subscriptionManager.subscribeToRoomInfo(
      itemId: itemId,
      roomId: roomId,
      onItemUpdate: (updateItemInfo) {
        itemInfo = updateItemInfo;
        notifyListeners();
      },
      onAuctionUpdate: (updateAuctionInfo) {
        auctionInfo = updateAuctionInfo;
        notifyListeners();
      },
      onTradeUpdate: (updateTradeInfo) {
        tradeInfo = updateTradeInfo;
        notifyListeners();
      },
      onUnreadCountUpdate: (newUnreadCount) {
        // unread_count를 기반으로 마지막으로 본 메시지까지 읽음 처리
        if (messages.isNotEmpty) {
          _markMessagesAsReadUpToLastViewed(newUnreadCount);
        }

        // 이전에 읽지 않은 메시지가 있었는데 지금 0이 되면 하단으로 스크롤
        // 단, 사용자가 수동으로 스크롤 중이 아닐 때만
        if (previousUnreadCount != null &&
            previousUnreadCount! > 0 &&
            newUnreadCount == 0 &&
            !isUserScrolling) {
          scrollToBottom(force: true);
        }
        previousUnreadCount = newUnreadCount;
      },
      onNotifyListeners: notifyListeners,
    );
  }

  void setupRealtimeSubscription() {
    final currentRoomId = roomId;
    if (currentRoomId == null) {
      return;
    }

    _subscriptionManager.subscribeToMessages(
      currentRoomId,
      (newChattingMessage) {
        messages.add(newChattingMessage);
        notifyListeners();

        // 본인이 보낸 메시지일 때만 하단으로 스크롤
        final userId = SupabaseManager.shared.supabase.auth.currentUser?.id;
        if (userId != null && newChattingMessage.senderId == userId) {
          scrollToBottom(force: true);
        }
      },
      notifyListeners,
    );
  }

  @override
  void dispose() {
    // 채팅방을 나갈 때 읽음 처리를 위해 disposeViewModel 호출
    if (roomId != null && isActive) {
      // disposeViewModel은 비동기이므로 await 없이 호출
      // dispose는 동기 메서드이므로 Future를 기다릴 수 없음
      disposeViewModel().catchError((e) {
      });
    }

    _roomInfoManager.dispose();
    _subscriptionManager.dispose();
    _scrollManager.dispose();
    super.dispose();
  }

  Future<void> pickImagesFromGallery() async {
    final result = await _imagePickerManager.pickImagesFromGallery();
    if (result == null) return;
    
    images.addAll(result.images);
    type = result.messageType;
    notifyListeners();
  }

  Future<void> pickImageFromCamera() async {
    final result = await _imagePickerManager.pickImageFromCamera();
    if (result == null) return;
    
    images.addAll(result.images);
    type = result.messageType;
    notifyListeners();
  }

  Future<void> pickVideoFromGallery() async {
    final result = await _imagePickerManager.pickVideoFromGallery();
    if (result == null) return;
    
    images.addAll(result.images);
    type = result.messageType;
    notifyListeners();
  }

  void clearImage(int index) {
    if (index >= 0 && index < images.length) {
      images.removeAt(index);
      if (images.isEmpty) {
        type = MessageType.text;
      }
      notifyListeners();
    }
  }

  void clearAllImages() {
    images.clear();
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
      final beforeCreatedAtIso = oldestMessage.createdAt;

      // 현재 스크롤 위치 저장
      double? previousScrollOffset;
      if (scrollController.hasClients) {
        previousScrollOffset = scrollController.offset;
      }

      final olderMessages = await _getOlderMessagesUseCase(
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

        // 스크롤 위치 유지 (새로 추가된 메시지 높이만큼 오프셋 조정)
        if (previousScrollOffset != null) {
          _scrollManager.maintainScrollPosition(
            previousScrollOffset!,
            olderMessages.length,
          );
        }
      }
    } catch (e) {
    }

    isLoadingMore = false;
    notifyListeners();
  }
}
