import 'package:bidbird/core/router/root_tab_back_handler.dart';
import 'package:bidbird/core/widgets/bottom_nav_bar.dart';
import 'package:bidbird/core/widgets/item/components/others/double_back_exit_handler.dart';
import 'package:bidbird/features/auth/presentation/screens/auth_set_profile_screen.dart';
import 'package:bidbird/features/auth/presentation/screens/login_screen.dart';
import 'package:bidbird/features/auth/presentation/screens/tos_screen.dart';
import 'package:bidbird/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:bidbird/features/auth/presentation/viewmodels/tos_viewmodel.dart';
import 'package:bidbird/features/bid/domain/entities/item_bid_win_entity.dart';
import 'package:bidbird/features/bid/presentation/screens/item_bid_win_screen.dart';
import 'package:bidbird/features/chat/presentation/screens/chat_screen.dart';
import 'package:bidbird/features/chat/presentation/screens/chatting_room_screen.dart';
import 'package:bidbird/features/current_trade/presentation/screens/current_trade_screen.dart';
import 'package:bidbird/features/current_trade/presentation/screens/filtered_trade_list_screen.dart';
import 'package:bidbird/features/home/presentation/screens/home_screen.dart';
import 'package:bidbird/features/item_detail/detail/presentation/screens/item_detail_screen.dart';
import 'package:bidbird/features/item_detail/user_history/presentation/screens/user_profile_history_screen.dart';
import 'package:bidbird/features/item_detail/user_profile/presentation/screens/user_profile_screen.dart';
import 'package:bidbird/features/item_enroll/add/presentation/screens/item_add_screen.dart';
import 'package:bidbird/features/item_enroll/add/presentation/viewmodels/item_add_viewmodel.dart';
import 'package:bidbird/features/item_enroll/registration/detail/presentation/screens/item_registration_detail_screen.dart';
import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';
import 'package:bidbird/features/item_enroll/registration/list/presentation/screens/item_registration_list_screen.dart';
import 'package:bidbird/features/item_enroll/relist/presentation/screens/item_relist_screen.dart';
import 'package:bidbird/features/item_trade/trade_status/presentation/screens/trade_status_screen.dart';
import 'package:bidbird/features/mypage/data/repositories/blacklist_repository_impl.dart';
import 'package:bidbird/features/mypage/data/repositories/favorites_repository_impl.dart';
import 'package:bidbird/features/mypage/data/repositories/report_feedback_repository_impl.dart';
import 'package:bidbird/features/mypage/data/repositories/trade_history_repository_impl.dart';
import 'package:bidbird/features/mypage/domain/entities/report_feedback_entity.dart';
import 'package:bidbird/features/mypage/domain/usecases/add_favorite.dart';
import 'package:bidbird/features/mypage/domain/usecases/block_user.dart';
import 'package:bidbird/features/mypage/domain/usecases/get_blacklist.dart';
import 'package:bidbird/features/mypage/domain/usecases/get_favorites.dart';
import 'package:bidbird/features/mypage/domain/usecases/get_report_feedback.dart';
import 'package:bidbird/features/mypage/domain/usecases/get_trade_history.dart';
import 'package:bidbird/features/mypage/domain/usecases/remove_favorite.dart';
import 'package:bidbird/features/mypage/domain/usecases/unblock_user.dart';
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
import 'package:bidbird/features/notification/presentation/screen/notification_screen.dart';
import 'package:bidbird/features/payment/payment_history/presentation/screens/payment_history_screen.dart';
import 'package:bidbird/features/splash/ui/splash_screen.dart';
import 'package:flutter/cupertino.dart'; // iOS 스타일 페이지를 위해 필요
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final doubleBackHandler = DoubleBackExitHandler();

final homeNavKey = GlobalKey<NavigatorState>();
final bidNavKey = GlobalKey<NavigatorState>();
final chatNavKey = GlobalKey<NavigatorState>();
final mypageNavKey = GlobalKey<NavigatorState>();

/// [수정 핵심] 플랫폼에 따라 iOS는 CupertinoPage(스와이프 가능), 나머지는 애니메이션 없는 페이지 반환
Page<T> buildPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  // iOS 스와이프 기능
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return CupertinoPage<T>(key: state.pageKey, child: child);
  }
  return NoTransitionPage<T>(key: state.pageKey, child: child);
}

GoRouter createAppRouter(BuildContext context) {
  final AuthViewModel authVM = context.read<AuthViewModel>();

  return GoRouter(
    observers: [routeObserver],
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authVM,
    redirect: (context, state) {
      final authVM = context.read<AuthViewModel>();
      final location = state.uri.toString();

      if (authVM.status == AuthStatus.initializing) {
        return location == '/splash' ? null : '/splash';
      }
      if (authVM.status == AuthStatus.unauthenticated) {
        return location.startsWith('/login') ? null : '/login';
      }
      final user = authVM.user;
      if (user != null && user.nick_name == null) {
        return location.startsWith('/login/ToS') ? null : '/login/ToS';
      }
      if (location == '/login' || location == '/splash') {
        return '/home';
      }
      return null;
    },
    routes: [
      // --- 스플래시 및 로그인 ---
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => buildPage(
          context: context,
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => buildPage(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
        routes: [
          GoRoute(
            path: 'ToS',
            pageBuilder: (context, state) => buildPage(
              context: context,
              state: state,
              child: ChangeNotifierProvider(
                create: (_) => ToSViewmodel(),
                child: const ToSScreen(),
              ),
            ),
            routes: [
              GoRoute(
                path: 'auth_set_profile',
                pageBuilder: (context, state) => buildPage(
                  context: context,
                  state: state,
                  child: const AuthSetProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // --- 메인 쉘 (바텀 네비게이션 포함) ---
      StatefulShellRoute.indexedStack(
        // StatefulShellRoute의 builder 부분 수정
        builder: (context, state, navigationShell) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;

              final NavigatorState? currentTabNav = _getCurrentNavigator(
                navigationShell.currentIndex,
              );

              // 하위 스택이 있으면 pop
              if (currentTabNav != null && currentTabNav.canPop()) {
                currentTabNav.pop();
              } else {
                // 루트 탭이면 홈으로 가거나 종료 핸들러 실행
                if (navigationShell.currentIndex != 0) {
                  navigationShell.goBranch(0);
                } else {
                  doubleBackHandler.onWillPop(context);
                }
              }
            },
            child: Scaffold(
              body: navigationShell,
              bottomNavigationBar: BottomNavBar(
                navigationShell: navigationShell,
              ),
            ),
          );
        },
        branches: [
          // 1. 홈 탭
          StatefulShellBranch(
            navigatorKey: homeNavKey,
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => buildPage(
                  context: context,
                  state: state,
                  child: const RootTabBackHandler(
                    isHome: true,
                    child: HomeScreen(),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'search',
                    pageBuilder: (context, state) => buildPage(
                      context: context,
                      state: state,
                      child: const LoginScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 2. 거래 탭
          StatefulShellBranch(
            navigatorKey: bidNavKey,
            routes: [
              GoRoute(
                path: '/bid',
                pageBuilder: (context, state) => buildPage(
                  context: context,
                  state: state,
                  child: const RootTabBackHandler(
                    isHome: true,
                    child: CurrentTradeScreen(),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'filtered',
                    pageBuilder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      if (extra != null) {
                        final actionType = extra['actionType'];
                        final isSeller = extra['isSeller'];
                        final actionTypes = extra['actionTypes'];
                        return buildPage(
                          context: context,
                          state: state,
                          child: FilteredTradeListScreen(
                            actionType: actionType,
                            isSeller: isSeller,
                            actionTypes: actionTypes,
                          ),
                        );
                      }
                      return buildPage(
                        context: context,
                        state: state,
                        child: const CurrentTradeScreen(),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // 3. 채팅 탭
          StatefulShellBranch(
            navigatorKey: chatNavKey,
            routes: [
              GoRoute(
                path: '/chat',
                pageBuilder: (context, state) => buildPage(
                  context: context,
                  state: state,
                  child: const RootTabBackHandler(
                    isHome: true,
                    child: ChatScreen(),
                  ),
                ),
              ),
            ],
          ),
          // 4. 마이페이지 탭
          StatefulShellBranch(
            navigatorKey: mypageNavKey,
            routes: [
              GoRoute(
                path: '/mypage',
                pageBuilder: (context, state) => buildPage(
                  context: context,
                  state: state,
                  child: const RootTabBackHandler(
                    isHome: true,
                    child: MypageScreen(),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'update_info',
                    pageBuilder: (context, state) => buildPage(
                      context: context,
                      state: state,
                      child: const ProfileEditScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'favorite',
                    pageBuilder: (context, state) => buildPage(
                      context: context,
                      state: state,
                      child: ChangeNotifierProvider(
                        create: (_) {
                          final repo = FavoritesRepositoryImpl();
                          return FavoritesViewModel(
                            getFavorites: GetFavorites(repo),
                            addFavorite: AddFavorite(repo),
                            removeFavorite: RemoveFavorite(repo),
                          )..loadFavorites();
                        },
                        child: const FavoritesScreen(),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'trade',
                    pageBuilder: (context, state) => buildPage(
                      context: context,
                      state: state,
                      child: ChangeNotifierProvider(
                        create: (_) {
                          final repo = TradeHistoryRepositoryImpl();
                          return TradeHistoryViewModel(
                            getTradeHistory: GetTradeHistory(repo),
                          )..loadPage(reset: true);
                        },
                        child: const TradeHistoryScreen(),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: 'service_center',
                    pageBuilder: (context, state) => buildPage(
                      context: context,
                      state: state,
                      child: const CsScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: 'terms',
                        pageBuilder: (context, state) => buildPage(
                          context: context,
                          state: state,
                          child: const TermsScreen(),
                        ),
                      ),
                      GoRoute(
                        path: 'report_feedback',
                        pageBuilder: (context, state) => buildPage(
                          context: context,
                          state: state,
                          child: ChangeNotifierProvider(
                            create: (_) {
                              final repo = ReportFeedbackRepositoryImpl();
                              return ReportFeedbackViewModel(
                                getReportFeedback: GetReportFeedback(repo),
                              )..loadReports();
                            },
                            child: const ReportFeedbackScreen(),
                          ),
                        ),
                        routes: [
                          GoRoute(
                            path: ':feedbackId',
                            pageBuilder: (context, state) => buildPage(
                              context: context,
                              state: state,
                              child: ReportFeedbackDetailScreen(
                                feedbackId:
                                    state.pathParameters["feedbackId"] ?? "",
                                report: state.extra as ReportFeedbackEntity?,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'black_list',
                    pageBuilder: (context, state) => buildPage(
                      context: context,
                      state: state,
                      child: ChangeNotifierProvider(
                        create: (_) {
                          final repo = BlacklistRepositoryImpl();
                          return BlacklistViewModel(
                            getBlacklist: GetBlacklist(repo),
                            blockUser: BlockUser(repo),
                            unblockUser: UnblockUser(repo),
                          )..loadBlacklist();
                        },
                        child: const BlacklistScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // --- 독립적 인 라우트 (바텀바 없음) ---
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => buildPage(
          context: context,
          state: state,
          child: const NotificationScreen(),
        ),
      ),
      GoRoute(
        path: '/chat/room',
        pageBuilder: (context, state) {
          final itemId = state.uri.queryParameters["itemId"] ?? "null";
          final roomId = state.uri.queryParameters["roomId"];
          return buildPage(
            context: context,
            state: state,
            child: ChattingRoomScreen(itemId: itemId, roomId: roomId),
          );
        },
        routes: [
          GoRoute(
            path: 'trade-status',
            pageBuilder: (context, state) => buildPage(
              context: context,
              state: state,
              child: TradeStatusScreen(
                itemId: state.uri.queryParameters["itemId"] ?? "",
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/payments',
        pageBuilder: (context, state) => buildPage(
          context: context,
          state: state,
          child: PaymentHistoryScreen(
            itemId: state.uri.queryParameters['itemId'],
          ),
        ),
      ),
      GoRoute(
        path: '/item/:id',
        pageBuilder: (context, state) => buildPage(
          context: context,
          state: state,
          child: ItemDetailScreen(itemId: state.pathParameters["id"] ?? ""),
        ),
      ),
      GoRoute(
        path: '/item/:itemId/relist',
        pageBuilder: (context, state) => buildPage(
          context: context,
          state: state,
          child: ItemRelistScreen(itemId: state.pathParameters['itemId'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/item_bid_win',
        pageBuilder: (context, state) {
          final item = state.extra is ItemBidWinEntity
              ? state.extra as ItemBidWinEntity
              : null;
          return buildPage(
            context: context,
            state: state,
            child: item != null
                ? ItemBidWinScreen(item: item)
                : const HomeScreen(),
          );
        },
      ),
      GoRoute(
        path: '/add_item',
        pageBuilder: (context, state) {
          final editingItemId = state.extra is String
              ? state.extra as String
              : null;
          return buildPage(
            context: context,
            state: state,
            child: ChangeNotifierProvider<ItemAddViewModel>(
              create: (_) {
                final vm = ItemAddViewModel();
                if (editingItemId != null) {
                  vm.startEdit(editingItemId);
                } else {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => vm.init(),
                  );
                }
                return vm;
              },
              child: const ItemAddScreen(),
            ),
          );
        },
        routes: [
          GoRoute(
            path: 'item_registration_list',
            pageBuilder: (context, state) => buildPage(
              context: context,
              state: state,
              child: const ItemRegistrationListScreen(),
            ),
          ),
          GoRoute(
            path: 'item_registration_detail',
            pageBuilder: (context, state) => buildPage(
              context: context,
              state: state,
              child: ItemRegistrationDetailScreen(
                item: state.extra as ItemRegistrationData,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/user/:userId',
        pageBuilder: (context, state) => buildPage(
          context: context,
          state: state,
          child: UserProfileScreen(
            userId: state.pathParameters["userId"] ?? "",
          ),
        ),
        routes: [
          GoRoute(
            path: 'trade',
            pageBuilder: (context, state) => buildPage(
              context: context,
              state: state,
              child: UserProfileHistoryScreen(
                userId: state.pathParameters["userId"] ?? "",
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/blocked',
        pageBuilder: (context, state) => buildPage(
          context: context,
          state: state,
          child: const HomeScreen(),
        ),
      ),
    ],
  );
}

/// 안드로이드 등에서 사용될 애니메이션 없는 페이지 클래스
class NoTransitionPage<T> extends CustomTransitionPage<T> {
  const NoTransitionPage({required super.child, super.key})
    : super(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: _noTransitionBuilder,
      );
}

Widget _noTransitionBuilder(
  BuildContext context,
  Animation<double> a,
  Animation<double> sa,
  Widget child,
) => child;

/// 현재 인덱스에 해당하는 탭의 NavigatorState를 반환하는 함수
NavigatorState? _getCurrentNavigator(int index) {
  switch (index) {
    case 0:
      return homeNavKey.currentState;
    case 1:
      return bidNavKey.currentState;
    case 2:
      return chatNavKey.currentState;
    case 3:
      return mypageNavKey.currentState;
    default:
      return null;
  }
}
