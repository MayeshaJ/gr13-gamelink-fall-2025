import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../game/game_list_view.dart';
import '../game/host_games_view.dart';
import '../profile/profile_view.dart';
import '../../controllers/notification_controller.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);

/// Main navigation view with bottom navigation bar
/// Displayed after user logs in
class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> with WidgetsBindingObserver {
  int _currentIndex = 0;

  // Define the pages for each tab (removed notifications)
  final List<Widget> _pages = const [
    GameListView(),
    HostGamesView(),
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
            content: Text(message, style: TextStyle(fontSize: 14.sp)),
            duration: const Duration(seconds: 4),
            backgroundColor: kNeonGreen,
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: kNeonGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: kDarkNavy,
          selectedItemColor: kNeonGreen,
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: GoogleFonts.barlowSemiCondensed(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: GoogleFonts.barlowSemiCondensed(
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
          ),
          iconSize: 22.sp,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'BROWSE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle),
              label: 'HOST',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}
