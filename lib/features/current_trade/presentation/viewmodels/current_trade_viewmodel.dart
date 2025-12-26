import 'dart:async';

import 'package:bidbird/core/utils/event_bus/login_event_bus.dart';
import 'package:bidbird/core/viewmodels/item_base_viewmodel.dart';
import 'package:bidbird/core/utils/item/trade_status_codes.dart';
import 'package:bidbird/features/current_trade/data/repositories/current_trade_repository.dart';
import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';
import 'package:bidbird/features/current_trade/domain/usecases/fetch_my_bid_history_usecase.dart';
import 'package:bidbird/features/current_trade/domain/usecases/fetch_my_sale_history_usecase.dart';
import 'package:bidbird/main.dart';

/// CurrentTrade ViewModel - Thin Pattern
/// 책임: 거래 내역 UI 상태 관리, 필터링/캠싱
/// 제외: 복잡한 비즈니스 로직 (UseCase에서 처리)
class CurrentTradeViewModel extends ItemBaseViewModel {
  final FetchMyBidHistoryUseCase _fetchMyBidHistoryUseCase;
  final FetchMySaleHistoryUseCase _fetchMySaleHistoryUseCase;
  StreamSubscription? _loginSubscription;

  List<BidHistoryItem> _bidHistory = [];
  List<SaleHistoryItem> _saleHistory = [];

  // State: Caching
  static const Duration _cacheValidDuration = Duration(minutes: 2);

  // 필터링 결과 캐시 (통합: 11개 변수 → 1개 맵)
  final Map<String, dynamic> _filterCache = {};

  // 캐시 키 상수
  static const String _cacheKeyTodoBid = 'todoBid';
  static const String _cacheKeyInProgressBid = 'inProgressBid';
  static const String _cacheKeyCompletedBid = 'completedBid';
  static const String _cacheKeyTodoSale = 'todoSale';
  static const String _cacheKeyInProgressSale = 'inProgressSale';
  static const String _cacheKeyCompletedSale = 'completedSale';
  static const String _cacheKeyFilteredBid = 'filteredBid';
  static const String _cacheKeyFilteredSale = 'filteredSale';
  static const String _cacheKeyBidActionHub = 'bidActionHub';
  static const String _cacheKeySaleActionHub = 'saleActionHub';
  static const String _cacheKeyAllItems = 'allItems';

  // 페이지네이션 필드 추가 (무한 스크롤용)
  static const int _itemsPerPage = 10;
  int _currentPage = 0;

  // State: UI Status
  int _pendingActionCount = 0;
  int _acknowledgedPendingCount = 0;

  int get displayedItemCount => (_currentPage + 1) * _itemsPerPage;

  /// 자동 로드 가능 여부
  bool get canLoadMore => displayedItemCount < allItems.length;

  CurrentTradeViewModel({
    FetchMyBidHistoryUseCase? fetchMyBidHistoryUseCase,
    FetchMySaleHistoryUseCase? fetchMySaleHistoryUseCase,
  }) : _fetchMyBidHistoryUseCase =
           fetchMyBidHistoryUseCase ??
           FetchMyBidHistoryUseCase(CurrentTradeRepositoryImpl()),
       _fetchMySaleHistoryUseCase =
           fetchMySaleHistoryUseCase ??
           FetchMySaleHistoryUseCase(CurrentTradeRepositoryImpl()) {
    _loginSubscription = eventBus.on<LoginEventBus>().listen((event) {
      if (event.type == LoginEventType.logout) {
        _clearAllData();
      }
    });
  }

  List<BidHistoryItem> get bidHistory => _bidHistory;
  List<SaleHistoryItem> get saleHistory => _saleHistory;

  // Computed: Filtered Items by Status
  List<BidHistoryItem> get todoBidItems {
    return _filterCache.putIfAbsent(
          _cacheKeyTodoBid,
          () => _filterByStatus(_bidHistory, TradeItemStatus.todo),
        )
        as List<BidHistoryItem>;
  }

  List<BidHistoryItem> get inProgressBidItems {
    return _filterCache.putIfAbsent(
          _cacheKeyInProgressBid,
          () => _filterByStatus(_bidHistory, TradeItemStatus.inProgress),
        )
        as List<BidHistoryItem>;
  }

  List<BidHistoryItem> get completedBidItems {
    return _filterCache.putIfAbsent(
          _cacheKeyCompletedBid,
          () => _filterByStatus(_bidHistory, TradeItemStatus.completed),
        )
        as List<BidHistoryItem>;
  }

  List<SaleHistoryItem> get todoSaleItems {
    return _filterCache.putIfAbsent(
          _cacheKeyTodoSale,
          () => _filterByStatus(_saleHistory, TradeItemStatus.todo),
        )
        as List<SaleHistoryItem>;
  }

  List<SaleHistoryItem> get inProgressSaleItems {
    return _filterCache.putIfAbsent(
          _cacheKeyInProgressSale,
          () => _filterByStatus(_saleHistory, TradeItemStatus.inProgress),
        )
        as List<SaleHistoryItem>;
  }

  List<SaleHistoryItem> get completedSaleItems {
    return _filterCache.putIfAbsent(
          _cacheKeyCompletedSale,
          () => _filterByStatus(_saleHistory, TradeItemStatus.completed),
        )
        as List<SaleHistoryItem>;
  }

  /// 현재 처리해야 할 거래가 존재하는지 여부 (미확인 건 기준)
  bool get hasPendingTradeAction {
    return _pendingActionCount > _acknowledgedPendingCount;
  }

  void markPendingActionsAcknowledged() {
    final changed = _pendingActionCount > _acknowledgedPendingCount;
    _acknowledgedPendingCount = _pendingActionCount;
    if (changed) {
      notifyListeners();
    }
  }

  List<SaleHistoryItem> get filteredSaleItems {
    return _filterCache.putIfAbsent(
          _cacheKeyFilteredSale,
          () => [
            ...todoSaleItems,
            ...inProgressSaleItems,
            ...completedSaleItems,
          ].where((item) => !item.status.contains('유찰')).toList(),
        )
        as List<SaleHistoryItem>;
  }

  List<BidHistoryItem> get filteredBidItems {
    return _filterCache.putIfAbsent(
          _cacheKeyFilteredBid,
          () => [
            ...todoBidItems,
            ...inProgressBidItems,
            ...completedBidItems,
          ].where((item) => !item.status.contains('유찰')).toList(),
        )
        as List<BidHistoryItem>;
  }

  List<({bool isSeller, bool isHighlighted, dynamic item})> get allItems {
    return _filterCache.putIfAbsent(
          _cacheKeyAllItems,
          () => [
            // 판매 아이템 추가
            for (var item in filteredSaleItems)
              (
                isSeller: true,
                isHighlighted: item.itemStatus == TradeItemStatus.todo,
                item: item,
              ),
            // 입찰 아이템 추가
            for (var item in filteredBidItems)
              (
                isSeller: false,
                isHighlighted: item.itemStatus == TradeItemStatus.todo,
                item: item,
              ),
          ],
        )
        as List<({bool isSeller, bool isHighlighted, dynamic item})>;
  }

  /// 페이지네이션된 아이템 반환
  List<({bool isSeller, bool isHighlighted, dynamic item})>
  get allItemsPaginated {
    return allItems.take(displayedItemCount).toList();
  }

  /// 더 많은 아이템 로드
  void loadMoreItems() {
    if (displayedItemCount < allItems.length) {
      _currentPage++;
      notifyListeners();
    }
  }

  List<T> _filterByStatus<T extends TradeHistoryItem>(
    List<T> items,
    TradeItemStatus status,
  ) {
    return items.where((item) => item.itemStatus == status).toList();
  }

  List<ActionHubItem> get bidActionHubItems {
    return _filterCache.putIfAbsent(
          _cacheKeyBidActionHub,
          () => _buildActionHubItems(_bidHistory, [
            TradeActionType.paymentRequired,
            TradeActionType.purchaseConfirmRequired,
          ]),
        )
        as List<ActionHubItem>;
  }

  List<ActionHubItem> get saleActionHubItems {
    return _filterCache.putIfAbsent(
          _cacheKeySaleActionHub,
          () => _buildActionHubItems(_saleHistory, [
            TradeActionType.paymentWaiting,
            TradeActionType.shippingInfoRequired,
          ]),
        )
        as List<ActionHubItem>;
  }

  List<ActionHubItem> _buildActionHubItems(
    List<TradeHistoryItem> items,
    List<TradeActionType> targetActionTypes,
  ) {
    final Map<TradeActionType, int> actionCounts = {
      for (final type in targetActionTypes) type: 0,
    };

    for (final item in items) {
      final actionType = item.actionType;
      if (actionType != TradeActionType.none &&
          actionCounts.containsKey(actionType)) {
        actionCounts[actionType] = (actionCounts[actionType] ?? 0) + 1;
      }
    }

    final hubItems = actionCounts.entries
        .map((e) => ActionHubItem(actionType: e.key, count: e.value))
        .toList();

    hubItems.sort((a, b) => b.count.compareTo(a.count));
    return hubItems.take(2).toList();
  }

  // Methods: Data Loading
  Future<void> loadData({bool forceRefresh = false}) async {
    if (isLoading) {
      return;
    }

    // 캐시가 유효하고 강제 새로고침이 아니면 캐시 사용
    if (!forceRefresh &&
        isCacheValid(_cacheValidDuration) &&
        _bidHistory.isNotEmpty &&
        _saleHistory.isNotEmpty) {
      return; // 캐시된 데이터 사용
    }

    try {
      startLoading();

      // 병렬로 입찰/판매 내역 조회 (페이징 파라미터: 페이지 1, 제한 20)
      final results = await Future.wait([
        _fetchMyBidHistoryUseCase(page: 1, limit: 20),
        _fetchMySaleHistoryUseCase(page: 1, limit: 20),
      ], eagerError: false);

      _bidHistory = results[0] as List<BidHistoryItem>;
      _saleHistory = results[1] as List<SaleHistoryItem>;

      _invalidateFilterCache();

      updateCacheTime();

      _pendingActionCount = _calculatePendingActionCount();
      if (_acknowledgedPendingCount > _pendingActionCount) {
        _acknowledgedPendingCount = _pendingActionCount;
      }
      notifyListeners();
    } catch (e) {
      _bidHistory = [];
      _saleHistory = [];
      _invalidateFilterCache();
      notifyListeners();

    } finally {
      stopLoading();
    }
  }

  /// 더 많은 거래 내역 불러오기 (무한 스크롤)
  Future<void> loadMoreTrades() async {
    final nextPage = (_currentPage + 1) + 1; // _currentPage는 0부터 시작

    try {
      startLoading();

      final results = await Future.wait([
        _fetchMyBidHistoryUseCase(page: nextPage, limit: 20),
        _fetchMySaleHistoryUseCase(page: nextPage, limit: 20),
      ], eagerError: false);

      final newBidHistory = results[0] as List<BidHistoryItem>;
      final newSaleHistory = results[1] as List<SaleHistoryItem>;

      _bidHistory.addAll(newBidHistory);
      _saleHistory.addAll(newSaleHistory);

      _invalidateFilterCache();
      _currentPage++;

      notifyListeners();
    } catch (e) {
      notifyListeners();

    } finally {
      stopLoading();
    }
  }

  Future<void> refresh() async {
    await loadData(forceRefresh: true);
  }

  /// 필터링 결과 캐시 무효화
  void _invalidateFilterCache() {
    _filterCache.clear();
    _currentPage = 0; // 페이지 리셋
  }

  /// 로그아웃 시 모든 데이터 초기화
  void _clearAllData() {
    _bidHistory = [];
    _saleHistory = [];
    _pendingActionCount = 0;
    _acknowledgedPendingCount = 0;
    _invalidateFilterCache();
    invalidateCache(); // 캐시 시간 초기화
    // notifyListeners()는 한 번만 호출
    notifyListeners();
  }

  int _calculatePendingActionCount() {
    int count = 0;

    for (final item in _saleHistory) {
      final statusCode = item.tradeStatusCode;
      if (statusCode == TradeStatusCode.paymentRequired) {
        count++;
        continue;
      }
      if (statusCode == TradeStatusCode.shippingInfoRequired &&
          !item.hasShippingInfo) {
        count++;
      }
    }

    for (final item in _bidHistory) {
      final statusCode = item.tradeStatusCode;
      if (statusCode == TradeStatusCode.paymentRequired) {
        count++;
        continue;
      }
      if (statusCode == TradeStatusCode.shippingInfoRequired &&
          item.hasShippingInfo) {
        count++;
        continue;
      }
      if ((statusCode == null || statusCode == 0) &&
          item.auctionStatusCode == AuctionStatusCode.bidWon) {
        count++;
      }
    }

    return count;
  }

  @override
  void dispose() {
    _loginSubscription?.cancel();
    super.dispose();
  }
}
