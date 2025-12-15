import 'dart:async';

import 'package:bidbird/features/chat/domain/entities/auction_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/item_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/room_info_entity.dart';
import 'package:bidbird/features/chat/domain/entities/trade_info_entity.dart';
import 'package:bidbird/features/chat/domain/usecases/get_room_info_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/get_room_info_with_room_id_usecase.dart';
import 'package:bidbird/features/item/shipping/data/repository/shipping_info_repository.dart';

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
  final GetRoomInfoUseCase _getRoomInfoUseCase;
  final GetRoomInfoWithRoomIdUseCase _getRoomInfoWithRoomIdUseCase;
  final ShippingInfoRepository _shippingInfoRepository;

  Timer? _debounceTimer;

  RoomInfoManager({
    required GetRoomInfoUseCase getRoomInfoUseCase,
    required GetRoomInfoWithRoomIdUseCase getRoomInfoWithRoomIdUseCase,
    ShippingInfoRepository? shippingInfoRepository,
  })  : _getRoomInfoUseCase = getRoomInfoUseCase,
        _getRoomInfoWithRoomIdUseCase = getRoomInfoWithRoomIdUseCase,
        _shippingInfoRepository = shippingInfoRepository ?? ShippingInfoRepository();

  /// RoomInfo 가져오기
  /// [roomId] 채팅방 ID (null이면 itemId로 조회)
  /// [itemId] 상품 ID
  Future<RoomInfoResult> fetchRoomInfo({
    String? roomId,
    required String itemId,
  }) async {
    RoomInfoEntity? newRoomInfo;
    try {
      if (roomId != null) {
        newRoomInfo = await _getRoomInfoWithRoomIdUseCase(roomId);
      } else {
        newRoomInfo = await _getRoomInfoUseCase(itemId);
      }
    } catch (e) {
      // 에러 발생 시 null 반환
    }

    final newUnreadCount = newRoomInfo?.unreadCount ?? 0;
    final itemInfo = newRoomInfo?.item;
    final auctionInfo = newRoomInfo?.auction;
    final tradeInfo = newRoomInfo?.trade;

    // 배송 정보 확인
    final hasShippingInfo = await _checkShippingInfo(itemId);

    return RoomInfoResult(
      roomInfo: newRoomInfo,
      itemInfo: itemInfo,
      auctionInfo: auctionInfo,
      tradeInfo: tradeInfo,
      hasShippingInfo: hasShippingInfo,
      unreadCount: newUnreadCount,
    );
  }

  /// 배송 정보 입력 여부 확인
  Future<bool> _checkShippingInfo(String itemId) async {
    try {
      final shippingInfo = await _shippingInfoRepository.getShippingInfo(itemId);
      
      return shippingInfo != null &&
          shippingInfo['tracking_number'] != null &&
          (shippingInfo['tracking_number'] as String?)?.isNotEmpty == true;
    } catch (e) {
      return false;
    }
  }

  /// 디바운스를 적용한 fetchRoomInfo 호출
  /// [callback] 디바운스 후 실행할 콜백
  void fetchRoomInfoDebounced({
    required String? roomId,
    required String itemId,
    required Future<void> Function(RoomInfoResult) callback,
  }) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final result = await fetchRoomInfo(roomId: roomId, itemId: itemId);
      await callback(result);
    });
  }

  /// 디바운스 타이머 정리
  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}



