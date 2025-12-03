import 'package:bidbird/core/widgets/bottom_nav_bar.dart';
import 'package:bidbird/core/widgets/splash_screen.dart';
import 'package:bidbird/features/auth/ui/auth_ui.dart';
import 'package:bidbird/features/auth/viewmodel/auth_view_model.dart';
import 'package:bidbird/features/chat/ui/chat_screen.dart';
import 'package:bidbird/features/chat/ui/chatting_room_screen.dart';
import 'package:bidbird/features/current_trade/screen/current_trade_screen.dart';
import 'package:bidbird/features/feed/ui/home_screen.dart';
import 'package:bidbird/features/item_add/item_add_screen/item_add_screen.dart';
import 'package:bidbird/features/item_add/item_add_viewmoel/item_add_viewmoel.dart';
import 'package:bidbird/features/item_detail/screen/item_detail_screen.dart';
import 'package:bidbird/features/item_registration/ui/item_registration_ui.dart';
import 'package:bidbird/features/item_registration/viewmodel/item_registration_viewmodel.dart';
import 'package:bidbird/features/profile/ui/my_page_screen.dart';
import 'package:bidbird/features/profile/ui/profile_screen.dart';
import 'package:bidbird/features/report/ui/report_screen.dart';
import 'package:bidbird/features/user_profile/screen/user_profile_screen.dart';
import 'package:bidbird/features/user_profile/screen/user_trade_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/user_entity.dart';

GoRouter createAppRouter(BuildContext context) {
  final AuthViewModel authVM = context.read<AuthViewModel>();

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authVM,
    redirect: (BuildContext context, GoRouterState state) {
      final bool isLoggedIn = authVM.isLoggedIn;
      debugPrint("[리디렉트] isLoggedIn: ${isLoggedIn}");

      final String currentRoute = state.uri.toString();
      debugPrint("[리디렉트] currentRoute: ${currentRoute}");

      final UserEntity? user = authVM.user;

      //로그인 되면 홈화면으로 이동
      if (isLoggedIn && currentRoute == '/login') {
        return '/home';
        // 밴 유저는 밴유저 페이지로
      } else if (isLoggedIn && user?.is_banned == true) {
        return '/blocked';
        // 삭제한 유저는 삭제유저 페이지로
      } else if (isLoggedIn && user?.unregister_at != null) {
        return '/deleted_user';
      }

      //접근 가능한 화면
      final List<String> publicRoutes = [
        '/login',
        '/splash',
        '/home',
        '/blocked',
        '/deleted_user',
        '/set_profile',
      ];
      // 비로그인인데 publicRoutes 중 어떤 것도 아닌 경우 로그인 페이지로(지선생)
      final bool isPublic = publicRoutes.any(
        (path) => currentRoute.startsWith(path),
      );
      if (!isLoggedIn && !isPublic) {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) {
          return const NoTransitionPage(child: SplashScreen());
        },
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          return const NoTransitionPage(child: LoginScreen());
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(body: child, bottomNavigationBar: BottomNavBar());
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: HomeScreen());
            },
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: LoginScreen());
                },
              ),
            ],
          ),
          GoRoute(
            path: '/bid',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: CurrentTradeScreen());
            },
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: ChatScreen());
            },
            routes: [
              GoRoute(
                path: '/:roomId',
                pageBuilder: (context, state) {
                  final roomId = state.pathParameters["roomId"] ?? "";
                  return const NoTransitionPage(child: ChattingRoomScreen());
                },
                routes: [
                  GoRoute(
                    path: '/trade_report',
                    pageBuilder: (context, state) {
                      return const NoTransitionPage(child: ReportScreen());
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/my_page',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: MyPageScreen());
            },
            routes: [
              GoRoute(
                path: '/update_info',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: ProfileScreen());
                },
              ),
              GoRoute(
                path: '/favorite',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: ProfileScreen());
                },
              ),
              GoRoute(
                path: '/trade',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: ProfileScreen());
                },
              ),
              GoRoute(
                path: '/service_center',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: ProfileScreen());
                },
                routes: [
                  GoRoute(
                    path: '/terms',
                    pageBuilder: (context, state) {
                      return const NoTransitionPage(child: ProfileScreen());
                    },
                  ),
                  GoRoute(
                    path: '/report_feedback',
                    pageBuilder: (context, state) {
                      return const NoTransitionPage(child: ProfileScreen());
                    },
                    routes: [
                      GoRoute(
                        path: '/:feedbackId',
                        pageBuilder: (context, state) {
                          final feedbackId =
                              state.pathParameters["feedbackId"] ?? "";
                          return const NoTransitionPage(child: ProfileScreen());
                        },
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: '/black_list',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: ProfileScreen());
                },
              ),
              GoRoute(
                path: '/setting',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: ProfileScreen());
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/payment',
        pageBuilder: (context, state) {
          final itemId = state.uri.queryParameters['itemId'] ?? '';
          return const NoTransitionPage(child: HomeScreen());
        },
      ),
      GoRoute(
        path: '/item/:id',
        pageBuilder: (context, state) {
          final itemId = state.pathParameters["id"] ?? "";
          // TODO: itemId를 사용해 실제 상세 데이터를 로드하도록 연동
          return const NoTransitionPage(child: ItemDetailScreen());
        },
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) {
          return const NoTransitionPage(child: HomeScreen());
        },
      ),
      GoRoute(
        path: '/add_item',
        pageBuilder: (context, state) {
          return NoTransitionPage(
            child: ChangeNotifierProvider<ItemAddViewModel>(
              create: (_) => ItemAddViewModel()..init(),
              child: const ItemAddScreen(),
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/check',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: ChangeNotifierProvider<ItemRegistrationViewModel>(
                  create: (_) => ItemRegistrationViewModel()..init(),
                  child: const ItemRegistrationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/user/:userId',
        pageBuilder: (context, state) {
          final userId = state.pathParameters["userId"] ?? "";
          return NoTransitionPage(child: UserProfileScreen(userId: userId));
        },
        routes: [
          GoRoute(
            path: '/trade',
            pageBuilder: (context, state) {
              final userId = state.pathParameters["userId"] ?? "";
              return NoTransitionPage(
                child: UserTradeHistoryScreen(userId: userId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/blocked',
        pageBuilder: (context, state) {
          return const NoTransitionPage(child: HomeScreen());
        },
      ),
    ],
  );
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
