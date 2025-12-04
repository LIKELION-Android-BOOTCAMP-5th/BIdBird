import 'package:flutter/widgets.dart';

import '../model/home_data.dart';
import '../repository/home_repository.dart';

class HomeViewmodel extends ChangeNotifier {
  final HomeRepository _homeRepository;
  //키워드 그릇 생성
  List<HomeCodeKeywordType> _keywords = [];
  List<HomeCodeKeywordType> get keywords => _keywords;

  HomeViewmodel(this._homeRepository) {
    getKeywordList();
  }

  Future<void> getKeywordList() async {
    keywords.addAll(await _homeRepository.getKeywordType());
    notifyListeners();
  }
}
