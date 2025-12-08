import 'dart:async';

import 'package:bidbird/core/models/items_entity.dart';
import 'package:flutter/widgets.dart';

import '../model/home_data.dart';
import '../repository/home_repository.dart';

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
    List<ItemsEntity> newFetchPosts = await _homeRepository.fetchItems(
      orderBy,
      currentIndex: _currentPage,
      keywordType: selectedKeywordId,
    );
    _Items.addAll(newFetchPosts);
    notifyListeners();
  }

  void selectKeywordAndFetch(String keyword, int? keywordId) async {
    selectKeyword = keyword;
    _currentPage = 1;
    _Items = [];
    notifyListeners();

    String orderBy = setOrderBy(type);

    _Items = await _homeRepository.fetchItems(
      orderBy,
      currentIndex: _currentPage,
      keywordType: keywordId,
    );

    notifyListeners();
  }
}
