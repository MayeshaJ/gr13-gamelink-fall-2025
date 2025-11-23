import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'features/notifications/local_notification_service.dart';
import 'features/notifications/presentation/notifications_screen.dart';

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Received a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize local notifications (reminders)
  await LocalNotificationService.instance.init();

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request push notification permissions
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Optional: print FCM token for debugging
  final token = await messaging.getToken();
  print("FCM Token: $token");

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // This MaterialApp creates the Navigator
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GameLink Group 13',

      // Register routes here
      routes: {
        '/notifications': (context) => const NotificationsScreen(),
      },

      // Home screen with a button that uses the Navigator
      home: Builder(
        // Builder gives us a context *under* the MaterialApp / Navigator
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Home'),
            ),
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/notifications');
                },
                child: const Text('Go to Notifications'),
              ),
            ),
          );
        },
      ),
    );
  }
}
