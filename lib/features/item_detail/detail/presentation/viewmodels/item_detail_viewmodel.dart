import 'dart:async';
import 'package:bidbird/core/viewmodels/item_base_viewmodel.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bidbird/features/item_detail/detail/domain/repositories/item_detail_repository.dart'
    as domain;
import 'package:bidbird/features/item_detail/detail/data/repositories/item_detail_repository.dart'
    as data;
import 'package:bidbird/features/item_detail/detail/data/managers/item_detail_realtime_manager.dart';
import 'package:bidbird/features/item_detail/detail/domain/usecases/fetch_item_detail_usecase.dart';
import 'package:bidbird/features/item_detail/detail/domain/usecases/check_is_favorite_usecase.dart';
import 'package:bidbird/features/item_detail/detail/domain/usecases/toggle_favorite_usecase.dart';
import 'package:bidbird/features/item_detail/detail/domain/usecases/fetch_seller_profile_usecase.dart';
import 'package:bidbird/features/item_detail/detail/domain/usecases/fetch_bid_history_usecase.dart';
import 'package:bidbird/features/item_detail/detail/domain/usecases/check_is_my_item_usecase.dart';
import 'package:bidbird/features/item_detail/detail/domain/usecases/orchestrations/item_detail_flow_usecase.dart';

// BidHistoryItem은 item_detail_entity.dart에 정의되어 있음

class ItemDetailViewModel extends ItemBaseViewModel {
  final String itemId;
  final FetchItemDetailUseCase _fetchItemDetailUseCase;
  final CheckIsFavoriteUseCase _checkIsFavoriteUseCase;
  final ToggleFavoriteUseCase _toggleFavoriteUseCase;
  final FetchSellerProfileUseCase _fetchSellerProfileUseCase;
  final FetchBidHistoryUseCase _fetchBidHistoryUseCase;
  final CheckIsMyItemUseCase _checkIsMyItemUseCase;
  final domain.ItemDetailRepository
  _repository; // getLastIsTopBidder와 supabase getter용
  late final ItemDetailFlowUseCase _flowUseCase;

  ItemDetailViewModel({
    required this.itemId,
    FetchItemDetailUseCase? fetchItemDetailUseCase,
    CheckIsFavoriteUseCase? checkIsFavoriteUseCase,
    ToggleFavoriteUseCase? toggleFavoriteUseCase,
    FetchSellerProfileUseCase? fetchSellerProfileUseCase,
    FetchBidHistoryUseCase? fetchBidHistoryUseCase,
    CheckIsMyItemUseCase? checkIsMyItemUseCase,
    domain.ItemDetailRepository? repository,
  }) : _fetchItemDetailUseCase =
           fetchItemDetailUseCase ??
           FetchItemDetailUseCase(data.ItemDetailRepositoryImpl()),
       _checkIsFavoriteUseCase =
           checkIsFavoriteUseCase ??
           CheckIsFavoriteUseCase(data.ItemDetailRepositoryImpl()),
       _toggleFavoriteUseCase =
           toggleFavoriteUseCase ??
           ToggleFavoriteUseCase(data.ItemDetailRepositoryImpl()),
       _fetchSellerProfileUseCase =
           fetchSellerProfileUseCase ??
           FetchSellerProfileUseCase(data.ItemDetailRepositoryImpl()),
       _fetchBidHistoryUseCase =
           fetchBidHistoryUseCase ??
           FetchBidHistoryUseCase(data.ItemDetailRepositoryImpl()),
       _checkIsMyItemUseCase =
           checkIsMyItemUseCase ??
           CheckIsMyItemUseCase(data.ItemDetailRepositoryImpl()),
       _repository = repository ?? data.ItemDetailRepositoryImpl() {
    // 초기 로딩 상태 설정
    setLoading(true);
    _flowUseCase = ItemDetailFlowUseCase(
      fetchItemDetailUseCase: _fetchItemDetailUseCase,
      checkIsFavoriteUseCase: _checkIsFavoriteUseCase,
      fetchSellerProfileUseCase: _fetchSellerProfileUseCase,
      checkIsMyItemUseCase: _checkIsMyItemUseCase,
      repository: _repository,
    );
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

  List<BidHistoryItem> _bidHistory = [];
  List<BidHistoryItem> get bidHistory => _bidHistory;
  
  // 입찰 히스토리 캐시
  DateTime? _bidHistoryCacheTime;
  static const Duration _bidHistoryCacheDuration = Duration(minutes: 1);
  
  bool _isBidHistoryCacheValid() {
    if (_bidHistoryCacheTime == null) return false;
    return DateTime.now().difference(_bidHistoryCacheTime!) < _bidHistoryCacheDuration;
  }

  final ItemDetailRealtimeManager _realtimeManager =
      ItemDetailRealtimeManager();
  bool _isLoadingDetail = false;
  bool _isRefreshingFromRealtime = false; // 리얼타임 업데이트로 인한 새로고침 중인지 추적
  Timer? _statusUpdateDebounceTimer; // 상태 업데이트 디바운싱용 타이머

  // 낙찰 성공 화면 표시 여부 추적
  bool _hasShownBidWinScreen = false;
  bool _hasLoadedBidWinScreenFlag = false;
  bool get hasShownBidWinScreen => _hasShownBidWinScreen;

  static String _getBidWinScreenKey(String itemId) =>
      'bid_win_screen_shown_$itemId';

  Future<void> _loadBidWinScreenFlag() async {
    if (_hasLoadedBidWinScreenFlag) return;
    _hasLoadedBidWinScreenFlag = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasShownBidWinScreen =
          prefs.getBool(_getBidWinScreenKey(itemId)) ?? false;
    } catch (e) {
      _hasShownBidWinScreen = false;
    }
  }

  Future<void> markBidWinScreenAsShown() async {
    _hasShownBidWinScreen = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_getBidWinScreenKey(itemId), true);
    } catch (e) {
      // 저장 실패 시 무시
    }
    notifyListeners();
  }

  Future<void> resetBidWinScreenFlag() async {
    _hasShownBidWinScreen = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getBidWinScreenKey(itemId));
    } catch (e) {
      // 삭제 실패 시 무시
    }
    notifyListeners();
  }

  // 캐싱 관련
  static const Duration _cacheValidDuration = Duration(minutes: 3);
  static const Duration _additionalDataCacheValidDuration = Duration(
    minutes: 5,
  );

  // 추가 데이터 캐싱
  DateTime? _lastFavoriteCheckTime;
  DateTime? _lastMyItemCheckTime;
  DateTime? _lastSellerProfileLoadTime;
  String? _cachedSellerId; // 판매자 프로필 캐시 키

  Future<void> loadItemDetail({bool forceRefresh = false}) async {
    if (_isLoadingDetail) return;
    await _loadBidWinScreenFlag();

    // 캐시 사용 조건 유지
    if (!forceRefresh &&
        isCacheValid(_cacheValidDuration) &&
        _itemDetail != null) {
      await _loadAdditionalData(forceRefresh: false);
      notifyListeners();
      setupRealtimeSubscription();
      return;
    }

    _isLoadingDetail = true;
    startLoading();
    final previousStatusCode = _itemDetail?.statusCode;

    final (result, error) = await _flowUseCase.loadInitial(itemId);
    if (error != null) {
      stopLoadingWithError(error.message);
      _isLoadingDetail = false;
      _isRefreshingFromRealtime = false;
      return;
    }

    final r = result!;
    _itemDetail = r.item;
    _isFavorite = r.isFavorite;
    _isMyItem = r.isMyItem;
    _sellerProfile = r.sellerProfile;
    _isTopBidder = r.isTopBidder;

    if (previousStatusCode != null &&
        previousStatusCode != _itemDetail!.statusCode) {
      await resetBidWinScreenFlag();
    }

    stopLoading();
    notifyListeners();
    updateCacheTime();
    setupRealtimeSubscription();

    _isLoadingDetail = false;
    _isRefreshingFromRealtime = false;
  }

  /// 추가 데이터를 한 번에 로드하는 헬퍼 메서드
  /// 개별 메서드에서는 notifyListeners를 호출하지 않음
  /// 캐시가 유효하면 API 호출을 건너뜀
  Future<void> _loadAdditionalData({bool forceRefresh = false}) async {
    await Future.wait([
      _checkIsMyItem(forceRefresh: forceRefresh),
      _loadFavoriteState(forceRefresh: forceRefresh),
      // _checkTopBidder() 제거 - 엣지 펑션에서 이미 반환함
      _loadSellerProfile(forceRefresh: forceRefresh),
      // 입찰 내역은 바텀 시트가 열릴 때만 로드
    ], eagerError: false);
  }

  Future<void> _loadFavoriteState({bool forceRefresh = false}) async {
    // 캐시 검증
    if (!forceRefresh &&
        _lastFavoriteCheckTime != null &&
        DateTime.now().difference(_lastFavoriteCheckTime!) <
            _additionalDataCacheValidDuration) {
      return; // 캐시 사용
    }

    try {
      _isFavorite = await _checkIsFavoriteUseCase(itemId);
      _lastFavoriteCheckTime = DateTime.now();
      // notifyListeners() 제거 - 상위에서 배치 호출
    } catch (e) {
      // 즐겨찾기 상태 로드 실패 시 기본값 유지
    }
  }

  Future<void> _checkIsMyItem({bool forceRefresh = false}) async {
    if (_itemDetail != null) {
      // 캐시 검증
      if (!forceRefresh &&
          _lastMyItemCheckTime != null &&
          DateTime.now().difference(_lastMyItemCheckTime!) <
              _additionalDataCacheValidDuration) {
        return; // 캐시 사용
      }

      try {
        _isMyItem = await _checkIsMyItemUseCase(itemId, _itemDetail!.sellerId);
        _lastMyItemCheckTime = DateTime.now();
        // notifyListeners() 제거 - 상위에서 배치 호출
      } catch (e) {
        // 내 아이템 확인 실패 시 기본값 유지
      }
    }
  }

  Future<void> _loadSellerProfile({bool forceRefresh = false}) async {
    if (_itemDetail?.sellerId != null) {
      final sellerId = _itemDetail!.sellerId;

      // 캐시 검증: 같은 판매자이고 캐시가 유효하면 재호출 안 함
      if (!forceRefresh &&
          _cachedSellerId == sellerId &&
          _lastSellerProfileLoadTime != null &&
          DateTime.now().difference(_lastSellerProfileLoadTime!) <
              _additionalDataCacheValidDuration) {
        return; // 캐시 사용
      }

      try {
        _sellerProfile = await _fetchSellerProfileUseCase(sellerId);
        _lastSellerProfileLoadTime = DateTime.now();
        _cachedSellerId = sellerId;
        // notifyListeners() 제거 - 상위에서 배치 호출
      } catch (e) {
        // 판매자 프로필 로드 실패 시 null 유지
      }
    }
  }

  bool _isLoadingBidHistory = false;

  /// 입찰 내역을 로드합니다. 바텀 시트가 열릴 때 호출됩니다.
  Future<void> loadBidHistory() async {
    // 중복 호출 방지
    if (_isLoadingBidHistory) return;
    
    // 캐시가 유효하면 재로드하지 않음
    if (_isBidHistoryCacheValid()) return;
    
    // 이미 로드된 데이터가 있으면 재로드하지 않음
    if (_bidHistory.isNotEmpty && _isBidHistoryCacheValid()) return;

    _isLoadingBidHistory = true;
    try {
      _bidHistory = await _fetchBidHistoryUseCase(itemId);
      _bidHistoryCacheTime = DateTime.now(); // 캐시 시간 업데이트
      notifyListeners();
    } catch (e) {
      // 입찰 내역 로드 실패 시 빈 리스트 유지
      _bidHistory = [];
      notifyListeners();
    } finally {
      _isLoadingBidHistory = false;
    }
  }

  Future<void> toggleFavorite() async {
    try {
      await _toggleFavoriteUseCase(itemId, _isFavorite);
      _isFavorite = !_isFavorite;
      _lastFavoriteCheckTime = DateTime.now(); // 캐시 업데이트
      notifyListeners();
    } catch (e) {
      // toggle favorite 실패 시 조용히 처리
    }
  }

  void setupRealtimeSubscription() {
    if (_itemDetail == null) return;

    // 이미 같은 itemId로 구독 중이면 재구독하지 않음 (트래픽 최적화)
    if (_realtimeManager.isSubscribed &&
        _realtimeManager.currentItemId == itemId) {
      return;
    }

    _realtimeManager.subscribeToAuctionStatus(
      itemId: itemId,
      onPriceUpdate: (newPrice, newBidPrice) {
        if (_itemDetail == null) return;
        _itemDetail = _itemDetail!.copyWith(
          currentPrice: newPrice,
          bidPrice: newBidPrice,
        );
        // 가격이 올라갔을 때, 입찰 성공 직후일 수 있으므로
        // 실시간 업데이트에서 last_bid_user_id를 확인하여 isTopBidder 업데이트
        // (onTopBidderUpdate가 별도로 호출되지만, 타이밍 이슈를 방지하기 위해)
        notifyListeners();
      },
      onBidCountUpdate: (newCount) {
        if (_itemDetail == null) return;
        _itemDetail = _itemDetail!.copyWith(biddingCount: newCount);
        notifyListeners();
      },
      onTopBidderUpdate: (isTopBidder) {
        // isTopBidder가 변경되었을 때만 업데이트
        if (_isTopBidder != isTopBidder) {
          _isTopBidder = isTopBidder;
          notifyListeners();
        }
      },
      onStatusUpdate: () {
        // 순환참조 방지: 이미 새로고침 중이면 무시
        if (_isRefreshingFromRealtime || _isLoadingDetail) return;

        // 디바운싱: 짧은 시간 내 여러 업데이트가 오면 마지막 것만 처리
        // 상태 변경(예: 경매 종료)은 중요한 변경이므로 전체 새로고침 필요
        // TODO: 최적화 가능 - 백엔드에서 상태변경과 함께 finish_time, winner_id 등을 함께 제공하면
        // 부분 업데이트로 처리 가능. 현재는 전체 재조회 필요
        _statusUpdateDebounceTimer?.cancel();
        _statusUpdateDebounceTimer = Timer(
          const Duration(milliseconds: 1000),
          () {
            if (_isRefreshingFromRealtime || _isLoadingDetail) return;
            _isRefreshingFromRealtime = true;
            super.invalidateCache();
            // 상태 변경 시에는 전체 새로고침 필요 (중요한 변경)
            loadItemDetail(forceRefresh: true);
          },
        );
      },
      onFinishTimeUpdate: () {
        // 순환참조 방지: 이미 새로고침 중이면 무시
        if (_isRefreshingFromRealtime || _isLoadingDetail) return;

        // 종료 시간 업데이트는 부분 업데이트로 처리 가능
        // 디바운싱: 짧은 시간 내 여러 업데이트가 오면 마지막 것만 처리
        _statusUpdateDebounceTimer?.cancel();
        _statusUpdateDebounceTimer = Timer(
          const Duration(milliseconds: 500),
          () {
            if (_isRefreshingFromRealtime || _isLoadingDetail) return;
            // 종료 시간만 업데이트 (부분 업데이트)
            // 실시간 구독에서 finish_time을 받아서 직접 업데이트할 수 없으므로
            // 최소한의 데이터만 가져오도록 최적화는 어려움
            // 대신 디바운싱 시간을 늘려서 호출 빈도 감소
            _isRefreshingFromRealtime = true;
            super.invalidateCache();
            loadItemDetail(forceRefresh: true);
          },
        );
      },
      onNotifyListeners: notifyListeners,
    );
  }

  /// 데이터베이스에서 직접 isTopBidder 확인
  /// 엣지 펑션에서 값을 받지 못한 경우 사용
  // 기존 DB 직접 조회 방식은 오케스트레이션 유즈케이스로 대체됨

  @override
  void dispose() {
    // 디바운스 타이머 정리
    _statusUpdateDebounceTimer?.cancel();
    _statusUpdateDebounceTimer = null;
    // 리얼타임 구독 정리
    _realtimeManager.dispose();
    super.dispose();
  }
}
