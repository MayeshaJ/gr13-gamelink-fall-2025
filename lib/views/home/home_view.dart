import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/notification_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Future<void> _handleLogout(BuildContext context) async {
    await AuthController.instance.signOut();

    if (!context.mounted) return;

    // Clear navigation stack and go to auth route
    context.goNamed('auth');
  }

  @override
  void initState() {
    super.initState();
    // At this point the user is authenticated; ensure their FCM token
    // is registered against their `users/{uid}` document.
    NotificationController.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    // Register handler to show in-app prompts for notification events
    NotificationPromptBus.registerPromptHandler(
      (String message) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 4),
          ),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('GameLink Home'),
        actions: [
          IconButton(
            onPressed: () => context.pushNamed('notifications'),
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: () => context.pushNamed('profile'),
            icon: const Icon(Icons.person),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),  
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to games list
                context.push('/games');
              },
              icon: const Icon(Icons.sports_soccer),
              label: const Text('Browse Games'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.pushNamed('create-game'),
              icon: const Icon(Icons.add),
              label: const Text('Create a Game'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.pushNamed('game-logs'),
              icon: const Icon(Icons.history),
              label: const Text('My Hosted Games'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
