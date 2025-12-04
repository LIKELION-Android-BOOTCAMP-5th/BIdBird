import 'package:flutter/material.dart';

import '../data/repository/user_profile_repository.dart';
import '../model/user_profile_entity.dart';

class UserProfileViewModel extends ChangeNotifier {
  UserProfileViewModel({UserProfileRepository? repository})
      : _repository = repository ?? UserProfileRepository();

  final UserProfileRepository _repository;

  UserProfile? _profile;

  UserProfile? get profile => _profile;

  Future<void> loadProfile(String userId) async {
    _profile = await _repository.fetchUserProfile(userId);
    notifyListeners();
  }
}
