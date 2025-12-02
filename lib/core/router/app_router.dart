import 'package:bidbird/core/widgets/bottom_nav_bar.dart';
import 'package:bidbird/core/widgets/splash_screen.dart';
import 'package:bidbird/features/auth/ui/auth_ui.dart';
import 'package:bidbird/features/auth/viewmodel/auth_view_model.dart';
import 'package:bidbird/features/trade/ui/current_trade_screen.dart';
import 'package:bidbird/features/chat/ui/chat_screen.dart';
import 'package:bidbird/features/chat/ui/chatting_room_screen.dart';
import 'package:bidbird/features/feed/ui/home_screen.dart';
import 'package:bidbird/features/profile/ui/profile_screen.dart';
import 'package:bidbird/features/report/ui/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

GoRouter createAppRouter(BuildContext context) {
  final AuthViewModel authVM = context.read<AuthViewModel>();

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authVM,
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
            path: '/profile',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: ProfileScreen());
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
          return const NoTransitionPage(child: HomeScreen());
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
          return const NoTransitionPage(child: HomeScreen());
        },
        routes: [
          GoRoute(
            path: '/check',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: HomeScreen());
            },
          ),
        ],
      ),
      GoRoute(
        path: '/user/:userId',
        pageBuilder: (context, state) {
          final userId = state.pathParameters["userId"] ?? "";
          return const NoTransitionPage(child: HomeScreen());
        },
        routes: [
          GoRoute(
            path: '/trade',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: HomeScreen());
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
