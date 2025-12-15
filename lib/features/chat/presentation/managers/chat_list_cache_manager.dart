import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/domain/entities/chatting_room_entity.dart';

/// 채팅 리스트 캐시 관리자
/// sellerId, topBidder 등의 캐싱 로직을 관리하는 클래스
class ChatListCacheManager {
  final _supabase = SupabaseManager.shared.supabase;

  // itemId -> sellerId 매핑 캐시
  final Map<String, String> _sellerIdCache = {};
  
  // itemId -> isTopBidder 매핑 캐시 (내가 낙찰자인지 여부)
  final Map<String, bool> _topBidderCache = {};
  
  // itemId -> lastBidUserId 매핑 캐시 (낙찰자 ID 저장)
  final Map<String, String?> _lastBidUserIdCache = {};

  /// 모든 채팅방의 itemId에 대한 seller_id를 한 번에 가져와서 캐시에 저장
  Future<void> loadSellerIds(List<ChattingRoomEntity> chattingRoomList) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // 중복 제거된 itemId 목록
      final itemIds = chattingRoomList.map((room) => room.itemId).toSet().toList();
      if (itemIds.isEmpty) return;

      // 캐시에 없는 itemId만 조회
      final uncachedItemIds = itemIds
          .where((itemId) => !_sellerIdCache.containsKey(itemId))
          .toList();
      if (uncachedItemIds.isEmpty) return;

      final response = await _supabase
          .from('items_detail')
          .select('item_id, seller_id')
          .inFilter('item_id', uncachedItemIds);

      if (response is List) {
        for (final row in response) {
          final itemId = row['item_id'] as String?;
          final sellerId = row['seller_id'] as String?;
          if (itemId != null && sellerId != null) {
            _sellerIdCache[itemId] = sellerId;
          }
        }
      }
    } catch (e) {}
  }

  /// 모든 채팅방의 itemId에 대한 낙찰자 여부를 한 번에 가져와서 캐시에 저장
  Future<void> loadTopBidders(List<ChattingRoomEntity> chattingRoomList) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // 중복 제거된 itemId 목록
      final itemIds = chattingRoomList.map((room) => room.itemId).toSet().toList();
      if (itemIds.isEmpty) return;

      // 캐시에 없는 itemId만 조회
      final uncachedItemIds = itemIds
          .where((itemId) => !_topBidderCache.containsKey(itemId))
          .toList();
      if (uncachedItemIds.isEmpty) return;

      final response = await _supabase
          .from('auctions')
          .select('item_id, last_bid_user_id')
          .inFilter('item_id', uncachedItemIds)
          .eq('round', 1);

      if (response is List) {
        for (final row in response) {
          final itemId = row['item_id'] as String?;
          final lastBidUserId = row['last_bid_user_id'] as String?;
          if (itemId != null) {
            // last_bid_user_id 저장
            _lastBidUserIdCache[itemId] = lastBidUserId;
            // 내가 낙찰자인지 확인
            _topBidderCache[itemId] =
                lastBidUserId != null && lastBidUserId == currentUserId;
          }
        }
      }
    } catch (e) {}
  }

  /// 특정 itemId에 대해 현재 사용자가 판매자인지 확인
  bool isSeller(String itemId) {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final sellerId = _sellerIdCache[itemId];
    return sellerId == currentUserId;
  }

  /// 특정 itemId에 대해 현재 사용자가 낙찰자인지 확인
  bool isTopBidder(String itemId) {
    return _topBidderCache[itemId] ?? false;
  }

  /// 특정 itemId에 대해 상대방(구매자)이 낙찰자인지 확인
  /// 내가 판매자인 경우에만 사용
  bool isOpponentTopBidder(String itemId) {
    // 내가 판매자가 아니면 false
    if (!isSeller(itemId)) {
      return false;
    }

    // 내가 판매자인 경우, 상대방(구매자)이 낙찰자인지 확인
    // last_bid_user_id가 존재하고, 내가 아니면 상대방이 낙찰자
    final lastBidUserId = _lastBidUserIdCache[itemId];
    if (lastBidUserId == null) return false; // 낙찰자가 없으면 false

    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return false;

    // 낙찰자가 존재하고 내가 낙찰자가 아니면 상대방이 낙찰자
    return lastBidUserId != currentUserId;
  }

  /// 캐시 초기화
  void clear() {
    _sellerIdCache.clear();
    _topBidderCache.clear();
    _lastBidUserIdCache.clear();
  }
}

