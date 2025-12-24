import 'dart:async';

import 'package:bidbird/core/utils/event_bus/login_event_bus.dart';
import 'package:bidbird/main.dart';
import 'package:flutter/material.dart';

import '../domain/entities/profile_entity.dart';
import '../domain/usecases/get_profile.dart';

class ProfileViewModel extends ChangeNotifier {
  final GetProfile _getProfile;
  StreamSubscription? _loginSubscription;

  ProfileEntity? profile;
  bool isLoading = false;

  String? errorMessage; //나중에팝업으로쓸것

  ProfileViewModel(this._getProfile) {
    loadProfile(); //생성자에서 쵸기로딩 // main에서 ..loadProfile()하지 않아도 됨
    _loginSubscription = eventBus.on<LoginEventBus>().listen((event) {
      if (event.type == LoginEventType.logout) {
        profile = null;
        errorMessage = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadProfile() async {
    if (isLoading) return; //반복요청대비

    isLoading = true;
    errorMessage = null; //다른곳에서참조할수도있으니확실하게지정해주는게좋음
    notifyListeners(); //로딩인디케이터표시를위함

    try {
      profile = await _getProfile();
    } catch (e) {
      errorMessage = e.toString(); //e는String임
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _loginSubscription?.cancel();
    super.dispose();
  }
}
