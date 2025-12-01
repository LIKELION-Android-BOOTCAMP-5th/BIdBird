import 'package:bidbird/features/auth/ui/auth_ui.dart';
import 'package:bidbird/features/auth/viewmodel/auth_view_model.dart';
import 'package:bidbird/features/feed/ui/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

GoRouter createAppRouter(BuildContext context) {
  final AuthViewModel authVM = context.read<AuthViewModel>();

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authVM,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) {
          return const NoTransitionPage(child: HomeScreen());
        },
      ),
    ],
  );
}
