import 'package:flutter/material.dart';

import '../data/datasource/user_profile_datasource.dart';
import '../model/user_profile_entity.dart';

class UserProfileViewModel extends ChangeNotifier {
  UserProfileViewModel({UserProfileDatasource? datasource})
      : _datasource = datasource ?? UserProfileDatasource();

  final UserProfileDatasource _datasource;

  UserProfile? _profile;

  UserProfile? get profile => _profile;

  Future<void> loadProfile(String userId) async {
    _profile = await _datasource.fetchUserProfile(userId);
    notifyListeners();
  }
}
