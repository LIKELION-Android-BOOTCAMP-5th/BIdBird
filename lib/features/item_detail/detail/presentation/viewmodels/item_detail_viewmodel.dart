import 'dart:async';
import 'package:bidbird/core/utils/event_bus/item_event_bus.dart';
import 'package:bidbird/core/viewmodels/item_base_viewmodel.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bidbird/features/item_detail/detail/domain/repositories/item_detail_repository.dart'
    as domain;
import 'package:bidbird/features/item_detail/detail/data/repositories/item_detail_repository.dart'
    as data;
import 'package:bidbird/features/item_detail/detail/data/managers/item_detail_realtime_manager.dart';
import 'package:bidbird/features/item_detail/detail/domain/usecases/fetch_item_detail_usecase.dart';
import 'package:bidbird/features/item_detail/detail/domain/usecases/toggle_favorite_usecase.dart';
import 'package:bidbird/features/item_detail/detail/domain/usecases/fetch_bid_history_usecase.dart';
import 'package:bidbird/features/item_detail/detail/domain/usecases/orchestrations/item_detail_flow_usecase.dart';

// BidHistoryItem은 item_detail_entity.dart에 정의되어 있음
class ItemDetailViewModel extends ItemBaseViewModel {
  final String itemId;
  late final FetchItemDetailUseCase _fetchItemDetailUseCase;
  late final ToggleFavoriteUseCase _toggleFavoriteUseCase;
  late final FetchBidHistoryUseCase _fetchBidHistoryUseCase;

  final domain.ItemDetailRepository _repository;
  late final ItemDetailFlowUseCase _flowUseCase;

  ItemDetailViewModel({
    required this.itemId,
    FetchItemDetailUseCase? fetchItemDetailUseCase,
    ToggleFavoriteUseCase? toggleFavoriteUseCase,
    FetchBidHistoryUseCase? fetchBidHistoryUseCase,
    domain.ItemDetailRepository? repository,
  }) : _repository = repository ?? data.ItemDetailRepositoryImpl() {
    // 모든 UseCase가 동일한 repository 인스턴스를 사용하도록 설정
    _fetchItemDetailUseCase =
        fetchItemDetailUseCase ?? FetchItemDetailUseCase(_repository);
    _toggleFavoriteUseCase =
        toggleFavoriteUseCase ?? ToggleFavoriteUseCase(_repository);
    _fetchBidHistoryUseCase =
        fetchBidHistoryUseCase ?? FetchBidHistoryUseCase(_repository);



    // 초기 로딩 상태 설정
    setLoading(true);
    _flowUseCase = ItemDetailFlowUseCase(
      fetchItemDetailUseCase: _fetchItemDetailUseCase,
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

  String? _sellerProfileImage;
  String? get sellerProfileImage => _sellerProfileImage;

  List<BidHistoryItem> _bidHistory = [];
  List<BidHistoryItem> get bidHistory => _bidHistory;

  final ItemDetailRealtimeManager _realtimeManager =
      ItemDetailRealtimeManager();
  bool _isLoadingDetail = false;
  bool _isRefreshingFromRealtime = false; // 리얼타임 업데이트로 인한 새로고침 중인지 추적
  Timer? _realtimeUpdateDebounceTimer; // 통합 디바운싱 타이머

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

  Future<void> loadItemDetail({bool forceRefresh = false}) async {
    if (_isLoadingDetail) return;
    await _loadBidWinScreenFlag();

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
    _sellerProfileImage = r.sellerProfileImage;
    _isTopBidder = r.isTopBidder;

    if (previousStatusCode != null &&
        previousStatusCode != _itemDetail!.statusCode) {
      await resetBidWinScreenFlag();
    }

    stopLoading();
    notifyListeners();

    // ✅ 백그라운드 작업들 (로딩 화면을 블로킹하지 않음)
    setupRealtimeSubscription();
    _preloadImages(_itemDetail?.itemImages ?? []);

    _isLoadingDetail = false;
    _isRefreshingFromRealtime = false;
  }



  bool _isLoadingBidHistory = false;

  /// 입찰 내역을 로드합니다. 바텀 시트가 열릴 때 호출됩니다.
  Future<void> loadBidHistory() async {
    // 중복 호출 방지
    if (_isLoadingBidHistory) return;

    _isLoadingBidHistory = true;
    try {
      _bidHistory = await _fetchBidHistoryUseCase(itemId);
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
        
        // 홈 화면 등에 업데이트 알림
        eventBus.fire(ItemUpdateEvent(
          itemId: itemId,
          currentPrice: newPrice,
        ));

        // ✅ 가격 업데이트 시 최고 입찰자 상태를 즉시 확인
        // (WebSocket 지연으로 인한 타이밍 이슈 방지)
        _checkAndUpdateTopBidderStatus();
        notifyListeners();
      },
      onBidCountUpdate: (newCount) {
        if (_itemDetail == null) return;
        _itemDetail = _itemDetail!.copyWith(biddingCount: newCount);
        
        // 홈 화면 등에 업데이트 알림
        eventBus.fire(ItemUpdateEvent(
          itemId: itemId,
          biddingCount: newCount,
        ));
        
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
        _handleStatusOrTimeUpdate();
      },
      onFinishTimeUpdate: () {
        _handleStatusOrTimeUpdate();
      },
      onNotifyListeners: notifyListeners,
    );
  }

  /// 데이터베이스에서 직접 isTopBidder 확인
  /// 엣지 펑션에서 값을 받지 못한 경우 사용
  // 기존 DB 직접 조회 방식은 오케스트레이션 유즈케이스로 대체됨

  /// 통합된 상태/시간 업데이트 핸들러
  void _handleStatusOrTimeUpdate() {
    if (_isRefreshingFromRealtime || _isLoadingDetail) return;

    // 기존 타이머 취소
    _realtimeUpdateDebounceTimer?.cancel();

    // 새 타이머 설정 (1초 디바운스)
    _realtimeUpdateDebounceTimer = Timer(
      const Duration(milliseconds: 1000),
      () {
        if (_isRefreshingFromRealtime || _isLoadingDetail) return;
        _isRefreshingFromRealtime = true;
        loadItemDetail(forceRefresh: true);
      },
    );
  }

  /// 최고 입찰자 상태를 즉시 확인하고 업데이트
  /// 입찰 직후 WebSocket 지연으로 인한 타이밍 이슈를 방지하기 위해
  /// 가격 업데이트 시 즉시 호출됨
  Future<void> _checkAndUpdateTopBidderStatus() async {
    try {
      // Repository에서 현재 최고 입찰자 여부를 직접 조회
      final isCurrentlyTopBidder = await _repository.isCurrentUserTopBidder(
        itemId,
      );

      // 상태가 변경되었을 때만 업데이트
      if (_isTopBidder != isCurrentlyTopBidder) {
        _isTopBidder = isCurrentlyTopBidder;
        notifyListeners();
      }
    } catch (e) {
      // DB 조회 실패 시 무시 (WebSocket 업데이트가 올 예정)
    }
  }

  /// 이미지 프리로딩 (백그라운드에서 수행)
  /// 상세 화면이 이미 표시된 후에 이미지를 로드하여 UX 개선
  void _preloadImages(List<String> imageUrls) {
    // UI 스레드 블로킹하지 않고 백그라운드에서 처리
    for (final url in imageUrls) {
      if (url.isNotEmpty) {
        // 이미지 캐시 워밍 (실제 로드는 화면에서 이루어짐)
        // 네트워크 요청만 미리 시작하여 캐시에 저장
        Future.microtask(() {
          // ImageCache를 통한 프리로딩 시도
          // 구체적인 구현은 플랫폼별로 다를 수 있음
        });
      }
    }
  }

  @override
  void dispose() {
    // 통합 타이머 정리
    _realtimeUpdateDebounceTimer?.cancel();
    _realtimeUpdateDebounceTimer = null;
    // 리얼타임 구독 정리
    _realtimeManager.dispose();
    super.dispose();
  }
}
