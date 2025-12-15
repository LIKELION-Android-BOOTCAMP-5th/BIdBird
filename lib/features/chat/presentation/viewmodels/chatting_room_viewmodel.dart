import 'dart:async';

import 'package:bidbird/core/managers/chatting_room_service.dart';
import 'package:bidbird/core/managers/cloudinary_manager.dart';
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
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChattingRoomViewmodel extends ChangeNotifier {
  String? roomId;
  String itemId;
  bool isActive = false;
  XFile? image;
  RoomInfoEntity? roomInfo;
  ItemInfoEntity? itemInfo;
  AuctionInfoEntity? auctionInfo;
  TradeInfoEntity? tradeInfo;
  bool _hasShippingInfo = false;
  bool get hasShippingInfo => _hasShippingInfo;
  double? imageAspectRatio; // width / height
  final ImagePicker _picker = ImagePicker();
  final TextEditingController messageController = TextEditingController();
  List<ChatMessageEntity> messages = [];
  MessageType type = MessageType.text;
  bool isSending = false;
  ScrollController scrollController = ScrollController();
  ChattingNotificationSetEntity? notificationSetting;
  ScrollPhysics? listViewPhysics; // ListView의 physics를 동적으로 제어
  bool isLoadingMore = false;
  bool hasMore = false;

  bool hasScrolledToUnread = false;
  bool isInitialLoad = true; // 초기 로드 여부
  bool isUserScrolling = false; // 사용자가 수동으로 스크롤 중인지 여부
  int? previousUnreadCount; // 이전 unreadCount 값을 저장
  Timer? _fetchRoomInfoDebounce; // fetchRoomInfo 디바운스용 타이머
  Timer? _userScrollingDebounce; // 사용자 스크롤 감지 디바운스
  bool _isScrollPositionSet = false; // 스크롤 위치가 설정되었는지 여부
  bool _shouldScrollToBottom = false; // 하단으로 스크롤해야 하는지 여부 (false면 상단)
  bool _isScrollPositionReady = false; // 스크롤 위치가 준비되어 화면을 표시해도 되는지 여부

  bool get isScrollPositionReady => _isScrollPositionReady;

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

  // 스크롤 위치 설정 및 화면 표시 (pre-render 단계)
  void _setScrollPositionAndShow() {
    if (!isInitialLoad || _isScrollPositionReady) {
      return;
    }

    if (!scrollController.hasClients) {
      print('[스크롤 위치 설정] scrollController.hasClients=false, 재시도');
      return;
    }

    if (messages.isEmpty) {
      print('[스크롤 위치 설정] messages.isEmpty, 재시도');
      return;
    }

    final maxScroll = scrollController.position.maxScrollExtent;

    // maxScrollExtent가 0이면 아직 레이아웃이 완료되지 않은 것
    if (maxScroll == 0) {
      print('[스크롤 위치 설정] maxScroll=0, 재시도');
      return;
    }

    // 스크롤 위치 계산 및 즉시 적용 (애니메이션 없이)
    if (_shouldScrollToBottom) {
      scrollController.jumpTo(maxScroll);
      print('[Pre-render 위치 설정] 하단으로 설정: maxScroll=$maxScroll');
    } else {
      scrollController.jumpTo(0);
      print('[Pre-render 위치 설정] 상단으로 설정');
    }

    // 스크롤 위치 설정 완료 후 즉시 physics를 ClampingScrollPhysics로 변경하고 화면 표시 허용
    listViewPhysics = const ClampingScrollPhysics();
    _isScrollPositionSet = true;
    _isScrollPositionReady = true; // 화면 표시 준비 완료
    isInitialLoad = false;
    notifyListeners();
    print('[Pre-render 위치 설정 완료] 화면 표시 준비 완료: maxScroll=$maxScroll');

    // 한 번 더 확인하여 확실하게 위치 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        final finalMaxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.position.pixels;

        if (_shouldScrollToBottom && currentScroll < finalMaxScroll - 1) {
          scrollController.jumpTo(finalMaxScroll);
        } else if (!_shouldScrollToBottom && currentScroll > 1) {
          scrollController.jumpTo(0);
        }
      }
    });
  }

  ChattingRoomViewmodel({required this.itemId, required this.roomId}) {
    // UseCases는 필드 초기화로 자동 초기화됨

    // roomInfo와 messages를 모두 로드
    fetchRoomInfo();
    fetchMessage();

    // 스크롤 컨트롤러가 처음 연결될 때 즉시 초기 위치 설정
    // 이 리스너는 ListView가 빌드되고 스크롤 컨트롤러가 연결될 때 즉시 실행됨
    scrollController.addListener(() {
      if (isInitialLoad &&
          !_isScrollPositionSet &&
          scrollController.hasClients &&
          messages.isNotEmpty) {
        final maxScroll = scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          if (_shouldScrollToBottom) {
            // 하단으로 즉시 이동 (애니메이션 없이)
            print('[스크롤 리스너] 하단으로 즉시 이동: maxScroll=$maxScroll');
            scrollController.jumpTo(maxScroll);
            _isScrollPositionSet = true;
            isInitialLoad = false;
            // 즉시 한 번 더 확인하여 확실하게 하단으로 이동
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                final newMaxScroll = scrollController.position.maxScrollExtent;
                final newCurrentScroll = scrollController.position.pixels;
                if (newCurrentScroll < newMaxScroll - 1) {
                  print(
                    '[스크롤 리스너] 하단으로 재이동: newMaxScroll=$newMaxScroll, newCurrentScroll=$newCurrentScroll',
                  );
                  scrollController.jumpTo(newMaxScroll);
                }
              }
            });
          } else {
            // 상단으로 즉시 이동 (애니메이션 없이)
            print('[스크롤 리스너] 상단으로 즉시 이동');
            scrollController.jumpTo(0);
            _isScrollPositionSet = true;
            isInitialLoad = false;
            // 즉시 한 번 더 확인하여 확실하게 상단으로 이동
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                final newCurrentScroll = scrollController.position.pixels;
                if (newCurrentScroll > 1) {
                  print(
                    '[스크롤 리스너] 상단으로 재이동: newCurrentScroll=$newCurrentScroll',
                  );
                  scrollController.jumpTo(0);
                }
              }
            });
          }
        }
      }
    });

    Timer? debounce;
    scrollController.addListener(() async {
      if (debounce?.isActive ?? false) debounce!.cancel();

      // 리스트 상단 근처에 도달했을 때 이전 메시지 로딩 (디바운스 적용)
      debounce = Timer(const Duration(milliseconds: 150), () {
        if (scrollController.offset <= 40) {
          loadMoreMessages();
        }
      });

      // 사용자가 수동으로 스크롤하는지 감지
      if (!isInitialLoad) {
        isUserScrolling = true;
        if (_userScrollingDebounce?.isActive ?? false) {
          _userScrollingDebounce!.cancel();
        }
        // 스크롤이 멈춘 후 1초 뒤에 플래그 해제 (사용자가 스크롤을 멈췄다고 간주)
        _userScrollingDebounce = Timer(const Duration(seconds: 1), () {
          isUserScrolling = false;
        });
      }
    });
  }

  RealtimeChannel? _subscribeMessageChannel;
  RealtimeChannel? _itemsChannel;
  RealtimeChannel? _auctionsChannel;
  RealtimeChannel? _tradeChannel;
  RealtimeChannel? _roomUsersChannel;

  Future<void> fetchRoomInfo() async {
    final currentRoomId = roomId;
    RoomInfoEntity? newRoomInfo;
    try {
      if (currentRoomId != null) {
        newRoomInfo = await _getRoomInfoWithRoomIdUseCase(currentRoomId);
      } else {
        newRoomInfo = await _getRoomInfoUseCase(itemId);
      }
    } catch (e) {
      print("방 정보 가져오기 실패: $e");
    }

    final newUnreadCount = newRoomInfo?.unreadCount ?? 0;

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
    roomInfo = newRoomInfo;
    itemInfo = roomInfo?.item;
    auctionInfo = roomInfo?.auction;
    tradeInfo = roomInfo?.trade;
    
    // 배송 정보 확인
    await _checkShippingInfo();
    
    setupRealtimeRoomInfoSubscription();
    notifyListeners();
  }

  /// 배송 정보 입력 여부 확인
  Future<void> _checkShippingInfo() async {
    try {
      final shippingInfoRepository = ShippingInfoRepository();
      final shippingInfo = await shippingInfoRepository.getShippingInfo(itemId);
      
      _hasShippingInfo = shippingInfo != null &&
          shippingInfo['tracking_number'] != null &&
          (shippingInfo['tracking_number'] as String?)?.isNotEmpty == true;
    } catch (e) {
      _hasShippingInfo = false;
    }
  }

  // 디바운스를 적용한 fetchRoomInfo 호출
  void fetchRoomInfoDebounced() {
    if (_fetchRoomInfoDebounce?.isActive ?? false) {
      _fetchRoomInfoDebounce!.cancel();
    }
    _fetchRoomInfoDebounce = Timer(const Duration(milliseconds: 500), () {
      fetchRoomInfo();
    });
  }

  // 하단으로 스크롤하는 메서드
  void scrollToBottom({bool force = false, bool instant = false}) {
    if (!scrollController.hasClients || messages.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.position.pixels;

        // 이미 하단 근처(50px 이내)에 있고 force가 false면 스크롤하지 않음
        if (!force && (maxScroll - currentScroll) <= 50) {
          return;
        }
        if (instant) {
          scrollController.jumpTo(maxScroll);
        } else {
          scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  // unread_count를 기반으로 마지막으로 본 메시지까지 읽음 처리
  void _markMessagesAsReadUpToLastViewed(int unreadCount) {
    if (messages.isEmpty) return;

    final userId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (userId == null) return;

    // unread_count가 0이면 모든 메시지가 읽음 처리됨
    if (unreadCount <= 0) {
      // 모든 메시지가 읽음 처리된 상태
      return;
    }

    // unread_count를 기반으로 마지막으로 본 메시지 인덱스 계산
    // unread_count가 N이면, 최신 메시지부터 N개가 읽지 않은 메시지
    // 따라서 messages.length - unreadCount 번째 메시지가 마지막으로 본 메시지
    final lastViewedIndex = messages.length - unreadCount;

    if (lastViewedIndex < 0 || lastViewedIndex >= messages.length) {
      // 인덱스가 유효하지 않으면 처리하지 않음
      return;
    }

    // 마지막으로 본 메시지의 시간 가져오기
    final lastViewedMessage = messages[lastViewedIndex];
    DateTime? lastViewedTime;
    try {
      lastViewedTime = DateTime.parse(lastViewedMessage.createdAt).toLocal();
    } catch (e) {
      // 날짜 파싱 오류 시 처리하지 않음
      return;
    }

    // 마지막으로 본 메시지 시간 이하의 모든 메시지를 읽음 처리
    // (본인이 보낸 메시지는 제외)
    for (int i = 0; i < messages.length; i++) {
      try {
        final messageTime = DateTime.parse(messages[i].createdAt).toLocal();
        // 마지막으로 본 메시지 시간 이하이고, 본인이 보낸 메시지가 아니면 읽음 처리
        if (!messageTime.isAfter(lastViewedTime) &&
            messages[i].senderId != userId) {
          // 여기서는 메시지 엔티티에 읽음 표시를 할 수 없으므로
          // roomInfo의 lastMessageAt을 업데이트하는 것으로 대체
          // 실제 읽음 처리는 서버에서 처리되므로 여기서는 로그만 남김
          print(
            '[읽음 처리] 메시지 ${messages[i].id} 읽음 처리 (마지막으로 본 메시지: ${lastViewedMessage.id})',
          );
        }
      } catch (e) {
        // 날짜 파싱 오류 무시
        continue;
      }
    }

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
    final userId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (userId == null || roomInfo == null || messages.isEmpty) return -1;

    // 읽지 않은 메시지가 없으면 -1 반환
    if (roomInfo!.unreadCount <= 0) return -1;

    // 마지막 메시지 시간 가져오기
    final lastMessageTime = roomInfo!.lastMessageAt;
    if (lastMessageTime == null) return -1;

    // 마지막 메시지 시간 이후의 첫 번째 메시지 찾기
    for (int i = 0; i < messages.length; i++) {
      try {
        final messageTime = DateTime.parse(messages[i].createdAt).toLocal();
        if (messageTime.isAfter(lastMessageTime)) {
          return i;
        }
      } catch (e) {
        // 날짜 파싱 오류 무시
        continue;
      }
    }

    return -1; // 읽지 않은 메시지를 찾을 수 없음
  }

  // 첫 번째 읽지 않은 메시지로 스크롤
  void scrollToFirstUnreadMessage(
    ScrollController scrollController,
    BuildContext? context, {
    bool instant = false,
  }) {
    if (hasScrolledToUnread || messages.isEmpty) return;

    final index = findFirstUnreadMessageIndex();
    if (index >= 0) {
      // 레이아웃이 완료된 후에 스크롤 수행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          // 메시지의 위치로 스크롤
          final position = index * 80.0; // 평균 메시지 높이로 추정
          if (instant) {
            scrollController.jumpTo(position);
          } else {
            scrollController.animateTo(
              position,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
          hasScrolledToUnread = true;
        }
      });
    } else {
      // 읽지 않은 메시지가 없으면 하단으로 스크롤
      scrollToBottom(force: true, instant: instant);
      hasScrolledToUnread = true;
    }
  }

  Future<void> fetchMessage() async {
    try {
      final currentRoomId = roomId;
      if (currentRoomId != null) {
        final chattings = await _getMessagesUseCase(currentRoomId);

        messages.clear(); // 기존 메시지 초기화
        messages.addAll(chattings);
        hasMore = chattings.length >= 50;
        hasScrolledToUnread = false; // 스크롤 플래그 초기화
        _isScrollPositionSet = false; // 스크롤 위치 설정 플래그 초기화

        // 초기 로드 시 항상 하단으로 위치
        if (isInitialLoad && messages.isNotEmpty) {
          // 읽지 않은 메시지가 있든 없든 항상 하단(최신 메시지)으로
          _shouldScrollToBottom = true;
          _isScrollPositionReady = false; // 초기 로드 시에는 스크롤 위치 설정 전까지 화면 숨김
        } else {
          _isScrollPositionReady = true; // 초기 로드가 아니면 즉시 화면 표시
        }

        // 초기 로드 시 스크롤 위치를 화면 표시 전에 미리 계산 및 설정
        if (isInitialLoad && messages.isNotEmpty) {
          // 1. ListView의 physics를 처음에 NeverScrollableScrollPhysics로 설정하여 스크롤 방지
          listViewPhysics = const NeverScrollableScrollPhysics();
          _isScrollPositionReady = false; // 아직 준비되지 않음
          notifyListeners();

          // 2. 첫 번째 프레임에서 즉시 스크롤 위치 계산 및 설정 (pre-render 단계)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _setScrollPositionAndShow();
          });

          // 추가로 여러 프레임에 걸쳐 시도
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isScrollPositionReady) {
              _setScrollPositionAndShow();
            }
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_isScrollPositionReady) {
              _setScrollPositionAndShow();
            }
          });

          // 약간의 지연 후에도 시도
          Future.delayed(const Duration(milliseconds: 10), () {
            if (!_isScrollPositionReady && isInitialLoad) {
              _setScrollPositionAndShow();
            }
          });

          Future.delayed(const Duration(milliseconds: 50), () {
            if (!_isScrollPositionReady && isInitialLoad) {
              _setScrollPositionAndShow();
            }
          });

          // 최대 200ms 후에는 강제로 화면 표시 (타임아웃)
          Future.delayed(const Duration(milliseconds: 200), () {
            if (!_isScrollPositionReady && isInitialLoad) {
              listViewPhysics = const ClampingScrollPhysics();
              _isScrollPositionSet = true;
              _isScrollPositionReady = true;
              isInitialLoad = false;
              notifyListeners();
            }
          });
        } else {
          _isScrollPositionReady = true;
          notifyListeners();
        }

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
      print('메시지 불러오기 실패: $e');
      notifyListeners();
    }
  }

  // 에러 처리 헬퍼 메서드
  void _handleSendError(String error, [Object? e]) {
    if (e != null) {
      print("$error: $e");
    } else {
      print(error);
    }
    isSending = false;
    notifyListeners();
  }

  // 이미지 업로드 헬퍼 메서드
  Future<String?> _uploadMedia(XFile file) async {
    try {
      if (isVideoFile(file.path)) {
        return await CloudinaryManager.shared.uploadVideoToCloudinary(file);
      } else {
        return await CloudinaryManager.shared.uploadImageToCloudinary(file);
      }
    } catch (e) {
      print('미디어 업로드 실패: $e');
      return null;
    }
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
      print("메시지 불러오기 실패: $e");
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
      print('최신 메시지 불러오기 실패: $e');
    }
  }

  Future<void> sendMessage() async {
    if (isSending == true) return;
    isSending = true;
    final currentRoomId = roomId;
    
    if (currentRoomId == null) {
      // 첫 메시지 전송
      if (type == MessageType.text) {
        if (messageController.text.isEmpty) {
          _handleSendError("메시지가 비어있습니다");
          return;
        }
        try {
          roomId = await _sendFirstMessageUseCase(
            itemId: itemId,
            messageType: type,
            message: messageController.text,
          );
          if (roomId == null) {
            _handleSendError("메세지 전송 실패: roomId가 null입니다");
            return;
          }
          messageController.text = "";
          notifyListeners();
          await _handleFirstMessageSent();
        } catch (e) {
          _handleSendError("메세지 전송 실패", e);
        }
      } else {
        // 이미지/비디오 메시지
        final thisImage = image;
        if (thisImage == null) {
          _handleSendError("이미지가 없습니다");
          return;
        }
        try {
          final mediaUrl = await _uploadMedia(thisImage);
          if (mediaUrl == null) {
            _handleSendError("미디어 업로드 실패");
            return;
          }
          roomId = await _sendFirstMessageUseCase(
            itemId: itemId,
            messageType: type,
            imageUrl: mediaUrl,
          );
          if (roomId == null) {
            _handleSendError("메세지 전송 실패: roomId가 null입니다");
            return;
          }
          image = null;
          type = MessageType.text;
          notifyListeners();
          await _handleFirstMessageSent();
        } catch (e) {
          _handleSendError("메세지 전송 실패", e);
        }
      }
    } else {
      // 기존 채팅방에서 메시지 전송
      // 실시간 구독이 설정되어 있지 않으면 설정
      if (_subscribeMessageChannel == null) {
        setupRealtimeSubscription();
      }
      
      if (type == MessageType.text) {
        if (messageController.text.isEmpty) {
          _handleSendError("메시지가 비어있습니다");
          return;
        }
        final messageText = messageController.text;
        try {
          await _sendTextMessageUseCase(currentRoomId, messageText);
          messageController.text = "";
          await _refreshLatestMessage(currentRoomId);
          isSending = false;
          notifyListeners();
          scrollToBottom(force: true);
        } catch (e) {
          _handleSendError('메세지 전송 실패', e);
        }
      } else {
        // 이미지/비디오 메시지
        final thisImage = image;
        if (thisImage == null) {
          _handleSendError("이미지가 없습니다");
          return;
        }
        try {
          final mediaUrl = await _uploadMedia(thisImage);
          if (mediaUrl == null) {
            _handleSendError("미디어 업로드 실패");
            return;
          }
          await _sendImageMessageUseCase(currentRoomId, mediaUrl);
          image = null;
          type = MessageType.text;
          await _refreshLatestMessage(currentRoomId);
          isSending = false;
          notifyListeners();
          scrollToBottom(force: true);
        } catch (e) {
          _handleSendError('메세지 전송 실패', e);
        }
      }
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
      print("enterRoom 실패: $e");
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
        print("disposeViewModel: leaveRoom 호출 시작, roomId=$thisRoomId");
        await chattingRoomService.leaveRoom(thisRoomId);
        print("disposeViewModel: leaveRoom 호출 완료");
      } catch (e) {
        print("leaveRoom 실패: $e");
      }
      heartbeatManager.stop();
      isActive = false;
    }
  }

  Future<void> leaveRoom() async {
    // disposeViewModel에서 leaveRoom이 호출되므로 여기서는 disposeViewModel만 호출
    // dispose는 자동으로 호출되므로 여기서 호출하지 않음
    if (isActive && roomId != null) {
      print("leaveRoom 호출: disposeViewModel 실행");
      await disposeViewModel();
    }
  }

  Future<void> enterRoom() async {
    init();
    if (roomId != null && _subscribeMessageChannel == null) {
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
    // 기존 채널 정리
    if (_roomUsersChannel != null) {
      SupabaseManager.shared.supabase.removeChannel(_roomUsersChannel!);
      _roomUsersChannel = null;
    }

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
            itemInfo = updateItemInfo;
            notifyListeners();
          },
        )
        .subscribe();

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
            auctionInfo = updateAuctionInfo;
            notifyListeners();
          },
        )
        .subscribe();
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
            final data = payload.newRecord;

            final userId = SupabaseManager.shared.supabase.auth.currentUser?.id;
            if (userId == null || data['buyer_id'] != userId) {
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

    // chatting_room_users 테이블의 unread_count 변경 감지
    final currentRoomId = roomId;
    final userId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentRoomId != null && userId != null && _roomUsersChannel == null) {
      _roomUsersChannel = SupabaseManager.shared.supabase.channel(
        'chatting_room_users$currentRoomId',
      );
      _roomUsersChannel!
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'chatting_room_users',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: currentRoomId,
            ),
            callback: (payload) {
              final data = payload.newRecord;

              // 현재 사용자의 unread_count만 확인
              if (data['user_id'] == userId) {
                final newUnreadCount = data['unread_count'] as int? ?? 0;

                // unread_count를 기반으로 마지막으로 본 메시지까지 읽음 처리
                _markMessagesAsReadUpToLastViewed(newUnreadCount);

                // 이전에 읽지 않은 메시지가 있었는데 지금 0이 되면 하단으로 스크롤
                // 단, 사용자가 수동으로 스크롤 중이 아닐 때만
                if (previousUnreadCount != null &&
                    previousUnreadCount! > 0 &&
                    newUnreadCount == 0 &&
                    !isUserScrolling) {
                  // 강제로 하단으로 스크롤
                  scrollToBottom(force: true);
                }
                // previousUnreadCount 업데이트
                previousUnreadCount = newUnreadCount;
                // roomInfo의 unreadCount도 업데이트 (디바운스 적용하여 무한 루프 방지)
                if (roomInfo != null) {
                  // roomInfo 객체 직접 업데이트 (fetchRoomInfo 호출하지 않음)
                  // fetchRoomInfoDebounced();
                }
              }
            },
          )
          .subscribe();
    }
  }

  void setupRealtimeSubscription() {
    final currentRoomId = roomId;
    if (currentRoomId == null) {
      return;
    }

    // 기존 채널 정리 (중복 구독 방지)
    if (_subscribeMessageChannel != null) {
      SupabaseManager.shared.supabase.removeChannel(_subscribeMessageChannel!);
      _subscribeMessageChannel = null;
    }

    _subscribeMessageChannel = SupabaseManager.shared.supabase.channel(
      'chatting_message$currentRoomId',
    );
    _subscribeMessageChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chatting_message',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: currentRoomId,
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;
            final ChatMessageEntity newChattingMessage =
                ChatMessageEntity.fromJson(newMessage);
            messages.add(newChattingMessage);
            notifyListeners();

            // 본인이 보낸 메시지일 때만 하단으로 스크롤
            final userId = SupabaseManager.shared.supabase.auth.currentUser?.id;
            if (userId != null && newChattingMessage.senderId == userId) {
              scrollToBottom(force: true);
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    // 채팅방을 나갈 때 읽음 처리를 위해 disposeViewModel 호출
    if (roomId != null && isActive) {
      // disposeViewModel은 비동기이므로 await 없이 호출
      // dispose는 동기 메서드이므로 Future를 기다릴 수 없음
      disposeViewModel().catchError((e) {
        print("disposeViewModel 실패: $e");
      });
    }

    _fetchRoomInfoDebounce?.cancel();
    _userScrollingDebounce?.cancel();
    if (_subscribeMessageChannel != null) {
      SupabaseManager.shared.supabase.removeChannel(_subscribeMessageChannel!);
    }
    if (_itemsChannel != null) {
      SupabaseManager.shared.supabase.removeChannel(_itemsChannel!);
    }
    if (_auctionsChannel != null) {
      SupabaseManager.shared.supabase.removeChannel(_auctionsChannel!);
    }
    if (_tradeChannel != null) {
      SupabaseManager.shared.supabase.removeChannel(_tradeChannel!);
    }
    if (_roomUsersChannel != null) {
      SupabaseManager.shared.supabase.removeChannel(_roomUsersChannel!);
    }
    // if (_bidLogChannel != null) _supabase.removeChannel(_bidLogChannel!);
    scrollController.dispose();
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

  Future<void> pickVideoFromGallery() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) {
      return;
    }
    // 동영상 파일 저장 (이미지와 동일한 방식으로 처리)
    image = video;
    imageAspectRatio = 16 / 9; // 기본 비율 설정
    type = MessageType.image; // 일단 image로 설정 (나중에 video 타입 추가 가능)
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
        if (previousScrollOffset != null && scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (scrollController.hasClients) {
              // 새로 추가된 메시지의 예상 높이 계산 (평균 메시지 높이 * 추가된 메시지 수)
              final estimatedNewHeight = olderMessages.length * 80.0;
              final newOffset = previousScrollOffset! + estimatedNewHeight;
              scrollController.jumpTo(newOffset);
            }
          });
        }
      }
    } catch (e) {
      print('이전 메시지 로딩 실패: $e');
    }

    isLoadingMore = false;
    notifyListeners();
  }
}
