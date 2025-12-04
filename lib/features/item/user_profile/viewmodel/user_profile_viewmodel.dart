import 'package:bidbird/features/item/user_profile/data/datasource/user_profile_data.dart';
import 'package:flutter/material.dart';

class UserProfileViewModel extends ChangeNotifier {
  UserProfile? _profile;

  UserProfile? get profile => _profile;

  Future<void> loadProfile(String userId) async {
    // TODO: 실제 API 연동 시 userId 기반으로 데이터 조회
    await Future.delayed(const Duration(milliseconds: 200));
    _profile = dummyUserProfile;
    notifyListeners();
  }
}
