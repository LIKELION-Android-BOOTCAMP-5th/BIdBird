import 'package:bidbird/core/widgets/bottom_nav_bar.dart';
import 'package:bidbird/core/widgets/splash_screen.dart';
import 'package:bidbird/features/auth/viewmodel/auth_view_model.dart';
import 'package:bidbird/features/bid/ui/bid_screen.dart';
import 'package:bidbird/features/chat/ui/chat_screen.dart';
import 'package:bidbird/features/feed/ui/home_screen.dart';
import 'package:bidbird/features/profile/ui/profile_screen.dart';
import 'package:bidbird/core/router/app_router.dart';
import 'package:bidbird/features/auth/viewmodel/auth_view_model.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient supabase = Supabase.instance.client;

EventBus eventBus = EventBus();

void main() async {
  await Supabase.initialize(url: '', anonKey: '');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) {
            return AuthViewModel();
          },
        ),
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

    final _router = GoRouter(
      initialLocation: '/home',
      refreshListenable: authVM,
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return Scaffold(body: child, bottomNavigationBar: BottomNavBar());
          },
          routes: [
            GoRoute(
              path: '/splash',
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: SplashScreen());
              },
            ),
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: HomeScreen());
              },
            ),
            GoRoute(
              path: '/bid',
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: BidScreen());
              },
            ),
            GoRoute(
              path: '/chat',
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: ChatScreen());
              },
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: ProfileScreen());
              },
            ),
          ],
        ),
      ],
    );
    final _router1 = createAppRouter(context);

    return MaterialApp.router(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        splashFactory: NoSplash.splashFactory, // 스플래쉬(리플효과) 제거
        highlightColor: Colors.transparent, // 하이라이트 효과 제거
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),

        scaffoldBackgroundColor: Color(0xFFF5F5F5),
        appBarTheme: AppBarTheme(backgroundColor: Color(0xFFF5F5F5)),
      ),
      routerConfig: _router,
    );
  }
}

// 애니메이션 없이 페이지를 전환해주는 클래스
class NoTransitionPage<T> extends CustomTransitionPage<T> {
  const NoTransitionPage({required super.child, super.key})
      : super(
    transitionDuration: Duration.zero, // 전환 시간 0
    reverseTransitionDuration: Duration.zero, // 역전환 시간 0
    transitionsBuilder: _noTransitionBuilder,
  );
}

// 애니메이션 없이 child만 반환하는 빌더
Widget _noTransitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    ) {
  return child;
}