import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:game_link_group13/views/auth/sign_in_placeholder.dart';
import 'package:game_link_group13/views/app/home_view.dart';

/// Centralized application router.
/// Screens are placeholders for now and will be replaced in later commits.
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'root',
      builder: (BuildContext context, GoRouterState state) {
        return const SizedBox.shrink();
      },
    ),
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (BuildContext context, GoRouterState state) {
        return const SignInPlaceholder();
      },
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeView();
      },
    ),
  ],
);


