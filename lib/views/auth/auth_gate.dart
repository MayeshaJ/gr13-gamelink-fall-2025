import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:game_link_group13/widgets/loading_indicator.dart';

/// Listens to auth state and redirects:
/// - unauthenticated → /auth
/// - authenticated   → /home
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingIndicator());
        }

        final bool isSignedIn = snapshot.data != null;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isSignedIn) {
            context.goNamed('home');
          } else {
            context.goNamed('auth');
          }
        });

        // Render a minimal placeholder while redirecting.
        return const Scaffold(
          body: SizedBox.shrink(),
        );
      },
    );
  }
}


