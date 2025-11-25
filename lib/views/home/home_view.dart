import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    // sign out through controller
    await AuthController.instance.signOut();

    if (!context.mounted) {
      return;
    }

    // go back to login and clear navigation stack using GoRouter
    context.go('/auth');
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
          IconButton(
            onPressed: () {
              context.push('/profile');
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: const Center(
        child: Text('Home view'),
      ),
    );
  }
}
