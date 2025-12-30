import 'dart:async';

import 'package:bidbird/features/chat/domain/entities/auction_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/item_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/trade_info_entity.dart';
import 'package:bidbird/features/chat/data/repositories/chat_repository.dart';
import 'package:bidbird/features/chat/domain/usecases/fetch_room_info_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/fetch_room_info_with_room_id_usecase.dart';
import 'package:bidbird/features/item_trade/shipping/data/repositories/shipping_info_repository.dart';
import 'package:bidbird/features/item_trade/shipping/domain/usecases/get_shipping_info_usecase.dart';

/// RoomInfo 관리 결과
class RoomInfoResult {
  final RoomInfoEntity? roomInfo;
  final ItemInfoEntity? itemInfo;
  final AuctionInfoEntity? auctionInfo;
  final TradeInfoEntity? tradeInfo;
  final bool hasShippingInfo;
  final int unreadCount;

  RoomInfoResult({
    required this.roomInfo,
    required this.itemInfo,
    required this.auctionInfo,
    required this.tradeInfo,
    required this.hasShippingInfo,
    required this.unreadCount,
  });
}

/// RoomInfo 관리자
/// 채팅방 정보(RoomInfo)를 가져오고 관리하는 클래스
class RoomInfoManager {
  final FetchRoomInfoUseCase _fetchRoomInfoUseCase;
  final FetchRoomInfoWithRoomIdUseCase _fetchRoomInfoWithRoomIdUseCase;
  final GetShippingInfoUseCase _getShippingInfoUseCase;

  Timer? _debounceTimer;
  
  // RoomInfo 캐싱
  RoomInfoResult? _cachedRoomInfo;
  String? _cachedRoomId;
  String? _cachedItemId;
  DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(seconds: 30); // 30초 캐시

  RoomInfoManager({
    FetchRoomInfoUseCase? fetchRoomInfoUseCase,
    FetchRoomInfoWithRoomIdUseCase? fetchRoomInfoWithRoomIdUseCase,
    GetShippingInfoUseCase? getShippingInfoUseCase,
  })  : _fetchRoomInfoUseCase =
            fetchRoomInfoUseCase ?? FetchRoomInfoUseCase(ChatRepositoryImpl()),
        _fetchRoomInfoWithRoomIdUseCase = fetchRoomInfoWithRoomIdUseCase ??
            FetchRoomInfoWithRoomIdUseCase(ChatRepositoryImpl()),
        _getShippingInfoUseCase =
            getShippingInfoUseCase ?? GetShippingInfoUseCase(ShippingInfoRepositoryImpl());

  /// RoomInfo 가져오기
  /// [roomId] 채팅방 ID (null이면 itemId로 조회)
  /// [itemId] 상품 ID
  /// [forceRefresh] 강제 새로고침 여부
  Future<RoomInfoResult> fetchRoomInfo({
    String? roomId,
    required String itemId,
    bool forceRefresh = false,
  }) async {
    // 캐시 검증
    if (!forceRefresh &&
        _cachedRoomInfo != null &&
        _cachedRoomId == roomId &&
        _cachedItemId == itemId &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration) {
      return _cachedRoomInfo!;
    }
    
    RoomInfoEntity? newRoomInfo;
    try {
      if (roomId != null) {
        newRoomInfo = await _fetchRoomInfoWithRoomIdUseCase(roomId);
      } else {
        newRoomInfo = await _fetchRoomInfoUseCase(itemId);
      }
    } catch (e) {
      // 에러 발생 시 캐시된 데이터 반환
      if (_cachedRoomInfo != null && _cachedRoomId == roomId && _cachedItemId == itemId) {
        return _cachedRoomInfo!;
      }
      // 캐시도 없으면 빈 결과 반환
      return RoomInfoResult(
        roomInfo: null,
        itemInfo: null,
        auctionInfo: null,
        tradeInfo: null,
        hasShippingInfo: false,
        unreadCount: 0,
      );
    }

    final newUnreadCount = newRoomInfo?.unreadCount ?? 0;
    final itemInfo = newRoomInfo?.item;
    final auctionInfo = newRoomInfo?.auction;
    final tradeInfo = newRoomInfo?.trade;

    // 배송 정보 확인 (캐시된 경우 재확인 생략)
    bool hasShippingInfo = false;
    if (!forceRefresh && 
        _cachedRoomInfo != null && 
        _cachedItemId == itemId) {
      // 캐시에서 배송 정보 재사용
      hasShippingInfo = _cachedRoomInfo!.hasShippingInfo;
    } else {
      hasShippingInfo = await _checkShippingInfo(itemId);
    }

    final result = RoomInfoResult(
      roomInfo: newRoomInfo,
      itemInfo: itemInfo,
      auctionInfo: auctionInfo,
      tradeInfo: tradeInfo,
      hasShippingInfo: hasShippingInfo,
      unreadCount: newUnreadCount,
    );
    
    // 캐시 업데이트
    _cachedRoomInfo = result;
    _cachedRoomId = roomId;
    _cachedItemId = itemId;
    _lastFetchTime = DateTime.now();
    
    return result;
  }
  
  /// RoomInfo 캐시 무효화
  void invalidateCache() {
    // _cachedRoomInfo = null;
    // _cachedRoomId = null;
    // _cachedItemId = null;
    // _lastFetchTime = null;
  }

  /// 배송 정보 입력 여부 확인
  Future<bool> _checkShippingInfo(String itemId) async {
    try {
      final shippingInfo = await _getShippingInfoUseCase(itemId);
      
      return shippingInfo != null &&
          shippingInfo['tracking_number'] != null &&
          (shippingInfo['tracking_number'] as String?)?.isNotEmpty == true;
    } catch (e) {
      return false;
    }
  }

  /// 디바운스를 적용한 fetchRoomInfo 호출
  /// [callback] 디바운스 후 실행할 콜백
  /// [forceRefresh] 강제 새로고침 여부
  void fetchRoomInfoDebounced({
    required String? roomId,
    required String itemId,
    required Future<void> Function(RoomInfoResult) callback,
    bool forceRefresh = false,
  }) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final result = await fetchRoomInfo(roomId: roomId, itemId: itemId, forceRefresh: forceRefresh);
      await callback(result);
    });
  }

  /// 디바운스 타이머 정리
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}



