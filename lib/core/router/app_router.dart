import 'package:bidbird/core/widgets/bottom_nav_bar.dart';
import 'package:bidbird/core/widgets/item/components/others/double_back_exit_handler.dart';
import 'package:bidbird/features/auth/data/repository/tos_repository.dart';
import 'package:bidbird/features/auth/ui/auth_set_profile_screen.dart';
import 'package:bidbird/features/auth/ui/login_screen.dart';
import 'package:bidbird/features/auth/ui/tos_screen.dart';
import 'package:bidbird/features/auth/viewmodel/auth_view_model.dart';
import 'package:bidbird/features/auth/viewmodel/tos_viewmodel.dart';
import 'package:bidbird/features/chat/presentation/screens/chat_screen.dart';
import 'package:bidbird/features/chat/presentation/screens/chatting_room_screen.dart';
import 'package:bidbird/features/item_trade/trade_status/presentation/screens/trade_status_screen.dart';
import 'package:bidbird/features/feed/ui/home_screen.dart';
import 'package:bidbird/features/item_enroll/add/presentation/screens/item_add_screen.dart';
import 'package:bidbird/features/item_enroll/add/presentation/viewmodels/item_add_viewmodel.dart';
import 'package:bidbird/features/bid/domain/entities/item_bid_win_entity.dart';
import 'package:bidbird/features/bid/presentation/screens/item_bid_win_screen.dart';
import 'package:bidbird/features/current_trade/domain/entities/current_trade_entity.dart';
import 'package:bidbird/features/current_trade/presentation/screens/current_trade_screen.dart';
import 'package:bidbird/features/current_trade/presentation/screens/filtered_trade_list_screen.dart';
import 'package:bidbird/features/current_trade/presentation/viewmodels/current_trade_viewmodel.dart';
import 'package:bidbird/features/item_detail/detail/presentation/screens/item_detail_screen.dart';
import 'package:bidbird/features/item_enroll/registration/detail/presentation/screens/item_registration_detail_screen.dart';
import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';
import 'package:bidbird/features/item_enroll/registration/list/presentation/screens/item_registration_list_screen.dart';
import 'package:bidbird/features/item_enroll/relist/presentation/screens/item_relist_screen.dart';
import 'package:bidbird/features/item_detail/user_profile/presentation/screens/user_profile_screen.dart';
import 'package:bidbird/features/item_detail/user_history/presentation/screens/user_profile_history_screen.dart';
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
import 'package:bidbird/features/payment/payment_history/presentation/screens/payment_history_screen.dart';
import 'package:bidbird/features/splash/ui/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
    initialLocation: '/splash',
    refreshListenable: authVM,
    redirect: (context, state) {
      final authVM = context.read<AuthViewModel>();
      final location = state.uri.toString();

      // 1. 초기화 중이면 Splash 고정
      if (authVM.status == AuthStatus.initializing) {
        return location == '/splash' ? null : '/splash';
      }

      // 2. 비로그인
      if (authVM.status == AuthStatus.unauthenticated) {
        return location.startsWith('/login') ? null : '/login';
      }

      // 3. 로그인 완료 + 유저 정보 있음
      final user = authVM.user!;
      if (user.nick_name == null) {
        return location.startsWith('/login/ToS') ? null : '/login/ToS';
      }

      // 4. 정상 로그인 상태
      if (location == '/login' || location == '/splash') {
        return '/home';
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
        routes: [
          GoRoute(
            path: 'ToS',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: ChangeNotifierProvider(
                  create: (_) => ToSViewmodel(ToSRepository()),
                  child: const ToSScreen(),
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'auth_set_profile',
                pageBuilder: (context, state) {
                  return const NoTransitionPage(child: AuthSetProfileScreen());
                },
              ),
            ],
          ),
        ],
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
                  create: (_) => CurrentTradeViewModel()..loadData(),
                  child: const CurrentTradeScreen(),
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'filtered',
                pageBuilder: (context, state) {
                  final extra = state.extra;
                  if (extra is Map<String, dynamic>) {
                    final actionType = extra['actionType'] as TradeActionType;
                    final isSeller = extra['isSeller'] as bool?;
                    final actionTypes =
                        extra['actionTypes'] as List<TradeActionType>?;

                    // 부모 경로의 ViewModel 찾기
                    CurrentTradeViewModel? parentViewModel;
                    try {
                      // Navigator를 통해 부모 위젯 트리에서 Provider 찾기
                      final navigatorContext = Navigator.of(
                        context,
                        rootNavigator: false,
                      ).context;
                      parentViewModel = Provider.of<CurrentTradeViewModel>(
                        navigatorContext,
                        listen: false,
                      );
                    } catch (e) {
                      // Provider를 찾을 수 없으면 null
                    }

                    // 기존 ViewModel이 있으면 재사용, 없으면 새로 생성
                    if (parentViewModel != null) {
                      return NoTransitionPage(
                        child:
                            ChangeNotifierProvider<CurrentTradeViewModel>.value(
                              value: parentViewModel,
                              child: FilteredTradeListScreen(
                                actionType: actionType,
                                isSeller: isSeller,
                                actionTypes: actionTypes,
                              ),
                            ),
                      );
                    } else {
                      return NoTransitionPage(
                        child: ChangeNotifierProvider<CurrentTradeViewModel>(
                          create: (_) => CurrentTradeViewModel()..loadData(),
                          child: FilteredTradeListScreen(
                            actionType: actionType,
                            isSeller: isSeller,
                            actionTypes: actionTypes,
                          ),
                        ),
                      );
                    }
                  }
                  return const NoTransitionPage(child: CurrentTradeScreen());
                },
              ),
            ],
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
        routes: [
          GoRoute(
            path: 'trade-status',
            pageBuilder: (context, state) {
              final String itemId =
                  state.uri.queryParameters["itemId"] ?? "";
              return NoTransitionPage(
                child: TradeStatusScreen(itemId: itemId),
              );
            },
          ),
        ],
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

          return NoTransitionPage(child: ItemBidWinScreen(item: item));
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
          return const NoTransitionPage(child: ItemRegistrationListScreen());
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
                child: UserProfileHistoryScreen(userId: userId),
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
