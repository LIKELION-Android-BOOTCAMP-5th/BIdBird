import 'package:bidbird/core/config/supabase_config.dart';
import 'package:bidbird/core/config/firebase_config.dart';



import 'dart:async';

import 'package:bidbird/core/managers/firebase_manager.dart';
import 'package:bidbird/core/managers/firebase_options.dart';
import 'package:cloudinary_flutter/cloudinary_object.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter/widgets.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:bidbird/core/utils/secure_local_storage.dart';

class AppInitializer {
  static Future<void>? _initFuture;
  static Future<void>? _firebaseInitFuture;
  static bool _postInitStarted = false;

  static Future<void> ensureInitialized() {
    _initFuture ??= _initialize();
    return _initFuture!;
  }

  static Future<void> _initialize() async {
    CloudinaryObject.fromCloudName(cloudName: 'dn12so6sm');


    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: SecureLocalStorage(),
      ),
    );


    // Firebase 설정 로드
    await FirebaseConfig.initialize();

    // 카카오 로그인 초기화
    KakaoSdk.init(
      nativeAppKey: FirebaseConfig.kakaoNativeAppKey,
      javaScriptAppKey: FirebaseConfig.kakaoJavaScriptAppKey,
    );

    // Nhost & GraphQL Hive 초기화
    await initHiveForFlutter();

    _firebaseInitFuture ??= Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );


    unawaited(
      _firebaseInitFuture!.catchError((e) {
        debugPrint('Firebase initialization failed: $e');
      }),
    );
  }

  static void startPostInitTasks() {
    if (_postInitStarted) return;
    _postInitStarted = true;

    _firebaseInitFuture ??= Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // FCM 초기화는 한 번만 시도 (재시도 로직 제거로 부팅 속도 개선)
    unawaited(_initFcmOnce());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        Future(() async {
          await Future.wait([
            () async {
              try {
                await _firebaseInitFuture;
                await FirebaseManager.shared.fcm.requestPermission(
                  provisional: true,
                );
              } catch (e) {
                debugPrint('FCM permission request failed: $e');
              }
            }(),
            () async {
              try {
                await initializeDateFormatting('ko', null);
              } catch (e) {
                debugPrint('Date formatting initialization failed: $e');
              }
            }(),
          ]);
        }),
      );
    });
  }

  static Future<void> _initFcmOnce() async {
    try {
      await _firebaseInitFuture;
      final fcmToken = await FirebaseManager.shared.getFcmToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        debugPrint('fcm 토큰 : $fcmToken');
        await FirebaseManager.initialize();
      }
    } catch (e) {
      debugPrint('푸시 알림 서비스 초기화 실패: $e');
    }
  }
}
