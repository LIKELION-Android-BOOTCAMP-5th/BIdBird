import 'dart:async';

import 'package:bidbird/core/managers/firebase_manager.dart';
import 'package:bidbird/core/managers/firebase_options.dart';
import 'package:bidbird/core/router/app_router.dart';
import 'package:bidbird/features/auth/viewmodel/auth_view_model.dart';
import 'package:bidbird/features/mypage/data/profile_repository.dart';
import 'package:bidbird/features/mypage/viewmodel/profile_viewmodel.dart';
import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:event_bus/event_bus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/feed/data/repository/home_repository.dart';

EventBus eventBus = EventBus();

class SupabaseConfig {
  static const String url = 'https://mdwelwjletorehxsptqa.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kd2Vsd2psZXRvcmVoeHNwdHFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQyOTEwNzksImV4cCI6MjA3OTg2NzA3OX0.tpCDNi74KoMcpr3BN7D6fT2SxsteCM9sf7RrEwnVPHg';
}

void main() async {
  // 1. 초기화는 한 번만!
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 초기화
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Cloudinary 초기화
  CloudinaryContext.cloudinary = Cloudinary.fromCloudName(
    cloudName: 'dn12so6sm',
  );

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // FCM 권한 요청
  await FirebaseManager.shared.fcm.requestPermission(provisional: true);

  // ⭐️ 2. APNS 토큰 지연 처리 (Timer 사용) ⭐️
  // Firebase Messaging 초기화 및 토큰 가져오기 로직을 Timer로 감싸 2초 후 실행
  Timer(const Duration(seconds: 2), () async {
    try {
      // APNS 토큰 대기 후 FCM 토큰 가져오기
      final fcmToken = await FirebaseManager.shared.getFcmToken();
      print("fcm 토큰 : $fcmToken");

      // 초기 메시지 및 기타 FCM 초기화 작업
      await FirebaseManager.initialize();
    } catch (e) {
      debugPrint('푸시 알림 서비스 초기화 실패: $e');
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            return AuthViewModel();
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            return ProfileViewModel(ProfileRepository());
          },
        ),
        Provider(create: (context) => HomeRepository()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String title;
  const MyApp({super.key, this.title = "타이틀"});

  @override
  Widget build(BuildContext context) {
    final AuthViewModel authVM = context.read<AuthViewModel>();

    // 1. authVM - 데이터 상태를 바꾼다
    // 2. 고 라우터 refreshListenable 에 authVM 이 연동되어 있다.
    // 3. authVM 의 데이터 변수가 바뀌면
    // 4. 고라우터의 redirect 로직이 타게된다.
    // 5. 현재 사용자 인증 상태는 authVM 로 알 수 있다.
    // 6. GoRouterState는 현재 사용자가 머물고 있는 화면 라우팅 주소를 알고 있다.
    // 7. 우리의 입맛에 맞게 화면이동처리가 가능하다.

    // final repo = context.read<MemoRepository>();

    final _router = createAppRouter(context);

    return MaterialApp.router(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        splashFactory: NoSplash.splashFactory, // 스플래쉬(리플효과) 제거
        highlightColor: Colors.transparent, // 하이라이트 효과 제거
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),

        scaffoldBackgroundColor: Color(0xFFF5F5F5),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFF5F5F5),
          //아래 두 줄 스크롤 시 appBar 색 바뀌는 현상 해결
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      routerConfig: _router,
    );
  }
}
