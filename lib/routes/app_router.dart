import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:game_link_group13/views/auth/auth_gate.dart';
import 'package:game_link_group13/widgets/error_state.dart';
import 'package:game_link_group13/views/auth/auth_view.dart';
import 'package:game_link_group13/views/auth/forgot_password_view.dart';
import 'package:game_link_group13/views/app/main_navigation_view.dart';
import 'package:game_link_group13/views/game/game_list_view.dart';
import 'package:game_link_group13/views/game/create_game_view.dart';
import 'package:game_link_group13/views/game/game_details_view.dart';
import 'package:game_link_group13/views/game/game_logs_view.dart';
import 'package:game_link_group13/views/profile/profile_view.dart';
import 'package:game_link_group13/views/profile/edit_profile_view.dart';
import 'package:game_link_group13/models/app_user.dart';
import 'package:game_link_group13/views/notifications/notifications_view.dart';


/// Centralized application router.
/// All navigation should use GoRouter (context.go, context.push, etc.)
final GoRouter appRouter = GoRouter(
  debugLogDiagnostics: true, // Enable debug logging for route issues
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
        return const AuthView();
      },
    ),
    GoRoute(
      path: '/signup',
      name: 'signup',
      builder: (BuildContext context, GoRouterState state) {
        return const AuthView();
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
        return const MainNavigationView();
      },
    ),
    GoRoute(
      path: '/games',
      name: 'games',
      builder: (BuildContext context, GoRouterState state) {
        // Support query parameter for search persistence
        final String? query = state.uri.queryParameters['q'];
        return GameListView(initialQuery: query);
      },
    ),
    GoRoute(
      path: '/game/create',
      name: 'create-game',
      builder: (BuildContext context, GoRouterState state) {
        return const CreateGameView();
      },
    ),
    GoRoute(
      path: '/game/:id',
      name: 'game-details',
      builder: (BuildContext context, GoRouterState state) {
        final gameId = state.pathParameters['id']!;
        return GameDetailsView(gameId: gameId);
      },
    ),
    GoRoute(
      path: '/game-logs',
      name: 'game-logs',
      builder: (BuildContext context, GoRouterState state) {
        return const GameLogsView();
      },
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (BuildContext context, GoRouterState state) {
        return const ProfileView();
      },
    ),
    GoRoute(
      path: '/edit-profile',
      name: 'edit-profile',
      builder: (BuildContext context, GoRouterState state) {
        // User data should be passed via state.extra when navigating
        final Object? extra = state.extra;
        if (extra == null || extra is! AppUser) {
          // If no user data provided, go back to profile
          return const ProfileView();
        }
        return EditProfileView(user: extra);
      },
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsView(),
    ),
  ],
  errorBuilder: (BuildContext context, GoRouterState state) {
    final String? message = state.error?.toString();
    return ErrorState(details: message);
  },
);
