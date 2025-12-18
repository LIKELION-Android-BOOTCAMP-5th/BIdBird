import 'dart:async';

import 'package:bidbird/core/managers/chatting_room_service.dart';
import 'package:bidbird/core/managers/heartbeat_manager.dart';
import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/data/repositories/chat_repository.dart';
import 'package:bidbird/features/chat/domain/entities/auction_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_notification_set_entity.dart';
import 'package:bidbird/features/chat/domain/entities/item_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/trade_info_entity.dart';
import 'package:bidbird/features/chat/domain/usecases/get_messages_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/get_room_id_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/get_older_messages_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/has_submitted_review_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/complete_trade_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/cancel_trade_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/submit_trade_review_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/get_room_notification_setting_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/notification_off_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/notification_on_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/message_type.dart';
import 'package:bidbird/features/chat/presentation/managers/image_picker_manager.dart';
import 'package:bidbird/features/chat/presentation/managers/message_send_manager.dart';
import 'package:bidbird/features/chat/presentation/managers/read_status_manager.dart';
import 'package:bidbird/features/chat/data/managers/realtime_subscription_manager.dart';
import 'package:bidbird/features/chat/presentation/managers/room_info_manager.dart';
import 'package:bidbird/features/chat/presentation/managers/scroll_manager.dart';
import 'package:bidbird/features/chat/presentation/viewmodels/chat_list_viewmodel.dart';
import 'package:bidbird/core/utils/item/trade_status_codes.dart';
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
  bool _hasSubmittedReview = false;
  bool get hasSubmittedReview => _hasSubmittedReview;
  final TextEditingController messageController = TextEditingController();
  List<ChatMessageEntity> messages = [];
  MessageType type = MessageType.text;
  bool isSending = false;
  ChattingNotificationSetEntity? notificationSetting;
  bool isLoadingMore = false;
  bool hasMore = false;

  int? previousUnreadCount; // 이전 unreadCount 값을 저장
  bool _isFetchingRoomInfo = false; // fetchRoomInfo 호출 중인지 확인하는 플래그
  bool _isInitialMessageLoad = true; // 초기 메시지 로드 여부

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
  /// 경매가 종료되고 낙찰된 경우에만 true 반환
  bool get isTopBidder {
    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null || auctionInfo == null) return false;
    
    // 경매가 종료되고 낙찰된 경우에만 낙찰자로 인정
    // auction_status_code가 bidWon이고, 내가 최고 입찰자인 경우
    final isAuctionWon = auctionInfo!.auctionStatusCode == AuctionStatusCode.bidWon;
    final isLastBidder = auctionInfo!.lastBidUserId == currentUserId;
    
    return isAuctionWon && isLastBidder;
  }

  /// 낙찰자가 존재하는지 확인 (경매 종료 후 낙찰된 경우)
  bool get hasTopBidder {
    if (auctionInfo == null) return false;
    
    // 경매가 종료되고 낙찰된 경우에만 true
    final isAuctionWon = auctionInfo!.auctionStatusCode == AuctionStatusCode.bidWon;
    final hasLastBidder = auctionInfo!.lastBidUserId != null && 
                          auctionInfo!.lastBidUserId!.isNotEmpty;
    
    return isAuctionWon && hasLastBidder;
  }

  final GetMessagesUseCase _getMessagesUseCase;
  final GetRoomIdUseCase _getRoomIdUseCase;
  final GetOlderMessagesUseCase _getOlderMessagesUseCase;
  final HasSubmittedReviewUseCase _hasSubmittedReviewUseCase;
  final CompleteTradeUseCase _completeTradeUseCase;
  final CancelTradeUseCase _cancelTradeUseCase;
  final SubmitTradeReviewUseCase _submitTradeReviewUseCase;
  final GetRoomNotificationSettingUseCase _getRoomNotificationSettingUseCase;
  final NotificationOffUseCase _notificationOffUseCase;
  final NotificationOnUseCase _notificationOnUseCase;

  ChattingRoomViewmodel({
    required this.itemId,
    required this.roomId,
    GetMessagesUseCase? getMessagesUseCase,
    GetRoomIdUseCase? getRoomIdUseCase,
    GetOlderMessagesUseCase? getOlderMessagesUseCase,
    HasSubmittedReviewUseCase? hasSubmittedReviewUseCase,
    CompleteTradeUseCase? completeTradeUseCase,
    CancelTradeUseCase? cancelTradeUseCase,
    SubmitTradeReviewUseCase? submitTradeReviewUseCase,
    GetRoomNotificationSettingUseCase? getRoomNotificationSettingUseCase,
    NotificationOffUseCase? notificationOffUseCase,
    NotificationOnUseCase? notificationOnUseCase,
    ScrollManager? scrollManager,
    RealtimeSubscriptionManager? subscriptionManager,
    ReadStatusManager? readStatusManager,
    MessageSendManager? messageSendManager,
    RoomInfoManager? roomInfoManager,
    ImagePickerManager? imagePickerManager,
  })  : _getMessagesUseCase =
            getMessagesUseCase ?? GetMessagesUseCase(ChatRepositoryImpl()),
        _getRoomIdUseCase = getRoomIdUseCase ?? GetRoomIdUseCase(ChatRepositoryImpl()),
        _getOlderMessagesUseCase =
            getOlderMessagesUseCase ?? GetOlderMessagesUseCase(ChatRepositoryImpl()),
        _hasSubmittedReviewUseCase =
            hasSubmittedReviewUseCase ?? HasSubmittedReviewUseCase(ChatRepositoryImpl()),
        _completeTradeUseCase =
            completeTradeUseCase ?? CompleteTradeUseCase(ChatRepositoryImpl()),
        _cancelTradeUseCase = cancelTradeUseCase ?? CancelTradeUseCase(ChatRepositoryImpl()),
        _submitTradeReviewUseCase =
            submitTradeReviewUseCase ?? SubmitTradeReviewUseCase(ChatRepositoryImpl()),
        _getRoomNotificationSettingUseCase = getRoomNotificationSettingUseCase ??
            GetRoomNotificationSettingUseCase(ChatRepositoryImpl()),
        _notificationOffUseCase =
            notificationOffUseCase ?? NotificationOffUseCase(ChatRepositoryImpl()),
        _notificationOnUseCase =
            notificationOnUseCase ?? NotificationOnUseCase(ChatRepositoryImpl()) {
    // Manager 클래스 초기화
    _scrollManager = scrollManager ?? ScrollManager(ScrollController());
    _subscriptionManager = subscriptionManager ?? RealtimeSubscriptionManager();
    _readStatusManager = readStatusManager ?? ReadStatusManager();
    _messageSendManager = messageSendManager ?? MessageSendManager();
    _roomInfoManager = roomInfoManager ?? RoomInfoManager();
    _imagePickerManager = imagePickerManager ?? ImagePickerManager();

    // 더 많은 메시지 로드 리스너 설정
    _scrollManager.setupLoadMoreListener(() {
      loadMoreMessages();
    });

    // roomInfo와 messages를 모두 로드
    fetchRoomInfo();
    fetchMessage();
  }


  Future<void> fetchRoomInfo({bool forceRefresh = false}) async {
    // 중복 호출 방지
    if (_isFetchingRoomInfo) {
      return;
    }
    _isFetchingRoomInfo = true;
    
    try {
      final result = await _roomInfoManager.fetchRoomInfo(
        roomId: roomId,
        itemId: itemId,
        forceRefresh: forceRefresh,
      );

      final newUnreadCount = result.unreadCount;

      // unread_count를 기반으로 마지막으로 본 메시지까지 읽음 처리
      // fetchRoomInfo 호출 중이므로 fetchRoomInfoDebounced를 호출하지 않도록 플래그 전달
      if (messages.isNotEmpty) {
        _markMessagesAsReadUpToLastViewed(newUnreadCount, skipFetchRoomInfo: true);
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
      
      // 평가 작성 여부 확인
      if (itemId.isNotEmpty) {
        _hasSubmittedReview = await _hasSubmittedReviewUseCase(itemId);
      }
      
      setupRealtimeRoomInfoSubscription();
      notifyListeners();
    } catch (e) {
      // 에러 발생 시 조용히 처리
    } finally {
      _isFetchingRoomInfo = false;
    }
  }

  // 디바운스를 적용한 fetchRoomInfo 호출
  void fetchRoomInfoDebounced() {
    // 중복 호출 방지
    if (_isFetchingRoomInfo) {
      return;
    }
    _roomInfoManager.fetchRoomInfoDebounced(
      roomId: roomId,
      itemId: itemId,
      callback: (result) async {
        _isFetchingRoomInfo = true;
        try {
          final newUnreadCount = result.unreadCount;

          // unread_count를 기반으로 마지막으로 본 메시지까지 읽음 처리
          // fetchRoomInfoDebounced 호출 중이므로 fetchRoomInfoDebounced를 호출하지 않도록 플래그 전달
          if (messages.isNotEmpty) {
            _markMessagesAsReadUpToLastViewed(newUnreadCount, skipFetchRoomInfo: true);
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
          
          // 평가 작성 여부 확인
          if (itemId.isNotEmpty) {
            _hasSubmittedReview = await _hasSubmittedReviewUseCase(itemId);
          }
          
          setupRealtimeRoomInfoSubscription();
          notifyListeners();
        } catch (e) {
          // 에러 발생 시 조용히 처리
        } finally {
          _isFetchingRoomInfo = false;
        }
      },
    );
  }

  // 하단으로 스크롤하는 메서드
  void scrollToBottom({bool force = false, bool instant = false}) {
    if (messages.isEmpty) return;
    // 더 많은 메시지를 로드 중일 때는 자동 스크롤하지 않음
    if (isLoadingMore && !force) return;
    _scrollManager.scrollToBottom(force: force, instant: instant);
  }

  // unread_count를 기반으로 마지막으로 본 메시지까지 읽음 처리
  void _markMessagesAsReadUpToLastViewed(int unreadCount, {bool skipFetchRoomInfo = false}) {
    _readStatusManager.markMessagesAsReadUpToLastViewed(
      messages,
      unreadCount,
      onMarkAsRead: (message) {
        // 읽음 처리 로그 (필요시)
        // 실제 읽음 처리는 서버에서 처리되므로 여기서는 로그만 남김
      },
    );

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
        // 초기 로드인지 확인 (clear 전에 확인)
        final isInitialLoad = _isInitialMessageLoad && messages.isEmpty;
        
        // 현재 스크롤 위치 저장 (초기 로드가 아닐 때)
        double? savedScrollOffset;
        if (!isInitialLoad && scrollController.hasClients) {
          savedScrollOffset = scrollController.offset;
        }
        
        // 초기 로드일 때는 항상 최신 메시지를 가져오기 위해 forceRefresh: true 전달
        final chattings = await _getMessagesUseCase(currentRoomId, forceRefresh: isInitialLoad);

        messages.clear(); // 기존 메시지 초기화
        messages.addAll(chattings);
        hasMore = chattings.length >= 20;

        // 초기 로드일 때만 하단으로 스크롤, 이후에는 스크롤 위치 유지
        if (isInitialLoad) {
          _scrollManager.initializeScrollPosition(
            shouldScrollToBottom: true,
            messagesCount: messages.length,
          );
          _isInitialMessageLoad = false;
        } else {
          // 초기 로드가 아닐 때는 스크롤 위치 초기화하지 않고, 저장된 위치로 복원
          _scrollManager.resetInitialLoad();
          if (savedScrollOffset != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                final maxScroll = scrollController.position.maxScrollExtent;
                final targetOffset = savedScrollOffset! > maxScroll ? maxScroll : savedScrollOffset!;
                scrollController.jumpTo(targetOffset);
              }
            });
          }
        }
        
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
    } catch (e) {
      notifyListeners();
    }
  }

  // 에러 처리 헬퍼 메서드
  void _handleSendError(String error, [Object? e]) {
    isSending = false;
    notifyListeners();
  }

  /// 채팅방 목록에 방 업데이트 알림 (메시지 전송 시)
  /// 실시간 구독이 chatting_room 테이블 변경을 감지하여 자동으로 reloadList()를 호출하므로
  /// 여기서는 즉시 방을 최상단으로 이동만 qq
  void _notifyChatListRoomUpdate(String roomId) {
    ChatListViewmodel.instance?.moveRoomToTop(roomId);
  }


  // 첫 메시지 전송 후 처리 헬퍼 메서드
  Future<void> _handleFirstMessageSent() async {
    try {
      // fetchMessage를 호출하여 메시지 리스트를 다시 불러오기
      // fetchMessage 내부에서 setupRealtimeSubscription()과 init()을 호출하므로 여기서는 호출하지 않음
      await fetchMessage();
      
      // fetchMessage 내부에서 이미 setupRealtimeSubscription()과 init()을 호출하지만,
      // roomInfo는 별도로 업데이트 필요 (강제 새로고침)
      await fetchRoomInfo(forceRefresh: true);
      
      isSending = false;
      notifyListeners();
      scrollToBottom(force: true);
    } catch (e) {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage() async {
    if (isSending == true) return;
    isSending = true;
    notifyListeners();

    final currentRoomId = roomId;
    final messageText = messageController.text;
    final imagesToSend = List<XFile>.from(images);

    // 낙관적 업데이트: 메시지 전송 전에 임시 메시지 추가
    final userId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentRoomId != null && userId != null) {
      _addOptimisticMessage(
        roomId: currentRoomId,
        senderId: userId,
        messageText: messageText,
        images: imagesToSend,
        messageType: type,
      );
    }

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
      // 전송 실패 시 임시 메시지 제거
      _removeOptimisticMessages(messageText, imagesToSend);
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
      
      // 채팅방 목록에서 해당 방을 최상단으로 이동
      _notifyChatListRoomUpdate(result.roomId!);
    } else if (currentRoomId != null) {
      // 기존 채팅방에서 메시지 전송 성공
      // Realtime subscription이 실제 메시지를 추가하면 임시 메시지가 자동으로 교체됨
      messageController.text = "";
      images.clear();
      type = MessageType.text;
      isSending = false;
      notifyListeners();
      scrollToBottom(force: true);
      
      // 채팅방 목록에서 해당 방을 최상단으로 이동
      _notifyChatListRoomUpdate(currentRoomId);
    } else {
      // 예상치 못한 경우
      isSending = false;
      notifyListeners();
    }
  }

  /// 낙관적 업데이트: 임시 메시지를 추가
  void _addOptimisticMessage({
    required String roomId,
    required String senderId,
    required String messageText,
    required List<XFile> images,
    required MessageType messageType,
  }) {
    final now = DateTime.now().toUtc().toIso8601String();
    
    if (messageText.trim().isNotEmpty) {
      // 텍스트 메시지 추가
      final tempMessage = ChatMessageEntity(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}_text',
        roomId: roomId,
        senderId: senderId,
        messageType: 'text',
        text: messageText,
        imageUrl: null,
        thumbnailUrl: null,
        createdAt: now,
      );
      messages.add(tempMessage);
      notifyListeners();
    }

    // 이미지 메시지 추가
    for (final image in images) {
      final isVideo = image.path.toLowerCase().endsWith('.mp4') ||
          image.path.toLowerCase().endsWith('.mov') ||
          image.path.toLowerCase().endsWith('.avi');
      
      final tempMessage = ChatMessageEntity(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}_${image.path}',
        roomId: roomId,
        senderId: senderId,
        messageType: isVideo ? 'video' : 'image',
        text: null,
        imageUrl: image.path, // 임시로 로컬 경로 사용
        thumbnailUrl: null,
        createdAt: now,
      );
      messages.add(tempMessage);
    }
    
    if (images.isNotEmpty || messageText.trim().isNotEmpty) {
      notifyListeners();
      scrollToBottom(force: true);
    }
  }

  /// 전송 실패 시 임시 메시지 제거
  void _removeOptimisticMessages(String messageText, List<XFile> images) {
    messages.removeWhere((msg) => msg.id.startsWith('temp_'));
    notifyListeners();
  }

  // Call when view appears
  Future<void> init() async {
    final thisRoomId = roomId;
    if (thisRoomId == null) return;

    // enterRoom을 호출하여 읽음 처리 초기화
    try {
      await chattingRoomService.enterRoom(thisRoomId);
    } catch (e) {
      // 에러 발생 시 무시 (읽음 처리 실패해도 계속 진행)
    }

    await getRoomNotificationSetting();
    heartbeatManager.start(thisRoomId);
    isActive = true;
    notifyListeners();
  }

  // Call when view disappears
  Future<void> disposeViewModel() async {
    final thisRoomId = roomId;
    // 중복 호출 방지: 이미 비활성화되었으면 처리하지 않음
    if (thisRoomId == null || !isActive) {
      return;
    }
    
    // 낙관적 업데이트: 채팅방을 나갈 때 로컬에서 먼저 읽음 처리
    // unreadCount를 0으로 설정하여 UI를 즉시 업데이트
    if (roomInfo != null && roomInfo!.unreadCount > 0) {
      // 낙관적으로 읽음 처리
      roomInfo = RoomInfoEntity(
        item: roomInfo!.item,
        auction: roomInfo!.auction,
        opponent: roomInfo!.opponent,
        trade: roomInfo!.trade,
        unreadCount: 0,
        lastMessageAt: roomInfo!.lastMessageAt,
      );
      previousUnreadCount = 0;
      notifyListeners();
    }
    
    // 먼저 isActive를 false로 설정하여 실시간 구독 업데이트가 무시되도록 함
    heartbeatManager.stop();
    isActive = false;
    
    // 서버에 leaveRoom API 호출
    try {
      await chattingRoomService.leaveRoom(thisRoomId);
    } catch (e) {
      // 에러 발생 시 무시 (읽음 처리 실패해도 계속 진행)
    }
  }

  Future<void> leaveRoom() async {
    // disposeViewModel에서 낙관적 업데이트로 읽음 처리를 하고, 서버 통신은 백그라운드로 처리
    if (isActive && roomId != null) {
      await disposeViewModel();
    }
  }

  Future<void> enterRoom() async {
    // 이미 활성화되어 있으면 중복 호출 방지
    if (isActive) {
      return;
    }
    
    await init();
    if (roomId != null) {
      setupRealtimeSubscription();
    }
    notifyListeners();
  }

  /// 거래 완료 처리
  Future<void> completeTrade() async {
    if (itemId.isEmpty) {
      throw Exception('매물 ID가 없습니다.');
    }
    
    await _completeTradeUseCase(itemId);
    
    // 거래 완료 후 룸 정보 새로고침 (강제 새로고침)
    await fetchRoomInfo(forceRefresh: true);
  }

  /// 거래 취소 처리
  Future<void> cancelTrade(String reasonCode, bool isSellerFault) async {
    if (itemId.isEmpty) {
      throw Exception('매물 ID가 없습니다.');
    }
    
    await _cancelTradeUseCase(itemId, reasonCode, isSellerFault);
    
    // 거래 취소 후 룸 정보 새로고침
    await fetchRoomInfo();
  }

  /// 거래 평가 작성 처리
  Future<void> submitTradeReview(double rating, String comment) async {
    if (itemId.isEmpty) {
      throw Exception('매물 ID가 없습니다.');
    }

    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 현재 사용자가 판매자인지 구매자인지 확인
    final isSeller = itemInfo != null && itemInfo!.sellerId == currentUserId;
    final role = isSeller ? 'seller' : 'buyer';

    // 상대방 사용자 ID 확인
    String? toUserId;
    if (isSeller) {
      // 판매자인 경우, 구매자(낙찰자) ID
      toUserId = auctionInfo?.lastBidUserId;
    } else {
      // 구매자인 경우, 판매자 ID
      toUserId = itemInfo?.sellerId;
    }

    if (toUserId == null || toUserId.isEmpty) {
      throw Exception('상대방 정보를 찾을 수 없습니다.');
    }

    await _submitTradeReviewUseCase(
      itemId: itemId,
      toUserId: toUserId,
      role: role,
      rating: rating,
      comment: comment,
    );

    // 평가 작성 완료 후 상태 업데이트
    _hasSubmittedReview = true;
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
      await _notificationOffUseCase(thisRoomId);
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
      await _notificationOnUseCase(thisRoomId);
    } catch (e) {
      notificationSetting?.isNotificationOn = false;
      notifyListeners();
    }
  }

  void setupRealtimeRoomInfoSubscription() {
    _subscriptionManager.subscribeToRoomInfo(
      itemId: itemId,
      roomId: roomId,
      // 가격과 매물 관리는 리얼타임으로 가져오지 않음
      onItemUpdate: null,
      onAuctionUpdate: null,
      onTradeUpdate: null,
      onUnreadCountUpdate: (newUnreadCount) {
        // 채팅방이 비활성화된 상태에서는 실시간 업데이트 무시
        // (낙관적 업데이트로 이미 처리되었을 수 있음)
        if (!isActive) {
          return;
        }
        
        // 중복 호출 방지: 같은 값이면 처리하지 않음
        if (previousUnreadCount == newUnreadCount) {
          return;
        }
        
        // unread_count를 기반으로 마지막으로 본 메시지까지 읽음 처리
        // 실시간 구독에서 호출되므로 fetchRoomInfoDebounced를 호출하지 않도록 플래그 전달
        if (messages.isNotEmpty) {
          _markMessagesAsReadUpToLastViewed(newUnreadCount, skipFetchRoomInfo: true);
        }

        // 이전에 읽지 않은 메시지가 있었는데 지금 0이 되면 하단으로 스크롤
        // 단, 사용자가 수동으로 스크롤 중이 아니고, 더 많은 메시지를 로드 중이 아닐 때만
        if (previousUnreadCount != null &&
            previousUnreadCount! > 0 &&
            newUnreadCount == 0 &&
            !isUserScrolling &&
            !isLoadingMore) {
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
        // 이미 존재하는 메시지인지 확인 (중복 방지)
        final existingMessageIndex = messages.indexWhere((msg) => msg.id == newChattingMessage.id);
        if (existingMessageIndex != -1) {
          // 이미 존재하는 메시지면 업데이트만 하고 리턴
          messages[existingMessageIndex] = newChattingMessage;
          notifyListeners();
          return;
        }

        // 임시 메시지가 있으면 제거하고 실제 메시지로 교체
        final userId = SupabaseManager.shared.supabase.auth.currentUser?.id;
        final isMyMessage = userId != null && newChattingMessage.senderId == userId;
        
        if (isMyMessage) {
          // 본인이 보낸 메시지인 경우, 임시 메시지와 매칭하여 교체
          _replaceOptimisticMessage(newChattingMessage);
        } else {
          // 다른 사람이 보낸 메시지는 추가
          messages.add(newChattingMessage);
        }
        
        notifyListeners();

        // 새 메시지가 오면 하단으로 스크롤 (더 많은 메시지를 로드 중이 아닐 때만)
        if (!isLoadingMore) {
          scrollToBottom(force: true);
        }
      },
      notifyListeners,
    );
  }

  /// 임시 메시지를 실제 메시지로 교체
  void _replaceOptimisticMessage(ChatMessageEntity realMessage) {
    // 같은 내용의 임시 메시지를 찾아서 교체
    bool foundMatch = false;
    
    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      
      // 임시 메시지인지 확인
      if (msg.id.startsWith('temp_')) {
        // 텍스트 메시지 매칭
        if (realMessage.messageType == 'text' && 
            msg.messageType == 'text' && 
            msg.text == realMessage.text) {
          messages[i] = realMessage;
          foundMatch = true;
          break;
        }
        
        // 이미지/비디오 메시지 매칭 (내용이 같고 최근 5초 이내)
        if ((realMessage.messageType == 'image' || realMessage.messageType == 'video') &&
            (msg.messageType == 'image' || msg.messageType == 'video')) {
          // 임시 메시지가 있고 같은 타입이면 교체
          // 첫 번째 매칭되는 임시 메시지를 교체
          if (!foundMatch) {
            messages[i] = realMessage;
            foundMatch = true;
            break;
          }
        }
      }
    }
    
    // 매칭되는 임시 메시지가 없으면 그냥 추가
    if (!foundMatch) {
      messages.add(realMessage);
    }
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
    if (currentRoomId == null) {
      return;
    }

    // notifyListeners() 호출 전에 스크롤 위치 저장 (리빌드 전 위치)
    double? previousScrollOffset;
    double? previousMaxScrollExtent;
    if (scrollController.hasClients) {
      previousScrollOffset = scrollController.offset;
      previousMaxScrollExtent = scrollController.position.maxScrollExtent;
    }

    isLoadingMore = true;
    notifyListeners();

    try {
      final oldestMessage = messages.first;
      final beforeCreatedAtIso = oldestMessage.createdAt;

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
        // previousOffset이 0.0이거나 매우 작으면 사용자가 맨 위에 있었던 것이므로 조정하지 않음
        if (previousScrollOffset != null && 
            previousMaxScrollExtent != null && 
            previousScrollOffset > 10.0) {
          _scrollManager.maintainScrollPosition(
            previousScrollOffset!,
            previousMaxScrollExtent!,
            olderMessages.length,
          );
        }
      }
    } catch (e) {
      // 에러 발생 시 조용히 처리
    }

    isLoadingMore = false;
    notifyListeners();
  }
}
