import 'package:flutter/material.dart';

import '../data/profile_repository.dart';

class Profile {
  final String id;
  final String? name;
  final String? phoneNumber;
  final String? profileImageUrl;

  Profile({
    required this.id,
    this.name,
    this.phoneNumber,
    this.profileImageUrl,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      name: map['name'] as String?,
      phoneNumber: map['phone'] as String?,
      profileImageUrl: map['profile_image'] as String?,
    );
  }
}

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;

  Profile? profile;
  bool isLoading = false;

  String? lastErrorMessage; //나중에팝업으로쓸것

  ProfileViewModel(this._repository);

  Future<void> loadProfile() async {
    if (isLoading) return;

    isLoading = true;
    notifyListeners();

    try {
      profile = await _repository.fetchCurrentProfile();
    } catch (e) {
      lastErrorMessage = e.toString(); //e는String임
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
