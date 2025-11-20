import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../home/home_view.dart';
import 'login_view.dart';

class AuthGateView extends StatelessWidget {
  const AuthGateView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthController.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // show simple loading while checking auth state
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          // user is not logged in show login view
          return const LoginView();
        }

        // user is logged in show home view
        return const HomeView();
      },
    );
  }
}
