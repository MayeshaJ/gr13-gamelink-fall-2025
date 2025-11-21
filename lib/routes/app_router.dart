import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:game_link_group13/views/home/home_view.dart';
import 'package:game_link_group13/views/auth/auth_gate.dart';
import 'package:game_link_group13/widgets/error_state.dart';
import 'package:game_link_group13/views/auth/login_view.dart';
import 'package:game_link_group13/views/auth/signup_view.dart';
import 'package:game_link_group13/views/auth/forgot_password_view.dart';

/// Centralized application router.
/// Screens are placeholders for now and will be replaced in later commits.
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'root',
      builder: (BuildContext context, GoRouterState state) {
        return const AuthGate();
      },
    ),
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginView();
      },
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (BuildContext context, GoRouterState state) {
        return const SignupView();
      },
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (BuildContext context, GoRouterState state) {
        return const ForgotPasswordView();
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
  errorBuilder: (BuildContext context, GoRouterState state) {
    final String? message = state.error?.toString();
    return ErrorState(details: message);
  },
);


