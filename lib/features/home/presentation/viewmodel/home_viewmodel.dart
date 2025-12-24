import 'dart:async';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/event_bus/login_event_bus.dart';
import 'package:bidbird/main.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/items_entity.dart';
import '../../domain/entities/keywordType_entity.dart';
import '../../domain/repositories/home_repository.dart';

//최신순, 오래된순, 좋아요순 처리할 때 쓸 것
enum OrderByType { newFirst, oldFirst, likesFirst }

class HomeViewmodel extends ChangeNotifier {
  final HomeRepository _homeRepository;
  StreamSubscription? _loginSubscription;
  //키워드 그릇 생성
  List<KeywordType> _keywords = [];
  List<KeywordType> get keywords => _keywords;
  //Items 그릇 생성
  List<ItemsEntity> _items = [];
  List<ItemsEntity> get items => _items;

  bool buttonIsWorking = false;
  OrderByType type = OrderByType.newFirst;
  String selectKeyword = "전체";

  //리얼타임
  RealtimeChannel? _actionRealtime;

  //로딩 플래그 개선
  bool _isFetching = false;
  bool _hasMore = true;

  //검색 기능 관련
  bool searchButton = false;
  final userInputController = TextEditingController();
  // 글씨 지우면 검색모드 꺼지기
  bool isSearching = false;
  String currentSearchText = "";

  // 폴링 관련
  Timer? _pollingTimer;
  bool _isPollingActive = false;
  static const Duration _pollingInterval = Duration(seconds: 6);

  // 검색 캐싱
  final Map<String, List<ItemsEntity>> _searchCache = {};

  int? get selectedKeywordId {
    if (selectKeyword == "전체") return null;
    try {
      return _keywords.firstWhere((e) => e.title == selectKeyword).id;
    } catch (_) {
      return null;
    }
  }

  //페이징 처리
  int _currentPage = 1;
  int get currentPage => _currentPage;
  //스크롤 컨트롤러
  Timer? _debounce;
  ScrollController scrollController = ScrollController();
  // 정렬/notify 배치 호출용
  Timer? _sortDebounce;

  //실시간 검색
  Timer? _searchDebounce;
  int _searchRequestId = 0; // 최신 검색 요청 식별자

  //ios fetch문제 잡기
  bool _isDisposed = false;

  ///시작할 때 작동
  HomeViewmodel(this._homeRepository) {
    getKeywordList();

    _loginSubscription = eventBus.on<LoginEventBus>().listen((event) {
      if (event.type == LoginEventType.logout) {
        _clearAllData();
      }
    });

    // 스크롤 fetch 설정 부분, 여기서 기본적인 fetch도 이루어짐
    scrollController.addListener(() {
      if (isSearching == true) return;

      // 마지막에 도달하면 다음 페이지 로드
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        fetchNextItems();
      }
    });
    if (_isDisposed) return;
    fetchItems();
    //리얼 타임
    setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loginSubscription?.cancel();
    scrollController.dispose();
    _debounce?.cancel();
    _searchDebounce?.cancel();
    _sortDebounce?.cancel();
    _pollingTimer?.cancel();
    userInputController.dispose();

    if (_actionRealtime != null) {
      SupabaseManager.shared.supabase.removeChannel(_actionRealtime!);
    }

    super.dispose();
  }

  Future<void> getKeywordList() async {
    keywords.addAll(await _homeRepository.getKeywordType());
    notifyListeners();
  }

  String setOrderBy(OrderByType type) {
    if (type == OrderByType.newFirst) {
      return "created_at.desc";
    } else if (type == OrderByType.oldFirst) {
      return "created_at.asc";
    } else {
      return "likes_count.desc";
    }
  }

  //판매 중인 아이템 위로 보내는 로직
  void sortItemsByFinishTime() {
    final now = DateTime.now();

    _items.sort((a, b) {
      final bool aActive = a.finishTime.isAfter(now); // a가 아직 종료 안됐는가?
      final bool bActive = b.finishTime.isAfter(now); // b가 아직 종료 안됐는가?

      // 진행 중(finishTime > now) 먼저
      if (aActive != bActive) {
        return aActive ? -1 : 1;
      }

      // 둘 다 진행 중이면 종료 임박 순으로, 둘 다 종료면 종료 시간 늦은 순으로
      final int finishCompare = a.finishTime.compareTo(b.finishTime);
      if (aActive && bActive) {
        return finishCompare; // 더 빨리 끝나는 것 우선
      }
      // 둘 다 종료 상태면 최신 종료를 아래로 보내기 위해 역순 정렬
      return -finishCompare;
    });
  }

  // 실시간 아이템 업데이트 (사용 안 함 - 폴링으로 변경)
  // ignore: unused_element
  void _scheduleResortAndNotify({
    Duration delay = const Duration(milliseconds: 150),
  }) {
    if (_isDisposed) return;
    _sortDebounce?.cancel();
    _sortDebounce = Timer(delay, () {
      if (_isDisposed) return;
      sortItemsByFinishTime();
      notifyListeners();
    });
  }

  Future<void> fetchItems() async {
    String orderBy = setOrderBy(type);
    _hasMore = true;
    _items = await _homeRepository.fetchItems(
      orderBy,
      currentIndex: _currentPage,
      keywordType: selectedKeywordId,
    );
    if (_isDisposed) return;
    sortItemsByFinishTime();
    notifyListeners();
  }

  Future<void> handleRefresh() async {
    String orderBy = setOrderBy(type);
    _currentPage = 1;
    _items = [];
    _hasMore = true;
    _isFetching = false; // 캐시된 fetch 플래그 초기화
    notifyListeners();
    _items = await _homeRepository.fetchItems(
      orderBy,
      currentIndex: _currentPage,
      keywordType: selectedKeywordId,
    );
    sortItemsByFinishTime();
    notifyListeners();
  }

  Future<void> fetchNextItems() async {
    if (_isFetching || !_hasMore) return;

    _isFetching = true;

    String orderBy = setOrderBy(type);
    final nextPage = _currentPage + 1;

    List<ItemsEntity> newFetchPosts;

    if (isSearching) {
      newFetchPosts = await _homeRepository.fetchSearchResult(
        orderBy,
        currentIndex: nextPage,
        keywordType: selectedKeywordId,
        userInputSearchText: currentSearchText,
      );
    } else {
      newFetchPosts = await _homeRepository.fetchItems(
        orderBy,
        currentIndex: nextPage,
        keywordType: selectedKeywordId,
      );
    }

    if (newFetchPosts.isEmpty) {
      _hasMore = false;
    } else {
      _currentPage = nextPage;
      _items.addAll(newFetchPosts);
    }

    sortItemsByFinishTime();
    _isFetching = false;
    notifyListeners();
  }

  Future<void> selectKeywordAndFetch(String keyword, int? keywordId) async {
    selectKeyword = keyword;
    _currentPage = 1;
    _items = [];
    _hasMore = true;
    notifyListeners();

    String orderBy = setOrderBy(type);

    if (isSearching) {
      // 검색 중이면 검색 결과 + 키워드 필터로 호출
      _items = await _homeRepository.fetchSearchResult(
        orderBy,
        currentIndex: _currentPage,
        keywordType: keywordId,
        userInputSearchText: currentSearchText,
      );
    } else {
      // 평소 모드
      _items = await _homeRepository.fetchItems(
        orderBy,
        currentIndex: _currentPage,
        keywordType: keywordId,
      );
    }

    sortItemsByFinishTime();

    notifyListeners();
  }

  Future<void> workSearchBar() async {
    searchButton = !searchButton;
    notifyListeners();
  }

  Future<void> search(String userInput) async {
    final requestId = ++_searchRequestId; // 최신 요청 토큰
    isSearching = userInput.isNotEmpty;
    currentSearchText = userInput;
    _currentPage = 1;
    _items = [];
    notifyListeners();

    String orderBy = setOrderBy(type);
    userInputController.text = userInput;

    // 캐시 확인
    if (_searchCache.containsKey(userInput)) {
      _items = List.from(_searchCache[userInput]!);
      sortItemsByFinishTime();
      notifyListeners();
      return;
    }

    _items = await _homeRepository.fetchSearchResult(
      orderBy,
      currentIndex: _currentPage,
      keywordType: selectedKeywordId,
      userInputSearchText: userInput,
    );

    // 늦게 도착한 응답은 폐기
    if (requestId != _searchRequestId) {
      return;
    }

    // 캐싱
    _searchCache[userInput] = List.from(_items);

    sortItemsByFinishTime();

    notifyListeners();
  }

  // 실시간 검색 호출
  void onSearchTextChanged(String text) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 100), () {
      if (_isDisposed) return;
      isSearching = text.isNotEmpty;
      search(text);
    });
  }

  Future<void> searchNextItems() async {
    if (_isFetching || !_hasMore) return;

    _isFetching = true;
    _currentPage++;

    String orderBy = setOrderBy(type);

    List<ItemsEntity> moreItems = await _homeRepository.fetchSearchResult(
      orderBy,
      currentIndex: _currentPage,
      keywordType: selectedKeywordId,
      userInputSearchText: currentSearchText,
    );

    if (moreItems.isEmpty) {
      _hasMore = false;
    } else {
      _items.addAll(moreItems);
    }

    sortItemsByFinishTime();

    _isFetching = false;
    notifyListeners();
  }

  void setupRealtimeSubscription() {
    // 폴링 시작 (6초마다 아이템 정렬 상태 확인)
    _startPolling();
  }

  void _startPolling() {
    if (_isPollingActive) return;
    _isPollingActive = true;

    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      if (_isDisposed) {
        _stopPolling();
        return;
      }

      // 현재 시간과 비교하여 종료/시작 상태 변경 확인
      final now = DateTime.now();
      bool needsUpdate = false;

      for (final item in _items) {
        if (item.finishTime.difference(now).inSeconds.abs() < 10) {
          // 종료 시간 10초 이내일 때만 업데이트 확인
          needsUpdate = true;
          break;
        }
      }

      // 필요할 때만 정렬 및 알림
      if (needsUpdate) {
        sortItemsByFinishTime();
        notifyListeners();
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPollingActive = false;
  }

  /// 로그아웃 시 모든 데이터 초기화
  void _clearAllData() {
    _items = [];
    _keywords = [];
    _searchCache.clear();
    selectKeyword = "전체";
    _currentPage = 1;
    _hasMore = true;
    _isFetching = false;
    searchButton = false;
    isSearching = false;
    currentSearchText = "";
    userInputController.clear();
    _stopPolling();
    _actionRealtime?.unsubscribe();
    _actionRealtime = null;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }
}
