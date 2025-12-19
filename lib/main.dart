import 'dart:async';

import 'package:bidbird/core/managers/app_initializer.dart';
import 'package:bidbird/core/router/app_router.dart';
import 'package:bidbird/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:bidbird/features/chat/presentation/viewmodels/chat_list_viewmodel.dart';
import 'package:bidbird/features/home/data/repository/home_repository.dart';
import 'package:bidbird/features/mypage/data/repositories/profile_repository_impl.dart';
import 'package:bidbird/features/mypage/domain/usecases/get_profile.dart';
import 'package:bidbird/features/mypage/viewmodel/profile_viewmodel.dart';
import 'package:bidbird/features/notification/presentation/viewmodel/notification_viewmodel.dart';
import 'package:bidbird/features/splash/ui/splash_screen.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

EventBus eventBus = EventBus();

void main() async {
  // 1. 초기화는 한 번만!
  WidgetsFlutterBinding.ensureInitialized();

  unawaited(
    AppInitializer.ensureInitialized().then((_) {
      AppInitializer.startPostInitTasks();
    }),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            return AuthViewModel();
          },
        ),
        // 확정된 프로필 데이터
        ChangeNotifierProvider(
          create: (_) {
            final repo = ProfileRepositoryImpl();
            return ProfileViewModel(GetProfile(repo));
          },
        ),
        // 프로필정보가 필요한 곳에서 다음과 같이 사용하세요
        // final profileVm = context.watch<ProfileViewModel>();
        // final profile = profileVm.profile;
        // final nickName = profile?.nickName ?? '';
        // final profileImageUrl = profile?.profileImageUrl;
        Provider(create: (context) => HomeRepositoryImpl()),
        ChangeNotifierProvider(
          create: (context) {
            return NotificationViewmodel(context);
          },
        ),
        ChangeNotifierProvider(
          create: (context) {
            return ChatListViewmodel();
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  final String title;
  const MyApp({super.key, this.title = "타이틀"});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  GoRouter? _router;
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = AppInitializer.ensureInitialized();
  }

  @override
  Widget build(BuildContext context) {
    // 1. authVM - 데이터 상태를 바꾼다
    // 2. 고 라우터 refreshListenable 에 authVM 이 연동되어 있다.
    // 3. authVM 의 데이터 변수가 바뀌면
    // 4. 고라우터의 redirect 로직이 타게된다.
    // 5. 현재 사용자 인증 상태는 authVM 로 알 수 있다.
    // 6. GoRouterState는 현재 사용자가 머물고 있는 화면 라우팅 주소를 알고 있다.
    // 7. 우리의 입맛에 맞게 화면이동처리가 가능하다.

    // final repo = context.read<MemoRepository>();

    final theme = ThemeData(
      splashFactory: NoSplash.splashFactory, // 스플래쉬(리플효과) 제거
      highlightColor: Colors.transparent, // 하이라이트 효과 제거
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),

      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F5),
        //아래 두 줄 스크롤 시 appBar 색 바뀌는 현상 해결
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );

    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            title: widget.title,
            debugShowCheckedModeBanner: false,
            color: const Color(0xFFF5F5F5),
            theme: theme,
            builder: (context, child) {
              return ColoredBox(
                color: const Color(0xFFF5F5F5),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const SplashScreen(),
          );
        }

        _router ??= createAppRouter(context);

        return MaterialApp.router(
          title: widget.title,
          debugShowCheckedModeBanner: false,
          color: const Color(0xFFF5F5F5),
          theme: theme,
          builder: (context, child) {
            return ColoredBox(
              color: const Color(0xFFF5F5F5),
              child: child ?? const SizedBox.shrink(),
            );
          },
          routerConfig: _router!,
        );
      },
    );
  }
}
