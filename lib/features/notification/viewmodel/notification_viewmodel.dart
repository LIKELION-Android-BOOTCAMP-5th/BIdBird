// 뷰모델 역할
// 화면의 상테 저장(데이터 변경시 화면을 다시 그리라고 notifyListeners()를 사용

//

//이것은 복붙용입니다. 혹시 몰라서 아직은 삭제하지 않으나 곧 삭제할 예정입니다.
import 'dart:async';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/event_bus/login_event_bus.dart';
import 'package:bidbird/features/notification/data/repositories/notification_repository.dart';
import 'package:bidbird/features/notification/model/notification_entity.dart';
import 'package:bidbird/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationViewmodel extends ChangeNotifier {
  NotificationRepository _repository = NotificationRepository();
  RealtimeChannel? _notifyChannel;
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
  ];
  int get unCheckedCount =>
      notifyList.where((e) => e.is_checked == false).length;
  // int inputCount = 0;

  // final TextEditingController textEditingController = TextEditingController();

  // 뷰모델 생성자, context를 통해 리포지토리를 받아올 수 있음.
  NotificationViewmodel(BuildContext context) {
    fetchNotify();
    setupRealtimeSubscription();
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
    final currentUserId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      print("로그인 상태가 아닙니다.");
      return;
    }
    try {
      notifyList = await _repository.fetchNotify(currentUserId);
    } catch (e) {
      print("알림 불러오기 실패했습니다 : $e");
    }
    sortNotifyList();
    notifyListeners();
  }

  Future<void> checkNotification(String id) async {
    final index = notifyList.indexWhere((e) => e.id == id);
    if (notifyList[index].is_checked == true) return;
    notifyList[index].is_checked = true;
    try {
      await _repository.checkNotification(id);
    } catch (e) {
      notifyList[index].is_checked = false;
      print("알림 확인 업데이트 실패했습니다 : $e");
    }
    notifyListeners();
  }

  Future<void> checkAllNotification() async {
    try {
      await _repository.checkAllNotification();
    } catch (e) {
      print("알림 확인 업데이트 실패했습니다 : $e");
    }
    await fetchNotify();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
    } catch (e) {
      print("알림 삭제에 실패했습니다 : $e");
    }
    notifyListeners();
  }

  Future<void> deleteAllNotification() async {
    try {
      await _repository.deleteAllNotification();
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
    final currentId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentId == null) return;
    if (_notifyChannel != null) return;
    _notifyChannel = SupabaseManager.shared.supabase.channel('notification');
    _notifyChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alarm',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentId,
          ),
          callback: (payload) {
            final newNotify = payload.newRecord;
            final NotificationEntity newNotification =
                NotificationEntity.fromJson(newNotify);
            notifyList.add(newNotification);
            sortNotifyList();
            notifyListeners();
          },
        )
        .subscribe();

    print("알림 채널이 연결 되었습니다");
  }

  void cancelRealtimeSubscription() {
    if (_notifyChannel != null)
      SupabaseManager.shared.supabase.removeChannel(_notifyChannel!);
    print("로그아웃으로 알림 채널이 닫혔습니다");
  }

  @override
  void dispose() {
    if (_notifyChannel != null)
      SupabaseManager.shared.supabase.removeChannel(_notifyChannel!);
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
