import 'dart:async';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/items_entity.dart';
import '../../domain/entities/keywordType_entity.dart';
import '../../domain/repositories/home_repository.dart';

//최신순, 오래된순, 좋아요순 처리할 때 쓸 것
enum OrderByType { newFirst, oldFirst, likesFirst }

class HomeViewmodel extends ChangeNotifier {
  final HomeRepository _homeRepository;
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

  //실시간 검색
  Timer? _searchDebounce;

  //ios fetch문제 잡기
  bool _isDisposed = false;

  ///시작할 때 작동
  HomeViewmodel(this._homeRepository) {
    getKeywordList();

    // 스크롤 fetch 설정 부분, 여기서 기본적인 fetch도 이루어짐
    scrollController.addListener(() async {
      if (_debounce?.isActive ?? false) _debounce!.cancel();

      _debounce = Timer(const Duration(milliseconds: 300), () {
        final double offset = scrollController.offset;
        if (_isDisposed) return;

        if (offset < 50) {
          if (buttonIsWorking) {
            buttonIsWorking = false;
            notifyListeners();
          }
        } else {
          if (!buttonIsWorking) {
            buttonIsWorking = true;
            notifyListeners();
          }
        }
      });

      if (isSearching == true) return;

      // if (scrollController.position.atEdge &&
      //     scrollController.position.pixels != 0) {
      //   fetchNextItems();
      // }
      //이걸 추가해야지 더욱 안정적이로 스크롤 닿기 전에 이미 fetch되어서 자연스러움
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

  //[메모리 누수] scrollController, Timer 정지

  @override
  void dispose() {
    _isDisposed = true;
    scrollController.dispose();
    _debounce?.cancel();
    _searchDebounce?.cancel();
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
    if (type == OrderByType.newFirst)
      return "created_at.desc";
    else if (type == OrderByType.oldFirst)
      return "created_at.asc";
    else
      return "likes_count.desc";
  }

  //판매 중인 아이템 위로 보내는 로직
  void sortItemsByFinishTime() {
    final now = DateTime.now();

    _items.sort((a, b) {
      final bool aActive = a.finishTime.isAfter(now); // a가 아직 종료 안됐는가?
      final bool bActive = b.finishTime.isAfter(now); // b가 아직 종료 안됐는가?

      // 진행 중(finishTime > now) 먼저
      if (aActive && !bActive) return -1; // a 먼저
      if (!aActive && bActive) return 1; // b 먼저

      // 둘 다 진행중이거나 둘 다 종료 → 기존 정렬 유지
      return 0;
    });
  }

  Future<void> fetchItems() async {
    String orderBy = setOrderBy(type);
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
    notifyListeners();
    _items = await _homeRepository.fetchItems(
      orderBy,
      currentIndex: _currentPage,
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
    isSearching = userInput.isNotEmpty;
    currentSearchText = userInput;
    _currentPage = 1;
    _items = [];
    notifyListeners();

    String orderBy = setOrderBy(type);
    userInputController.text = userInput;

    _items = await _homeRepository.fetchSearchResult(
      orderBy,
      currentIndex: _currentPage,
      keywordType: selectedKeywordId,
      userInputSearchText: userInput,
    );

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
    _currentPage++;

    String orderBy = setOrderBy(type);

    List<ItemsEntity> moreItems = await _homeRepository.fetchSearchResult(
      orderBy,
      currentIndex: _currentPage,
      keywordType: selectedKeywordId,
      userInputSearchText: currentSearchText,
    );

    _items.addAll(moreItems);

    sortItemsByFinishTime();

    notifyListeners();
  }

  void setupRealtimeSubscription() {
    _actionRealtime = SupabaseManager.shared.supabase.channel(
      'HomeActionChanel',
    );

    _actionRealtime!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'auctions',
          callback: (payload) {
            final newData = payload.newRecord;

            final itemId = newData['item_id'];
            final index = _items.indexWhere((e) => e.item_id == itemId);
            if (index == -1) return;

            final item = _items[index];

            // 1) bid_count 업데이트
            item.auctions.bid_count =
                newData['bid_count'] ?? item.auctions.bid_count;

            // 2) current_price 업데이트
            item.auctions.current_price =
                newData['current_price'] ?? item.auctions.current_price;

            // 3) finishTime 업데이트
            final endAt = newData['auction_end_at']?.toString();
            if (endAt != null && endAt.isNotEmpty) {
              item.finishTime = DateTime.tryParse(endAt) ?? item.finishTime;
            }
            if (_isDisposed) return;
            sortItemsByFinishTime();
            notifyListeners();
          },
        )
        .subscribe();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }
}
