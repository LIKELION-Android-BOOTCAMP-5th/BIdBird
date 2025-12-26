import 'dart:async';

import 'package:bidbird/core/managers/firebase_manager.dart';
import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/models/user_entity.dart';
import 'package:bidbird/core/utils/event_bus/login_event_bus.dart';
import 'package:bidbird/main.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//사용자 상태 관리
enum AuthStatus {
  initializing, // 앱 시작 직후, 아직 로그인 여부 판단 중
  unauthenticated, // 앱 실행했는데 정보 X
  authenticated, // 앱 실행했는데 정보 O
}

class AuthViewModel extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initializing;
  AuthStatus get status => _status;

  bool get isLoggedIn => _status == AuthStatus.authenticated;
  bool _loginEventFired = false;

  UserEntity? _user;
  UserEntity? get user => _user;
  late StreamSubscription<AuthState> _subscription;

  //로그아웃 인디케이터 설정
  bool _isLoggingOut = false;
  bool get isLoggingOut => _isLoggingOut;

  Future<void> _loadUserAndSetupFCM(String userId) async {
    try {
      final fetchedUser = await SupabaseManager.shared
          .fetchUser(userId)
          .timeout(const Duration(seconds: 2));
      _user = fetchedUser;
    } catch (e) {
      debugPrint('[AuthVM] fetchUser failed (background): $e');
    }

    try {
      await FirebaseManager.setupFCMTokenAtLogin();
    } catch (e) {
      debugPrint('[AuthVM] setupFCMTokenAtLogin failed (background): $e');
    }

    notifyListeners();
  }

  AuthViewModel() {
    // Supabase 인증 상태 구독
    _subscription = SupabaseManager.shared.supabase.auth.onAuthStateChange
        .listen((data) {
          final session = data.session;

          if (session == null) {
            _user = null;
            _status = AuthStatus.unauthenticated;
            _loginEventFired = false;

            eventBus.fire(LoginEventBus(LoginEventType.logout));
            notifyListeners();
            return;
          }

          _status = AuthStatus.authenticated;
          notifyListeners();

          if (!_loginEventFired) {
            _loginEventFired = true;
            eventBus.fire(LoginEventBus(LoginEventType.login));
          }

          unawaited(_loadUserAndSetupFCM(session.user.id));
        });
  }

  Future<void> logout() async {
    if (_isLoggingOut) return;

    _isLoggingOut = true;
    notifyListeners(); // 🔄 인디케이터 표시

    try {
      await _performLogoutTasks();
      // ❗ 여기서 UI 상태 직접 변경하지 않음
      // Supabase signOut → onAuthStateChange가 처리
    } finally {
      _isLoggingOut = false;
      notifyListeners();
    }
  }

  Future<void> _performLogoutTasks() async {
    try {
      final googleSignIn = GoogleSignIn.instance;

      // Google 로그아웃 시도 (에러 무시)
      try {
        await googleSignIn.signOut();
        await googleSignIn.disconnect();
      } catch (e) {
        debugPrint('⚠️ Google logout error: $e');
      }

      try {
        final userId = SupabaseManager.shared.supabase.auth.currentUser?.id;
        if (userId != null) {
          await SupabaseManager.shared.supabase
              .from('users')
              .update({'device_token': '', 'device_type': 'logOut'})
              .eq('id', userId);
        }
      } catch (e) {
        debugPrint('FCM 초기화: $e');
      }

      // Supabase 세션 로그아웃
      await SupabaseManager.shared.supabase.auth.signOut();
    } catch (e) {
      debugPrint('⚠️ Logout failed: $e');
    }

    debugPrint('✅ Background logout completed');
  }

  //  Supabase 인증 상태 구독
  // StreamSubscription<AuthState> _subscribeAuthEvent() {
  //   return SupabaseManager.shared.supabase.auth.onAuthStateChange.listen((
  //     data,
  //   ) async {
  //     final AuthChangeEvent event = data.event;
  //     final Session? session = data.session;
  //
  //     _isLoggedIn = session != null;
  //     if (_isLoggedIn && session != null) {
  //       // 인증 상태 변경 시 사용자 정보 가져오기
  //       _user = await SupabaseManager.shared.fetchUser(session.user.id);
  //       await FirebaseManager.setupFCMTokenAtLogin();
  //     }
  //     eventBus.fire(LoginEventBus());
  //     notifyListeners();
  //
  //     debugPrint('[AuthVM] event: $event, session: $session');
  //   });
  // }

  //  추가된 함수: 최신 사용자 정보를 수동으로 가져와 갱신
  Future<void> fetchUser() async {
    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      debugPrint('[AuthVM] fetchUser: Current user is null.');
      _user = null;
      notifyListeners();
      return;
    }

    try {
      // SupabaseManager의 fetchUser를 재사용하여 최신 프로필 정보 갱신
      _user = await SupabaseManager.shared.fetchUser(currentUserId);
      debugPrint(
        '[AuthVM] fetchUser: User profile updated (nick_name: ${_user?.nick_name})',
      );
    } catch (e) {
      debugPrint('[AuthVM] fetchUser failed to update user profile: $e');
      // 갱신 실패 시 _user는 기존 값을 유지하거나 null로 처리할 수 있습니다.
      // 여기서는 갱신 실패하더라도 현재 _user 값을 유지합니다.
    }

    // GoRouter 리디렉션 로직이 사용자 갱신을 감지하도록 notifyListeners 호출
    notifyListeners();
  }

  // splash 앱 시작 시 사용자 정보 관리
  Future<void> initialize() async {
    _status = AuthStatus.initializing;
    notifyListeners();

    final session = SupabaseManager.shared.supabase.auth.currentSession;

    if (session == null) {
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    _status = AuthStatus.authenticated;
    notifyListeners();
    unawaited(_loadUserAndSetupFCM(session.user.id));
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
