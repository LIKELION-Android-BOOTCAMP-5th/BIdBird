import 'package:flutter/material.dart';

import '../data/profile_repository.dart';
import '../model/profile_model.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;

  Profile? profile;
  List<int> _keywordIds = [];
  List<int> get keywordIds => _keywordIds;
  bool isLoading = false;

  String? errorMessage; //나중에팝업으로쓸것

  ProfileViewModel(this._repository) {
    loadProfile(); //생성자에서 쵸기로딩 // main에서 ..loadProfile()하지 않아도 됨
  }

  Future<void> loadProfile() async {
    if (isLoading) return; //반복요청대비

    isLoading = true;
    errorMessage = null; //다른곳에서참조할수도있으니확실하게지정해주는게좋음
    notifyListeners(); //로딩인디케이터표시를위함

    try {
      profile = await _repository.fetchProfile();
      _keywordIds = await _repository.fetchUserKeywordIds();
    } catch (e) {
      errorMessage = e.toString(); //e는String임
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
