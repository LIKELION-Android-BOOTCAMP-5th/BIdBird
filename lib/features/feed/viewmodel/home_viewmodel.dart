import 'dart:async';

import 'package:bidbird/core/models/items_entity.dart';
import 'package:flutter/widgets.dart';

import '../data/repository/home_repository.dart';
import '../model/home_data.dart';

//최신순, 오래된순, 좋아요순 처리할 때 쓸 것
enum OrderByType { newFirst, oldFirst, likesFirst }

class HomeViewmodel extends ChangeNotifier {
  final HomeRepository _homeRepository;
  //키워드 그릇 생성
  List<HomeCodeKeywordType> _keywords = [];
  List<HomeCodeKeywordType> get keywords => _keywords;
  //Items 그릇 생성
  List<ItemsEntity> _Items = [];
  List<ItemsEntity> get Items => _Items;
  bool buttonIsWorking = false;
  OrderByType type = OrderByType.newFirst;
  String selectKeyword = "전체";

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

  Timer? _debounce;

  //페이징 처리
  int _currentPage = 1;
  int get currentPage => _currentPage;
  //스크롤 컨트롤러
  ScrollController scrollController = ScrollController();

  //실시간 검색
  Timer? _searchDebounce;

  ///시작할 때 작동
  HomeViewmodel(this._homeRepository) {
    getKeywordList();

    // 스크롤 fetch 설정 부분, 여기서 기본적인 fetch도 이루어짐
    scrollController.addListener(() async {
      if (_debounce?.isActive ?? false) _debounce!.cancel();

      _debounce = Timer(const Duration(milliseconds: 300), () {
        final double offset = scrollController.offset;

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

      if (scrollController.position.atEdge &&
          scrollController.position.pixels != 0) {
        fetchNextItems();
      }
      //이걸 추가해야지 더욱 안정적이로 스크롤 닿기 전에 이미 fetch되어서 자연스러움
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 200) {
        fetchNextItems();
      }
    });
    fetchItems();
  }

  //[메모리 누수] scrollController, Timer 정지
  @override
  void dispose() {
    scrollController.dispose();
    _debounce?.cancel();
    _searchDebounce?.cancel();
    // TODO: implement dispose
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

  Future<void> fetchItems() async {
    String orderBy = setOrderBy(type);
    _Items = await _homeRepository.fetchItems(
      orderBy,
      currentIndex: _currentPage,
      keywordType: selectedKeywordId,
    );
    notifyListeners();
  }

  Future<void> handleRefresh() async {
    String orderBy = setOrderBy(type);
    _currentPage = 1;
    _Items = [];
    notifyListeners();
    _Items = await _homeRepository.fetchItems(
      orderBy,
      currentIndex: _currentPage,
    );
    notifyListeners();
  }

  Future<void> fetchNextItems() async {
    String orderBy = setOrderBy(type);
    _currentPage++;

    List<ItemsEntity> newFetchPosts;

    if (isSearching) {
      newFetchPosts = await _homeRepository.fetchSearchResult(
        orderBy,
        currentIndex: _currentPage,
        keywordType: selectedKeywordId,
        userInputSearchText: currentSearchText,
      );
    } else {
      newFetchPosts = await _homeRepository.fetchItems(
        orderBy,
        currentIndex: _currentPage,
        keywordType: selectedKeywordId,
      );
    }

    _Items.addAll(newFetchPosts);
    notifyListeners();
  }

  Future<void> selectKeywordAndFetch(String keyword, int? keywordId) async {
    selectKeyword = keyword;
    _currentPage = 1;
    _Items = [];
    notifyListeners();

    String orderBy = setOrderBy(type);

    if (isSearching) {
      // 검색 중이면 검색 결과 + 키워드 필터로 호출
      _Items = await _homeRepository.fetchSearchResult(
        orderBy,
        currentIndex: _currentPage,
        keywordType: keywordId,
        userInputSearchText: currentSearchText,
      );
    } else {
      // 평소 모드
      _Items = await _homeRepository.fetchItems(
        orderBy,
        currentIndex: _currentPage,
        keywordType: keywordId,
      );
    }

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
    _Items = [];
    notifyListeners();

    String orderBy = setOrderBy(type);
    userInputController.text = userInput;

    _Items = await _homeRepository.fetchSearchResult(
      orderBy,
      currentIndex: _currentPage,
      keywordType: selectedKeywordId,
      userInputSearchText: userInput,
    );

    notifyListeners();
  }

  // 실시간 검색 호출
  void onSearchTextChanged(String text) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 100), () {
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

    _Items.addAll(moreItems);
    notifyListeners();
  }
}
