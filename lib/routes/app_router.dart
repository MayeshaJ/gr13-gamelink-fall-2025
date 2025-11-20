import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

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
        return const SizedBox.shrink();
      },
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) {
        return const SizedBox.shrink();
      },
    ),
  ],
);


