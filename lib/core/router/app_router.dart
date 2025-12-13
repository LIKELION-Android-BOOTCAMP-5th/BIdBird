import 'package:bidbird/core/widgets/bottom_nav_bar.dart';
import 'package:bidbird/core/widgets/item/double_back_exit_handler.dart';
import 'package:bidbird/core/widgets/splash_screen.dart';
import 'package:bidbird/features/auth/ui/auth_ui.dart';
import 'package:bidbird/features/auth/viewmodel/auth_view_model.dart';
import 'package:bidbird/features/chat/presentation/screens/chat_screen.dart';
import 'package:bidbird/features/chat/presentation/screens/chatting_room_screen.dart';
import 'package:bidbird/features/feed/ui/home_screen.dart';
import 'package:bidbird/features/item/add/screen/item_add_screen.dart';
import 'package:bidbird/features/item/add/viewmodel/item_add_viewmodel.dart';
import 'package:bidbird/features/item/bid_win/model/item_bid_win_entity.dart';
import 'package:bidbird/features/item/bid_win/screen/item_bid_win_screen.dart';
import 'package:bidbird/features/item/current_trade/data/repository/current_trade_repository.dart';
import 'package:bidbird/features/item/current_trade/screen/current_trade_screen.dart';
import 'package:bidbird/features/item/current_trade/viewmodel/current_trade_viewmodel.dart';
import 'package:bidbird/features/item/detail/screen/item_detail_screen.dart';
import 'package:bidbird/features/item/registration/detail/screen/item_registration_detail_screen.dart';
import 'package:bidbird/features/item/registration/list/model/item_registration_entity.dart';
import 'package:bidbird/features/item/registration/list/screen/item_registration_list_screen.dart';
import 'package:bidbird/features/item/relist/screen/item_relist_screen.dart';
import 'package:bidbird/features/item/user_profile/screen/user_profile_screen.dart';
import 'package:bidbird/features/item/user_profile_history/screen/user_history_screen.dart';
import 'package:bidbird/features/mypage/data/blacklist_repository.dart';
import 'package:bidbird/features/mypage/data/favorites_repository.dart';
import 'package:bidbird/features/mypage/data/report_feedback_repository.dart';
import 'package:bidbird/features/mypage/data/trade_history_repository.dart';
import 'package:bidbird/features/mypage/model/report_feedback_model.dart';
import 'package:bidbird/features/mypage/ui/blacklist_screen.dart';
import 'package:bidbird/features/mypage/ui/cs_screen.dart';
import 'package:bidbird/features/mypage/ui/favorites_screen.dart';
import 'package:bidbird/features/mypage/ui/mypage_screen.dart';
import 'package:bidbird/features/mypage/ui/profile_edit_screen.dart';
import 'package:bidbird/features/mypage/ui/report_feedback_detail_screen.dart';
import 'package:bidbird/features/mypage/ui/report_feedback_screen.dart';
import 'package:bidbird/features/mypage/ui/terms_screen.dart';
import 'package:bidbird/features/mypage/ui/trade_history_screen.dart';
import 'package:bidbird/features/mypage/viewmodel/blacklist_viewmodel.dart';
import 'package:bidbird/features/mypage/viewmodel/favorites_viewmodel.dart';
import 'package:bidbird/features/mypage/viewmodel/report_feedback_viewmodel.dart';
import 'package:bidbird/features/mypage/viewmodel/trade_history_viewmodel.dart';
import 'package:bidbird/features/notification/screen/notification_screen.dart';
import 'package:bidbird/features/payment/payment_history/screen/payment_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/user_entity.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(BuildContext context) {
  final AuthViewModel authVM = context.read<AuthViewModel>();
  final doubleBackHandler = DoubleBackExitHandler();

  return GoRouter(
    observers: [
      routeObserver, // ← 여기!!
    ],
    navigatorKey: rootNavigatorKey,
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
          return WillPopScope(
            onWillPop: () async {
              final location = state.uri.toString();

              if (location != '/home') {
                context.go('/home');
                return false;
              }

              return doubleBackHandler.onWillPop(context);
            },
            child: Scaffold(
              body: child,
              bottomNavigationBar: const BottomNavBar(),
            ),
          );
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
              return NoTransitionPage(
                child: ChangeNotifierProvider<CurrentTradeViewModel>(
                  create: (_) => CurrentTradeViewModel(
                    repository: CurrentTradeRepositoryImpl(),
                  )..loadData(),
                  child: const CurrentTradeScreen(),
                ),
              );
            },
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: ChatScreen());
            },
          ),
          GoRoute(
            path: '/mypage',
            pageBuilder: (context, state) {
              return const NoTransitionPage(child: MypageScreen());
            },
            routes: [
              GoRoute(
                path: '/update_info',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: ProfileEditScreen());
                },
              ),
              GoRoute(
                path: '/favorite',
                pageBuilder: (context, state) {
                  return NoTransitionPage(
                    child: ChangeNotifierProvider(
                      create: (_) =>
                          FavoritesViewModel(repository: FavoritesRepository())
                            ..loadFavorites(),
                      child: const FavoritesScreen(),
                    ),
                  );
                },
              ),
              GoRoute(
                path: '/trade',
                pageBuilder: (context, state) {
                  return NoTransitionPage(
                    child: ChangeNotifierProvider(
                      create: (_) => TradeHistoryViewModel(
                        repository: TradeHistoryRepository(),
                      )..loadPage(reset: true),
                      child: const TradeHistoryScreen(),
                    ),
                  );
                },
              ),
              GoRoute(
                path: '/service_center',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: CsScreen());
                },
                routes: [
                  GoRoute(
                    path: '/terms',
                    pageBuilder: (context, state) {
                      return const NoTransitionPage(child: TermsScreen());
                    },
                  ),
                  GoRoute(
                    path: '/report_feedback',
                    pageBuilder: (context, state) {
                      return NoTransitionPage(
                        child: ChangeNotifierProvider(
                          create: (_) => ReportFeedbackViewModel(
                            repository: ReportFeedbackRepository(),
                          )..loadReports(),
                          child: const ReportFeedbackScreen(),
                        ),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: '/:feedbackId',
                        pageBuilder: (context, state) {
                          final feedbackId =
                              state.pathParameters["feedbackId"] ?? "";
                          final report =
                              state.extra
                                  as ReportFeedbackModel?; //state.extra(Object?타입)쓸떄사용해야하는문법
                          return NoTransitionPage(
                            child: ReportFeedbackDetailScreen(
                              feedbackId: feedbackId,
                              report: report,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: '/black_list',
                pageBuilder: (context, state) {
                  return NoTransitionPage(
                    child: ChangeNotifierProvider(
                      create: (_) =>
                          BlacklistViewModel(repository: BlacklistRepository())
                            ..loadBlacklist(),
                      child: const BlacklistScreen(),
                    ),
                  );
                },
              ),
              GoRoute(
                path: '/setting',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: MypageScreen());
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/chat/room',
        pageBuilder: (context, state) {
          final String thisItemId =
              state.uri.queryParameters["itemId"] ?? "null";
          final String? thisRoomId =
              state.uri.queryParameters["roomId"] ?? null;
          return NoTransitionPage(
            child: ChattingRoomScreen(itemId: thisItemId, roomId: thisRoomId),
          );
        },
      ),
      GoRoute(
        path: '/payment',
        pageBuilder: (context, state) {
          return const NoTransitionPage(child: HomeScreen());
        },
      ),
      GoRoute(
        path: '/payments',
        pageBuilder: (context, state) {
          final String? itemId = state.uri.queryParameters['itemId'];
          return NoTransitionPage(child: PaymentHistoryScreen(itemId: itemId));
        },
      ),
      GoRoute(
        path: '/item/:itemId/relist',
        pageBuilder: (context, state) {
          final itemId = state.pathParameters['itemId'] ?? '';
          return NoTransitionPage(child: ItemRelistScreen(itemId: itemId));
        },
      ),
      GoRoute(
        path: '/item/:id',
        pageBuilder: (context, state) {
          final itemId = state.pathParameters["id"] ?? "";
          return NoTransitionPage(child: ItemDetailScreen(itemId: itemId));
        },
      ),
      GoRoute(
        path: '/item_bid_win',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final item = extra is ItemBidWinEntity ? extra : null;

          if (item == null) {
            return const NoTransitionPage(child: HomeScreen());
          }

          return NoTransitionPage(child: ItemBidSuccessScreen(item: item));
        },
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) {
          return const NoTransitionPage(child: NotificationScreen());
        },
      ),
      GoRoute(
        path: '/add_item',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final String? editingItemId = extra is String ? extra : null;
          return NoTransitionPage(
            child: ChangeNotifierProvider<ItemAddViewModel>(
              create: (_) {
                final vm = ItemAddViewModel();
                if (editingItemId != null) {
                  vm.startEdit(editingItemId);
                } else {
                  vm.init();
                }
                return vm;
              },
              child: const ItemAddScreen(),
            ),
          );
        },
      ),
      GoRoute(
        path: '/add_item/item_registration_list',
        pageBuilder: (context, state) {
          return const NoTransitionPage(child: RegistrationScreen());
        },
      ),
      GoRoute(
        path: '/add_item/item_registration_detail',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final item = extra is ItemRegistrationData ? extra : null;

          if (item == null) {
            return const NoTransitionPage(child: HomeScreen());
          }
          return NoTransitionPage(
            child: ItemRegistrationDetailScreen(item: item),
          );
        },
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
