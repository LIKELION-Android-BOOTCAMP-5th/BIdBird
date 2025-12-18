import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 아이템 디테일 실시간 구독 관리자
/// 경매 상태 변경(현재가, 입찰 횟수, 최고 입찰자, 상태 코드 등)을 실시간으로 감지
/// Data Layer: Supabase와 직접 통신하는 데이터 소스 역할
class ItemDetailRealtimeManager {
  final _supabase = SupabaseManager.shared.supabase;

  RealtimeChannel? _auctionChannel;
  String? _currentItemId; // 현재 구독 중인 itemId 추적

  /// 구독 중인지 확인
  bool get isSubscribed => _auctionChannel != null && _currentItemId != null;

  /// 현재 구독 중인 itemId 확인
  String? get currentItemId => _currentItemId;

  /// 경매 상태 구독 설정
  /// 
  /// [itemId] 아이템 ID
  /// [onPriceUpdate] 현재가 변경 시 콜백 (newPrice, newBidPrice)
  /// [onBidCountUpdate] 입찰 횟수 변경 시 콜백
  /// [onTopBidderUpdate] 최고 입찰자 변경 시 콜백 (isTopBidder)
  /// [onStatusUpdate] 상태 코드 변경 시 콜백 (전체 새로고침 필요)
  /// [onFinishTimeUpdate] 종료 시간 변경 시 콜백 (전체 새로고침 필요)
  /// [onNotifyListeners] UI 업데이트 콜백
  void subscribeToAuctionStatus({
    required String itemId,
    void Function(int newPrice, int newBidPrice)? onPriceUpdate,
    void Function(int newCount)? onBidCountUpdate,
    void Function(bool isTopBidder)? onTopBidderUpdate,
    void Function()? onStatusUpdate,
    void Function()? onFinishTimeUpdate,
    required void Function() onNotifyListeners,
  }) {
    // 같은 itemId로 이미 구독 중이면 재구독하지 않음
    if (_currentItemId == itemId && _auctionChannel != null) {
      return;
    }

    // 기존 채널 정리 (중복 구독 방지)
    if (_auctionChannel != null) {
      _supabase.removeChannel(_auctionChannel!);
      _auctionChannel = null;
    }
    
    _currentItemId = itemId;

    _auctionChannel = _supabase.channel('auctions_$itemId');
    _auctionChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'auctions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'item_id',
            value: itemId,
          ),
          callback: (payload) {
            _handleRealtimeUpdate(
              payload,
              onPriceUpdate: onPriceUpdate,
              onBidCountUpdate: onBidCountUpdate,
              onTopBidderUpdate: onTopBidderUpdate,
              onStatusUpdate: onStatusUpdate,
              onFinishTimeUpdate: onFinishTimeUpdate,
              onNotifyListeners: onNotifyListeners,
            );
          },
        )
        .subscribe();
  }

  /// 실시간 업데이트 처리
  void _handleRealtimeUpdate(
    PostgresChangePayload payload, {
    void Function(int newPrice, int newBidPrice)? onPriceUpdate,
    void Function(int newCount)? onBidCountUpdate,
    void Function(bool isTopBidder)? onTopBidderUpdate,
    void Function()? onStatusUpdate,
    void Function()? onFinishTimeUpdate,
    required void Function() onNotifyListeners,
  }) {
    final newRecord = payload.newRecord;
    if (newRecord.isEmpty) return;

    // 현재가 변경 시 부분 업데이트
    if (newRecord.containsKey('current_price') && onPriceUpdate != null) {
      final newPrice = newRecord['current_price'] as int?;
      if (newPrice != null) {
        final newBidPrice = ItemPriceHelper.calculateBidStep(newPrice);
        onPriceUpdate(newPrice, newBidPrice);
      }
    }

    // 입찰 횟수 변경 시 부분 업데이트
    if (newRecord.containsKey('bid_count') && onBidCountUpdate != null) {
      final newCount = newRecord['bid_count'] as int?;
      if (newCount != null) {
        onBidCountUpdate(newCount);
      }
    }

    // 최고 입찰자 변경 시 isTopBidder 업데이트
    if (newRecord.containsKey('last_bid_user_id') && onTopBidderUpdate != null) {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        final lastBidUserId = newRecord['last_bid_user_id'] as String?;
        final isTopBidder = lastBidUserId != null && lastBidUserId == currentUserId;
        onTopBidderUpdate(isTopBidder);
      }
    }

    // 상태 코드 변경 시 전체 새로고침 필요
    if (newRecord.containsKey('auction_status_code') ||
        newRecord.containsKey('trade_status_code')) {
      onStatusUpdate?.call();
    }

    // 종료 시간 변경 시 전체 새로고침 필요
    if (newRecord.containsKey('finish_time')) {
      onFinishTimeUpdate?.call();
    }
  }

  /// 경매 상태 구독 해제
  void unsubscribeFromAuctionStatus() {
    if (_auctionChannel != null) {
      _supabase.removeChannel(_auctionChannel!);
      _auctionChannel = null;
    }
    _currentItemId = null;
  }

  /// 모든 구독 해제
  void dispose() {
    unsubscribeFromAuctionStatus();
  }
}

