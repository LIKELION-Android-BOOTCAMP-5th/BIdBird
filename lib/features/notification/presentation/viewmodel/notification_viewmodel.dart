// 뷰모델 역할
// 화면의 상테 저장(데이터 변경시 화면을 다시 그리라고 notifyListeners()를 사용

//

//이것은 복붙용입니다. 혹시 몰라서 아직은 삭제하지 않으나 곧 삭제할 예정입니다.
import 'dart:async';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/event_bus/login_event_bus.dart';
import 'package:bidbird/features/notification/data/managers/notification_list_realtime_subscription_manager.dart';
import 'package:bidbird/features/notification/data/repositories/notification_repository.dart';
import 'package:bidbird/features/notification/domain/entities/notification_entity.dart';
import 'package:bidbird/features/notification/domain/usecases/check_all_notification_usecase.dart';
import 'package:bidbird/features/notification/domain/usecases/check_notification_usecase.dart';
import 'package:bidbird/features/notification/domain/usecases/delete_all_notification_usecase.dart';
import 'package:bidbird/features/notification/domain/usecases/delete_notification_usecase.dart';
import 'package:bidbird/features/notification/domain/usecases/fetch_notification_usecase.dart';
import 'package:bidbird/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationViewmodel extends ChangeNotifier {
  // Manager 클래스들
  late final NotificationListRealtimeSubscriptionManager
  _notificationListRealtimeSubscriptionManager =
      NotificationListRealtimeSubscriptionManager();

  ///useCases
  final FetchNotificationUseCase _fetchNotificationUseCase;
  final CheckAllNotificationUseCase _checkAllNotificationUseCase;
  final CheckNotificationUseCase _checkNotificationUseCase;
  final DeleteAllNotificationUseCase _deleteAllNotificationUseCase;
  final DeleteNotificationUseCase _deleteNotificationUseCase;
  late final StreamSubscription<AuthState> _authSub;
  StreamSubscription? _loginSubscription;
  List<NotificationEntity> notifyList = [];
  final List<String> toItemDetail = [
    "BID",
    "OUTBID",
    "AUCTION_START",
    "AUCTION_END_SUCCESS",
    "AUCTION_FAILED",
    "PAID_SUCCESS",
    "PURCHASE_CONFIRM_REQUEST",
    "PURCHASE_AUTO_CONFIRMED",
    "PURCHASE_CONFIRMED",
    "PURCHASE_REJECTED",
    "BID_SUCCESS",
  ];

  DateTime? _lastPausedAt;
  bool _isFetching = false; // 중복 요청 방지 플래그

  int get unCheckedCount =>
      notifyList.where((e) => e.is_checked == false).length;
  // int inputCount = 0;

  // final TextEditingController textEditingController = TextEditingController();

  // 뷰모델 생성자, context를 통해 리포지토리를 받아올 수 있음.
  NotificationViewmodel(
    BuildContext context, {
    FetchNotificationUseCase? fetchNotificationUseCase,
    CheckAllNotificationUseCase? checkAllNotificationUseCase,
    CheckNotificationUseCase? checkNotificationUseCase,
    DeleteAllNotificationUseCase? deleteAllNotificationUseCase,
    DeleteNotificationUseCase? deleteNotificationUseCase,
  }) : _fetchNotificationUseCase =
           fetchNotificationUseCase ??
           FetchNotificationUseCase(NotificationRepositoryImpl()),
       _checkAllNotificationUseCase =
           checkAllNotificationUseCase ??
           CheckAllNotificationUseCase(NotificationRepositoryImpl()),
       _checkNotificationUseCase =
           checkNotificationUseCase ??
           CheckNotificationUseCase(NotificationRepositoryImpl()),
       _deleteAllNotificationUseCase =
           deleteAllNotificationUseCase ??
           DeleteAllNotificationUseCase(NotificationRepositoryImpl()),
       _deleteNotificationUseCase =
           deleteNotificationUseCase ??
           DeleteNotificationUseCase(NotificationRepositoryImpl()) {
    _bootstrap();
    _loginSubscription = eventBus.on<LoginEventBus>().listen((event) {
      if (SupabaseManager.shared.supabase.auth.currentUser?.id == null) {
        cancelRealtimeSubscription();
        resetNotifyList();
      } else {
        resetNotifyList();
        fetchNotify();
        setupRealtimeSubscription();
      }
    });
  }

  void removeNotificationLocally(String id) {
    notifyList.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // 중복 fetch 방지를 위한 래퍼 메서드
  Future<void> _safelyFetchNotify() async {
    if (_isFetching) return;
    await fetchNotify();
  }

  Future<void> _bootstrap() async {
    final userId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _safelyFetchNotify(); // ✅ 중복 방지하며 1회 보장
    setupRealtimeSubscription(); // ✅ 이후 실시간
  }

  void onAppPaused() {
    _lastPausedAt = DateTime.now();
  }

  Future<void> onAppResumed() async {
    final now = DateTime.now();
    final wasDisconnected =
        !_notificationListRealtimeSubscriptionManager.isConnected;

    if (wasDisconnected) {
      debugPrint('🔄 Realtime was disconnected → full sync');
      await _safelyFetchNotify(); // 중복 fetch 방지
      setupRealtimeSubscription();
      return;
    }

    // ⏱️ 오래 백그라운드였으면 보정
    if (_lastPausedAt != null &&
        now.difference(_lastPausedAt!) > const Duration(minutes: 2)) {
      debugPrint('⏱️ Long background → full sync');
      await _safelyFetchNotify(); // 중복 fetch 방지
      return;
    }

    debugPrint('✅ Realtime alive → skip fetch');
  }

  void updateNotification(NotificationEntity notify) {
    notifyList.add(notify);
    sortNotifyList();
    notifyListeners();
  }

  void sortNotifyList() {
    notifyList.sort((a, b) {
      // 1️⃣ isChecked: false 먼저
      if (a.is_checked != b.is_checked) {
        return a.is_checked ? 1 : -1;
        // false → -1 (앞), true → 1 (뒤)
      }

      // 2️⃣ createdAt: 최신순
      return b.created_at.compareTo(a.created_at);
    });
  }

  Future<void> fetchNotify() async {
    if (_isFetching) return; // 중복 호출 방지

    _isFetching = true;
    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      print("로그인 상태가 아닙니다.");
      _isFetching = false;
      return;
    }
    try {
      notifyList = await _fetchNotificationUseCase();
    } catch (e) {
      print("알림 불러오기 실패했습니다 : $e");
    }
    sortNotifyList();
    notifyListeners();
    _isFetching = false;
  }

  Future<void> checkNotification(String id) async {
    final index = notifyList.indexWhere((e) => e.id == id);
    if (notifyList[index].is_checked == true) return;
    notifyList[index].is_checked = true;
    try {
      await _checkNotificationUseCase(id);
    } catch (e) {
      notifyList[index].is_checked = false;
      print("알림 확인 업데이트 실패했습니다 : $e");
    }
    notifyListeners();
  }

  Future<void> checkAllNotification() async {
    try {
      await _checkAllNotificationUseCase();
    } catch (e) {
      print("알림 확인 업데이트 실패했습니다 : $e");
    }
    await fetchNotify();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _deleteNotificationUseCase(id);
    } catch (e) {
      print("알림 삭제에 실패했습니다 : $e");
    }
    notifyListeners();
  }

  Future<void> deleteAllNotification() async {
    try {
      await _deleteAllNotificationUseCase();
    } catch (e) {
      print("알림 전체 삭제에 실패했습니다 : $e");
    }
    await fetchNotify();
    notifyListeners();
  }

  void resetNotifyList() {
    notifyList = [];
    notifyListeners();
  }

  void setupRealtimeSubscription() {
    _notificationListRealtimeSubscriptionManager.setupRealtimeSubscription(
      updateNotification: updateNotification,
    );
  }

  void cancelRealtimeSubscription() {
    _notificationListRealtimeSubscriptionManager.closeSubscription();
    notifyList.clear(); // 로그아웃 시 이전 사용자의 알림 캐시 삭제
    print("로그아웃으로 알림 채널이 닫혔습니다");
  }

  @override
  void dispose() {
    _loginSubscription?.cancel();
    _notificationListRealtimeSubscriptionManager.closeSubscription();
    print("알림 채널이 닫혔습니다");
    super.dispose();
  }

  // 입력한 글자 수를 받아오는 함수
  // void handleTextInput(String input) {
  //   inputCount = input.length;
  //   notifyListeners();
  // }

  // Future 함수는 API나 Supabase, 메소드 채널과 사용할 때,
  // 처리를 하는데 시간이 걸리는 작업을 할때 사용됨.
  // 아래 함수 안 에서는 시간이 필요한 작업은 await를 사용 해야함
  // Future<void> function() async {
  //   try {
  //
  //   } catch (e) {
  //
  //   }
  //
  //   // 리빌딩, 리콤포지션 진행
  //   notifyListeners();
  // }
  // Future<void> function1() async {
  //   // 시간 지연 코드
  //   await Future.delayed(const Duration(milliseconds: 1700));
  //   notifyListeners();
  // }
}
