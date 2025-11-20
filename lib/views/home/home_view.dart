import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../auth/login_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    // sign out through controller
    await AuthController.instance.signOut();

    if (!context.mounted) {
      return;
    }

    // go back to login and clear navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginView(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Text('Home view'),
      ),
    );
  }
}
