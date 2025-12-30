import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bidbird/core/config/firebase_config.dart';
import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/router/app_router.dart';
import 'package:bidbird/core/services/datasource_manager.dart';
import 'package:bidbird/features/bid/domain/entities/item_bid_win_entity.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

class FirebaseManager {
  static final FirebaseManager _shared = FirebaseManager();
  static FirebaseManager get shared => _shared;

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  FirebaseMessaging get fcm => _fcm;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // FCM 토큰 변경 감지용
  static String? _lastSavedToken;
  static StreamSubscription? _tokenRefreshSubscription;

  static String? _webVapidKey() {
    if (!kIsWeb) return null;
    return FirebaseConfig.webVapidKey;
  }

  Future<String?> getFcmToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken(
      vapidKey: _webVapidKey(),
    );
    return fcmToken;
  }

  static Future<void> initialize() async {
    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        return;
      }

      // iOS 포그라운드 알림 표시 설정 (iOS에서 포그라운드 알림 팝업을 띄우기 위해 필수)
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _initializeLocalNotifications();
      // 알림 채널 설정(안드로이드만인가??)
      await _createStaticChannels();
      await _setupIOSCategories();
      await _setupFCMToken();
      _setupMessageHandlers();
    } catch (e) {
      debugPrint('PushNotificationService 초기화 실패: $e');
    }
  }

  //  기본 설정
  static Future<void> _initializeLocalNotifications() async {
    // 안드로이드 설정
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // AndroidInitializationSettings('@mipmap/ic_launcher');
    // ios 설정
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    // 시작 세팅 ( AOS + IOS)
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      //onDidReceiveNotificationResponse가 뭐지?
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      const AndroidNotificationChannel defaultChannel =
          AndroidNotificationChannel(
            'high_importance_channel',
            'High Importance Notifications',
            description: 'This channel is used for important notifications.',
            importance: Importance.high,
          );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(defaultChannel);
    }
  }

  //========================================= 채널 관련 시작=================================================
  // 알림 채널 설정(안드로이드만인가??)
  static Future<void> _createStaticChannels() async {
    if (!Platform.isAndroid) return;

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    const generalChannel = AndroidNotificationChannel(
      'general_channel',
      '일반 알림',
      description: '일반적인 알림을 위한 채널입니다.',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    const AndroidNotificationChannel fcmChannel = AndroidNotificationChannel(
      'fcm_notification_channel',
      '일반 알림',
      description: '포그라운드 FCM 알림용 채널입니다.',
      importance: Importance.max,
      playSound: true,
    );

    await androidPlugin.createNotificationChannel(generalChannel);
    await androidPlugin.createNotificationChannel(fcmChannel);
  }

  // 모르겠음 이건 뭐지......
  static Future<void> _setupIOSCategories() async {
    if (!Platform.isIOS) return;
  }
  //========================================= 채널 관련 끝==================================================

  //=====================================================================================================
  // FCM 토큰 관련
  static Future<void> _setupFCMToken() async {
    try {
      String? token = await _fcm.getToken(vapidKey: _webVapidKey());
      if (token != null) {
        // fcm 토큰 supabase에 저장하기
        await saveTokenToSupabase(token);
      }
      // 토큰이 갱신될 시 토큰 값을 다시 업데이트하기
      _fcm.onTokenRefresh.listen((newToken) {
        saveTokenToSupabase(newToken);
      });
    } catch (e) {
      debugPrint('FCM 토큰 가져오기 실패: $e');
    }
  }

  // 로그인 상태 리스너에 넣어놨음.
  static Future<void> setupFCMTokenAtLogin() async {
    try {
      String? token = await _fcm.getToken(vapidKey: _webVapidKey());
      if (token != null) {
        // 이전 토큰과 다를 때만 저장 -> 로그인 시에는 강제 저장
        await saveTokenToSupabase(token, force: true);
      }

      // 기존 리스너 취소 (중복 등록 방지)
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;

      // 토큰이 갱신될 시에만 업데이트
      _tokenRefreshSubscription = _fcm.onTokenRefresh.listen((newToken) {
        saveTokenToSupabase(newToken);
      });
    } catch (e) {
      debugPrint('FCM 토큰 가져오기 실패: $e');
    }
  }

  // fcm 토큰 supabase에 저장하기 (토큰 변경 시에만)
  static Future<void> saveTokenToSupabase(
    String token, {
    bool force = false,
  }) async {
    try {
      // 토큰이 변경되지 않았으면 저장하지 않음 (force가 true면 무시하고 저장)
      if (!force && token == _lastSavedToken) {
        return;
      }

      final userId = SupabaseManager.shared.supabase.auth.currentUser?.id;
      if (userId == null) {
        return;
      }

      String platform;
      if (kIsWeb) {
        platform = 'web';
      } else if (Platform.isIOS) {
        platform = 'ios';
      } else if (Platform.isAndroid) {
        platform = 'android';
      } else {
        platform = 'unknown';
      }

      print(platform);
      // TODO 테이블에 맞게 수정하기
      await SupabaseManager.shared.supabase
          .from('users')
          .update({'device_token': token, 'device_type': platform})
          .eq('id', userId);

      // 저장 성공 시 이전 토큰 업데이트
      _lastSavedToken = token;
    } catch (e) {
      debugPrint('FCM 토큰 저장 실패: $e');
    }
  }

  static void clearTokenCache() {
    _lastSavedToken = null;
  }
  // ================================================================================

  // ====================================리스너 =======================================

  static void _setupMessageHandlers() {
    print('=== _setupMessageHandlers START ===');
    // // 앱 접속중
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    //   if (message.notification != null) {
    //     // await _showLocalNotification(message);
    //   }
    // });

    //포그라운드 메시지 (앱 실행 중)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('=== FOREGROUND MESSAGE RECEIVED ===');

      sendLocalPushFromFCM(message);
    });

    // 푸시알림
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // 앱이 완전히 종료(Terminated) 상태일 때 알림을 탭하면 메시지를 가져옴
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('=== INITIAL MESSAGE (TERMINATED) ===');
        // handleRemoteMessageRouting(message);
        _handleNotificationTap(message);
      }
    });
  }

  // FCM 메시지를 받아 로컬 푸시
  static Future<void> sendLocalPushFromFCM(RemoteMessage message) async {
    final Map<String, dynamic> fcmData = message.data;

    final String title = message.notification?.title ?? "새로운 알림";
    final String body = message.notification?.body ?? "알림 내용";

    //데이터 파싱
    final String payloadString = jsonEncode(fcmData);

    NotificationDetails details = const NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      android: AndroidNotificationDetails(
        // 채널 ID는 FCM과 Local Notification이 동일한 채널을 사용하도록 일관성 있게 유지하는 것이 좋음
        'fcm_notification_channel',
        '일반 알림',
        channelDescription: "새로운 알림 및 업데이트", //채널설명
        importance: Importance.max, //중요도
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _localNotifications.show(
      // 알림 ID는 고유해야 하기때문에 데이터베이스의 alarm_id를 사용
      int.tryParse(fcmData['alarm_id'] ?? '1') ?? 1,
      title,
      body,
      details,
      payload: payloadString,
    );

    print('로컬알림 발송. 데이터: $payloadString');
  }

  static Future<void> _markAlarmCheckedIfNeeded(
    Map<String, dynamic> data,
  ) async {
    final alarmType = data['alarm_type']?.toString() ?? 'UNKNOWN';

    // 채팅은 알림 테이블 읽음처리 X
    if (alarmType == 'NEW_CHAT') return;

    final alarmId = data['alarm_id']?.toString();
    if (alarmId == null || alarmId.isEmpty) return;

    await SupabaseManager.shared.supabase
        .from('alarm')
        .update({'is_checked': true})
        .eq('id', alarmId); // ✅ uuid 그대로
  }

  static Future<void> _onNotificationTapped(
    NotificationResponse notificationResponse,
  ) async {
    // Deep linking 처리 필요시 구현
    final String? payload = notificationResponse.payload;

    if (payload != null && payload.isNotEmpty) {
      try {
        //데이터 파싱
        final Map<String, dynamic> fcmData = jsonDecode(payload);

        final String alarmType = fcmData['alarm_type'] ?? 'UNKNOWN';

        //alarm_id, post_id, friend_id 등의 정보를 포함한 최종 라우트 생성
        //안드로이드에서 로컬푸시생성시 반드시 고유한 아이디가 필요해서 alarm테이블의 기본키를 사용할것
        await _markAlarmCheckedIfNeeded(fcmData);
        final String targetRoute = _generateRoute(alarmType, fcmData);

        if (alarmType == "WIN") {
          final String? itemId = fcmData['item_id'] as String;
          if (itemId == null) return;
          final ItemDetail? item = await DatasourceManager().itemDetail
              .fetchItemDetail(itemId);
          if (item == null) {
            rootNavigatorKey.currentContext?.push(targetRoute);
            return;
          }
          ItemBidWinEntity itemBidWinEntity = ItemBidWinEntity.fromItemDetail(
            item,
          );
          rootNavigatorKey.currentContext?.push(
            targetRoute,
            extra: itemBidWinEntity,
          );
          print('FCM 탭으로 라우팅 성공: $targetRoute');
        } else {
          rootNavigatorKey.currentContext?.push(targetRoute);
          print('FCM 탭으로 라우팅 성공: $targetRoute');
        }

        print('알림탭. 경로: $targetRoute');
      } catch (e) {
        print('알림처리중 에러: $e');
      }
    }
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    final fcmData = message.data;
    // Deep linking 처리 필요시 구현
    final String alarmType = fcmData['alarm_type']?.toString() ?? 'UNKNOWN';

    // _generateRoute 함수를 사용하여 알림 타입과 데이터에 맞는 라우팅 경로 생성
    await _markAlarmCheckedIfNeeded(fcmData);
    final String targetRoute = _generateRoute(alarmType, fcmData);
    if (alarmType == "WIN") {
      final String? itemId = fcmData['item_id'] as String;
      if (itemId == null) return;
      final ItemDetail? item = await DatasourceManager().itemDetail
          .fetchItemDetail(itemId);
      if (item == null) {
        rootNavigatorKey.currentContext?.push(targetRoute);
        return;
      }
      ItemBidWinEntity itemBidWinEntity = ItemBidWinEntity.fromItemDetail(item);
      rootNavigatorKey.currentContext?.push(
        targetRoute,
        extra: itemBidWinEntity,
      );
      print('FCM 탭으로 라우팅 성공: $targetRoute');
    } else {
      rootNavigatorKey.currentContext?.push(targetRoute);
      print('FCM 탭으로 라우팅 성공: $targetRoute');
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _fcm.getToken(vapidKey: _webVapidKey());
    } catch (e) {
      debugPrint('FCM 토큰 가져오기 실패: $e');
      return null;
    }
  }

  // 매세지 컨트롤
  static Future<void> handleInitialMessage() async {
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static String _generateRoute(
    String alarmType,
    Map<String, dynamic> deepLinkData,
  ) {
    switch (alarmType) {
      case 'NEW_CHAT':
        // 친구 요청 페이지나 알림 목록 페이지로 이동
        final String itemId = deepLinkData['item_id']?.toString() ?? '0';
        final String roomId = deepLinkData['room_id']?.toString() ?? '0';
        return '/chat/room?itemId=$itemId&roomId=$roomId';
      case 'AUCTION_START':
        final String itemId = deepLinkData['item_id']?.toString() ?? '0';
        return '/item/${itemId}';
      case 'BID_SUCCESS':
        final String itemId = deepLinkData['item_id']?.toString() ?? '0';
        return '/item/${itemId}';
      case 'BID':
        final String itemId = deepLinkData['item_id']?.toString() ?? '0';
        return '/item/${itemId}';
      case 'OUTBID':
        final String itemId = deepLinkData['item_id']?.toString() ?? '0';
        return '/item/${itemId}';
      case 'WIN':
        // 결제 화면으로
        return '/item_bid_win';
      case 'AUCTION_END_SUCCESS':
        final String itemId = deepLinkData['item_id']?.toString() ?? '0';
        return '/item/${itemId}';
      // 유찰 화면
      case 'AUCTION_FAILED':
        final String itemId = deepLinkData['item_id']?.toString() ?? '0';
        return '/item/${itemId}/relist';
      // 결제 완료 푸시 알림
      case 'PAID_SUCCESS':
        final String itemId = deepLinkData['item_id']?.toString() ?? '0';
        return '/item/${itemId}';
      // 구매 확정 요구 알림
      case 'PURCHASE_CONFIRM_REQUEST':
        final String itemId = deepLinkData['item_id']?.toString() ?? '0';
        return '/item/${itemId}';
      // 자동 구매 확정 알림(구매자에게)
      case 'PURCHASE_AUTO_CONFIRMED':
        final String itemId = deepLinkData['item_id']?.toString() ?? '0';
        return '/item/${itemId}';
      // 구매 확정 알림(판매자에게)
      case 'PURCHASE_CONFIRMED':
        final String itemId = deepLinkData['item_id']?.toString() ?? '0';
        return '/item/${itemId}';
      // 구매 거부 알림(구매자 판매자에게 공통으로)
      case 'PURCHASE_REJECTED':
        final String itemId = deepLinkData['item_id']?.toString() ?? '0';
        return '/item/${itemId}';
      default:
        return '/home';
    }
  }
}
