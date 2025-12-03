import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'controllers/notification_controller.dart';
import 'controllers/theme_controller.dart';
import 'theme/app_theme.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background handling.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // For now we rely on the OS notification tray; no extra handling needed here.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // firebase must be initialized before running the app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background handler for FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification controller (permissions + FCM token registration)
  await NotificationController.instance.init();

  // Initialize theme controller
  await ThemeController.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize ScreenUtil with design dimensions from emulator
    // Design size: 411 x 923 (logical pixels from Pixel-style device)
    return ScreenUtilInit(
      designSize: const Size(411, 923),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return ListenableBuilder(
          listenable: ThemeController.instance,
          builder: (context, child) {
            return MaterialApp.router(
              title: 'GameLink',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme(),
              darkTheme: AppTheme.darkTheme(),
              themeMode: ThemeController.instance.isDarkMode 
                  ? ThemeMode.dark 
                  : ThemeMode.light,
              routerConfig: appRouter,
            );
          },
        );
      },
    );
  }
}
