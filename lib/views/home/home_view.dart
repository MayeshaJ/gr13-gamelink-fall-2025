import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await AuthController.instance.signOut();

    if (!context.mounted) return;

    // Clear navigation stack and go to auth route
    context.goNamed('auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GameLink Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
          IconButton(
            onPressed: () => context.pushNamed('profile'),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.pushNamed('create-game'),
          child: const Text('Create a Game'),
        ),
      ),
    );
  }
}
