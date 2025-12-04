import 'package:flutter/material.dart';

import '../data/profile_repository.dart';

class Profile {
  final String id;
  final String? nickName;
  final String? phoneNumber;
  final String? profileImageUrl;

  Profile({
    required this.id,
    this.nickName,
    this.phoneNumber,
    this.profileImageUrl,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      nickName: map['nick_name'] as String?,
      phoneNumber: map['phone_number'] as String?,
      profileImageUrl: map['profile_image'] as String?,
    );
  }
}

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;

  Profile? profile;
  bool isLoading = false;

  String? errorMessage; //나중에팝업으로쓸것

  ProfileViewModel(this._repository) {
    loadProfile(); //쵸기로딩
  }

  Future<void> loadProfile() async {
    if (isLoading) return; //반복요청대비

    isLoading = true;
    errorMessage = null; //다른곳에서참조할수도있으니확실하게지정해주는게좋음
    notifyListeners(); //로딩인디케이터표시를위함

    try {
      profile = await _repository.fetchProfile();
    } catch (e) {
      errorMessage = e.toString(); //e는String임
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
