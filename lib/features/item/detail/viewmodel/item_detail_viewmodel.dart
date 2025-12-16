import 'package:bidbird/core/viewmodels/item_base_viewmodel.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repository/item_detail_repository.dart';

class ItemDetailViewModel extends ItemBaseViewModel {
  final String itemId;
  final ItemDetailRepository _repository;

  ItemDetailViewModel({required this.itemId, ItemDetailRepository? repository})
    : _repository = repository ?? ItemDetailRepositoryImpl() {
    // 초기 로딩 상태 설정
    setLoading(true);
  }

  ItemDetail? _itemDetail;
  ItemDetail? get itemDetail => _itemDetail;

  bool _isFavorite = false;
  bool get isFavorite => _isFavorite;

  bool _isTopBidder = false;
  bool get isTopBidder => _isTopBidder;

  bool _isMyItem = false;
  bool get isMyItem => _isMyItem;

  Map<String, dynamic>? _sellerProfile;
  Map<String, dynamic>? get sellerProfile => _sellerProfile;

  List<Map<String, dynamic>> _bidHistory = [];
  List<Map<String, dynamic>> get bidHistory => _bidHistory;

  RealtimeChannel? _bidStatusChannel;
  bool _isLoadingDetail = false;
  
  // 캐싱 관련
  static const Duration _cacheValidDuration = Duration(minutes: 3);

  Future<void> loadItemDetail({bool forceRefresh = false}) async {
    // 중복 로딩 방지
    if (_isLoadingDetail) return;
    
    // 캐시가 유효하고 강제 새로고침이 아니면 캐시 사용
    if (!forceRefresh && 
        isCacheValid(_cacheValidDuration) &&
        _itemDetail != null) {
      // 캐시된 데이터가 있지만, 추가 데이터는 항상 최신 상태로 업데이트
      await _loadAdditionalData();
      // 모든 추가 데이터 로드 완료 후 한 번만 notifyListeners 호출
      notifyListeners();
      return; // 캐시된 메인 데이터 사용, 추가 데이터만 업데이트
    }
    
    _isLoadingDetail = true;
    startLoading();

    try {
      _itemDetail = await _repository.fetchItemDetail(itemId);

      if (_itemDetail == null) {
        stopLoadingWithError('상품을 찾을 수 없습니다.');
        return;
      }

      stopLoading();

      // 추가 데이터 로딩 - 부분 실패 허용
      await _loadAdditionalData();
      
      // 모든 추가 데이터 로드 완료 후 한 번만 notifyListeners 호출
      notifyListeners();
      
      updateCacheTime();
    } catch (e) {
      stopLoadingWithError(e.toString());
      // 에러 발생 시에도 캐시된 데이터는 유지
    } finally {
      _isLoadingDetail = false;
    }
  }

  /// 추가 데이터를 한 번에 로드하는 헬퍼 메서드
  /// 개별 메서드에서는 notifyListeners를 호출하지 않음
  Future<void> _loadAdditionalData() async {
    await Future.wait([
      _checkIsMyItem(),
      _loadFavoriteState(),
      _checkTopBidder(),
      _loadSellerProfile(),
      _loadBidHistory(),
    ], eagerError: false);
  }

  Future<void> _loadFavoriteState() async {
    try {
      _isFavorite = await _repository.checkIsFavorite(itemId);
      // notifyListeners() 제거 - 상위에서 배치 호출
    } catch (e) {
      // 즐겨찾기 상태 로드 실패 시 기본값 유지
    }
  }

  Future<void> _checkTopBidder() async {
    try {
      _isTopBidder = await _repository.checkIsTopBidder(itemId);
      // notifyListeners() 제거 - 상위에서 배치 호출
    } catch (e) {
      // 최고 입찰자 확인 실패 시 기본값 유지
    }
  }

  Future<void> _checkIsMyItem() async {
    if (_itemDetail != null) {
      try {
        _isMyItem = await _repository.checkIsMyItem(itemId, _itemDetail!.sellerId);
        // notifyListeners() 제거 - 상위에서 배치 호출
      } catch (e) {
        // 내 아이템 확인 실패 시 기본값 유지
      }
    }
  }

  Future<void> _loadSellerProfile() async {
    if (_itemDetail?.sellerId != null) {
      try {
        _sellerProfile = await _repository.fetchSellerProfile(
          _itemDetail!.sellerId,
        );
        // notifyListeners() 제거 - 상위에서 배치 호출
      } catch (e) {
        // 판매자 프로필 로드 실패 시 null 유지
      }
    }
  }

  Future<void> _loadBidHistory() async {
    try {
      _bidHistory = await _repository.fetchBidHistory(itemId);
      // notifyListeners() 제거 - 상위에서 배치 호출
    } catch (e) {
      // 입찰 내역 로드 실패 시 빈 리스트 유지
    }
  }

  Future<void> toggleFavorite() async {
    try {
      await _repository.toggleFavorite(itemId, _isFavorite);
      _isFavorite = !_isFavorite;
      notifyListeners();
    } catch (e) {
      // toggle favorite 실패 시 조용히 처리
    }
  }

  void setupRealtimeSubscription() {
    // 이미 구독 중이면 무시
    if (_bidStatusChannel != null) return;
    
    // auctions: 현재가, 최고 입찰자, 상태 코드 변경 감지
    _bidStatusChannel = _repository.supabase.channel('auctions_$itemId');
    _bidStatusChannel!
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
            _handleRealtimeUpdate(payload);
          },
        )
        .subscribe();
  }

  /// 실시간 업데이트를 선택적으로 처리
  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    final newRecord = payload.newRecord;
    
    if (newRecord == null || _itemDetail == null) return;
    
    bool needsFullRefresh = false;
    bool hasPartialUpdate = false;
    
    // 현재가 변경 시 부분 업데이트
    if (newRecord.containsKey('current_price')) {
      final newPrice = newRecord['current_price'] as int?;
      if (newPrice != null) {
        // bidPrice도 함께 계산
        final newBidPrice = _calculateBidStep(newPrice);
        _itemDetail = _itemDetail!.copyWith(
          currentPrice: newPrice,
          bidPrice: newBidPrice,
        );
        hasPartialUpdate = true;
      }
    }
    
    // 입찰 횟수 변경 시 부분 업데이트
    if (newRecord.containsKey('bid_count')) {
      final newCount = newRecord['bid_count'] as int?;
      if (newCount != null) {
        _itemDetail = _itemDetail!.copyWith(
          biddingCount: newCount,
        );
        hasPartialUpdate = true;
      }
    }
    
    // 상태 코드 변경 시 전체 새로고침 필요
    if (newRecord.containsKey('auction_status_code') ||
        newRecord.containsKey('trade_status_code')) {
      needsFullRefresh = true;
    }
    
    // 종료 시간 변경 시 전체 새로고침 필요
    if (newRecord.containsKey('finish_time')) {
      needsFullRefresh = true;
    }
    
    if (needsFullRefresh) {
      // 중요한 변경은 전체 새로고침
      super.invalidateCache();
      loadItemDetail(forceRefresh: true);
    } else if (hasPartialUpdate) {
      // 부분 업데이트만 적용
      notifyListeners();
    }
  }

  /// 입찰 단위 계산
  int _calculateBidStep(int currentPrice) {
    return ItemPriceHelper.calculateBidStep(currentPrice);
  }

  @override
  void dispose() {
    if (_bidStatusChannel != null) {
      _repository.supabase.removeChannel(_bidStatusChannel!);
    }
    super.dispose();
  }
}
