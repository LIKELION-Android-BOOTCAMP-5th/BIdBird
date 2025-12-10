import 'dart:io';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseManager {
  static final FirebaseManager _shared = FirebaseManager();
  static FirebaseManager get shared => _shared;

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  FirebaseMessaging get fcm => _fcm;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<String?> getFcmToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken(
      vapidKey:
          "BBMVGr2Cf0iITb26AyO-7tzN7HmpHjJQpoYIX-DSvlHvL9b40mV9zkPtiFi1fzs7upnZO-4CErbhLI4bRO6TfAA",
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

      await _initializeLocalNotifications();
      await _createStaticChannels();
      await _setupIOSCategories();
      await _setupFCMToken();
      _setupMessageHandlers();
    } catch (e) {
      debugPrint('PushNotificationService 초기화 실패: $e');
    }
  }

  //
  static Future<void> _initializeLocalNotifications() async {
    // 안드로이드 설정
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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

    const commentChannel = AndroidNotificationChannel(
      'comment_channel',
      '댓글 알림',
      description: '댓글이 달렸을 때 알림을 받습니다.',
      importance: Importance.high,
      playSound: true,
    );

    const likeChannel = AndroidNotificationChannel(
      'like_channel',
      '좋아요 알림',
      description: '좋아요를 받았을 때 알림을 받습니다.',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    const announcementChannel = AndroidNotificationChannel(
      'announcement_channel',
      '공지사항',
      description: '중요한 공지사항을 받습니다.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const followChannel = AndroidNotificationChannel(
      'follow_channel',
      '팔로우 알림',
      description: '새로운 팔로워 알림을 받습니다.',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    const postChannel = AndroidNotificationChannel(
      'post_channel',
      '게시글 알림',
      description: '게시글 관련 알림을 받습니다.',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    const messageChannel = AndroidNotificationChannel(
      'message_channel',
      '메시지 알림',
      description: '메시지 알림을 받습니다.',
      importance: Importance.high,
      playSound: true,
    );

    await androidPlugin.createNotificationChannel(generalChannel);
    await androidPlugin.createNotificationChannel(commentChannel);
    await androidPlugin.createNotificationChannel(likeChannel);
    await androidPlugin.createNotificationChannel(announcementChannel);
    await androidPlugin.createNotificationChannel(followChannel);
    await androidPlugin.createNotificationChannel(postChannel);
    await androidPlugin.createNotificationChannel(messageChannel);
  }

  static Future<String> createChatRoomChannel(String roomId) async {
    if (!Platform.isAndroid) return 'chat_room_$roomId';

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return 'chat_room_$roomId';

    final channelId = 'chat_room_$roomId';

    final channel = AndroidNotificationChannel(
      channelId,
      '채팅 알림',
      description: '채팅방 메시지 알림을 받습니다.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await androidPlugin.createNotificationChannel(channel);
    return channelId;
  }

  // 모르겠음 이건 뭐지......
  static Future<void> _setupIOSCategories() async {
    if (!Platform.isIOS) return;
  }

  static Future<void> _setupFCMToken() async {
    try {
      String? token = await _fcm.getToken(
        vapidKey:
            "BBMVGr2Cf0iITb26AyO-7tzN7HmpHjJQpoYIX-DSvlHvL9b40mV9zkPtiFi1fzs7upnZO-4CErbhLI4bRO6TfAA",
      );
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

  // 로그인떄 사용할 생각
  static Future<void> setupFCMTokenAtLogin() async {
    try {
      String? token = await _fcm.getToken(
        vapidKey:
            "BBMVGr2Cf0iITb26AyO-7tzN7HmpHjJQpoYIX-DSvlHvL9b40mV9zkPtiFi1fzs7upnZO-4CErbhLI4bRO6TfAA",
      );
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

  // fcm 토큰 supabase에 저장하기
  static Future<void> saveTokenToSupabase(String token) async {
    try {
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
    } catch (e) {
      debugPrint('FCM 토큰 저장 실패: $e');
    }
  }

  static void _setupMessageHandlers() {
    // 앱 접속중
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.notification != null) {
        await _showLocalNotification(message);
      }
    });
    // 푸시알림
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    AndroidNotificationDetails? androidDetails;
    DarwinNotificationDetails? iosDetails;

    if (Platform.isAndroid) {
      final channelId =
          message.data['channelId'] ??
          _getChannelFromNotificationType(message.data['type']) ??
          'general_channel';

      androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
    }

    if (Platform.isIOS) {
      iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
    }

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  // TODO : 채널 타입 설정
  static String? _getChannelFromNotificationType(String? type) {
    if (type == null) return null;

    const channelMap = {
      'comment': 'comment_channel',
      'like': 'like_channel',
      'follow': 'follow_channel',
      'message': 'message_channel',
      'chat': 'message_channel',
      'post': 'post_channel',
      'announcement': 'announcement_channel',
    };

    return channelMap[type];
  }

  // TODO : 채널 이름 설정
  static String _getChannelName(String channelId) {
    const channelNames = {
      'general_channel': '일반 알림',
      'comment_channel': '댓글 알림',
      'like_channel': '좋아요 알림',
      'announcement_channel': '공지사항',
      'follow_channel': '팔로우 알림',
      'post_channel': '게시글 알림',
      'message_channel': '메시지 알림',
      'high_importance_channel': 'High Importance Notifications',
    };

    if (channelId.startsWith('chat_room_')) {
      return '채팅 알림';
    }

    return channelNames[channelId] ?? '알림';
  }

  static String _getChannelDescription(String channelId) {
    // 동적 채널
    if (channelId.startsWith('chat_room_')) {
      return '채팅방 메시지 알림을 받습니다.';
    }
    // 정적 채널
    const descriptions = {
      'general_channel': '일반적인 알림을 위한 채널입니다.',
      'comment_channel': '댓글이 달렸을 때 알림을 받습니다.',
      'like_channel': '좋아요를 받았을 때 알림을 받습니다.',
      'announcement_channel': '중요한 공지사항을 받습니다.',
      'follow_channel': '새로운 팔로워 알림을 받습니다.',
      'post_channel': '게시글 관련 알림을 받습니다.',
      'message_channel': '메시지 알림을 받습니다.',
    };
    // 없을 시 알림을 받습니다.
    return descriptions[channelId] ?? '알림을 받습니다.';
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Deep linking 처리 필요시 구현
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    // Deep linking 처리 필요시 구현
  }

  static Future<String?> getToken() async {
    try {
      return await _fcm.getToken(
        vapidKey:
            "BBMVGr2Cf0iITb26AyO-7tzN7HmpHjJQpoYIX-DSvlHvL9b40mV9zkPtiFi1fzs7upnZO-4CErbhLI4bRO6TfAA",
      );
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
}
