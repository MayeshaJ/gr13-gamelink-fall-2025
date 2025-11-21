import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'views/auth/auth_gate_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // firebase must be initialized before running the app
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameLink',
      debugShowCheckedModeBanner: false,
      // AuthGateView decides login or home based on auth state
      home: const AuthGateView(),
    );
  }
}
