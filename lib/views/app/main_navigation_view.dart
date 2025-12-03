import 'package:flutter/material.dart';

import '../game/game_list_view.dart';
import '../game/host_games_view.dart';
import '../notifications/notifications_view.dart';
import '../profile/profile_view.dart';
import '../../controllers/notification_controller.dart';

/// Main navigation view with bottom navigation bar
/// Displayed after user logs in
class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> with WidgetsBindingObserver {
  int _currentIndex = 0;

  // Define the pages for each tab
  final List<Widget> _pages = const [
    GameListView(),
    HostGamesView(),
    NotificationsView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize notifications when user enters the app
    NotificationController.instance.init();
    // Listen for app lifecycle changes to detect keyboard dismissal
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Force rebuild when metrics change (including keyboard appearance/dismissal)
    if (mounted) {
      setState(() {});
    }
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
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Host',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

