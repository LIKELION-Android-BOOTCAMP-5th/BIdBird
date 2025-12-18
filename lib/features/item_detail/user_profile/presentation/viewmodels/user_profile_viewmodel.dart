import 'package:flutter/material.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/usecases/fetch_user_profile_usecase.dart';
import '../../data/repositories/user_profile_repository.dart';

class UserProfileViewModel extends ChangeNotifier {
  UserProfileViewModel({FetchUserProfileUseCase? fetchUserProfileUseCase})
      : _fetchUserProfileUseCase =
            fetchUserProfileUseCase ?? FetchUserProfileUseCase(UserProfileRepositoryImpl());

  final FetchUserProfileUseCase _fetchUserProfileUseCase;

  UserProfile? _profile;

  UserProfile? get profile => _profile;

  Future<void> loadProfile(String userId) async {
    _profile = await _fetchUserProfileUseCase(userId);
    notifyListeners();
  }
}



