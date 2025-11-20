import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignInPlaceholder extends StatelessWidget {
  const SignInPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('Sign in screen placeholder'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Pass (test) → Home'),
            ),
          ],
        ),
      ),
    );
  }
}


