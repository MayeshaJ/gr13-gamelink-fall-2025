import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'views/auth/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // keep your existing Firebase initialization here if it is already set up
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
      home: const LoginView(),
    );
  }
}
