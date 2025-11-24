  import 'package:flutter/material.dart';
  import '../../controllers/auth_controller.dart';
  import '../auth/login_view.dart';
  import '../game/create_game_view.dart';   // ← add this (file you'll create next)

  class HomeView extends StatelessWidget {
    const HomeView({super.key});

    Future<void> _handleLogout(BuildContext context) async {
      await AuthController.instance.signOut();

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginView()),
            (route) => false,
      );
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
          ],
        ),

        body: Center(
          child: ElevatedButton(
            child: const Text("Create a Game"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateGameView(),
                ),
              );
            },
          ),
        ),
      );
    }
  }
