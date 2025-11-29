import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'auth_controller.dart';

/// Handles push notification setup and in-app handling for waitlist events.
class NotificationController {
  NotificationController._internal();

  static final NotificationController instance =
      NotificationController._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Ensures we only wire listeners / ask for permission once.
  bool _listenersInitialized = false;

  /// Initialize Firebase Messaging:
  /// - request permissions (once)
  /// - wire listeners (once)
  /// - register the device token for the *current* signed-in user (idempotent)
  Future<void> init() async {
    // One-time permission request + listeners.
    if (!_listenersInitialized) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      // In-app foreground handling of messages.
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Keep user tokens up to date when FCM token changes.
      _messaging.onTokenRefresh.listen((String newToken) async {
        final currentUser = AuthController.instance.currentUser;
        if (currentUser == null) return;

        final usersRef = FirebaseFirestore.instance.collection('users');
        await usersRef.doc(currentUser.uid).set(
          <String, dynamic>{
            'fcmTokens': FieldValue.arrayUnion(<String>[newToken]),
          },
          SetOptions(merge: true),
        );
      });

      _listenersInitialized = true;
    }

    // Always (re)attempt to register the token for the current user.
    await _registerTokenForCurrentUser();
  }

  Future<void> _registerTokenForCurrentUser() async {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser == null) return;

    final String? token = await _messaging.getToken();
    if (token == null) return;

    final usersRef = FirebaseFirestore.instance.collection('users');
    await usersRef.doc(currentUser.uid).set(
      <String, dynamic>{
        'fcmTokens': FieldValue.arrayUnion(<String>[token]),
      },
      SetOptions(merge: true),
    );
  }

  /// Handle foreground FCM messages.
  ///
  /// We expect "spot open" notifications for waitlisted games to include:
  /// data: {
  ///   "type": "spot_open",
  ///   "gameId": "...",
  ///   "title": "...",
  /// }
  void _handleForegroundMessage(RemoteMessage message) {
    // For now, we rely on the OS notification for background/terminated state.
    // When the app is open, we surface a prompt via a SnackBar.
    final data = message.data;
    final type = data['type'];

    if (type == 'spot_open') {
      final String gameTitle =
          data['title'] as String? ?? 'one of your games';
      final String inAppMessage =
          'A spot just opened in "$gameTitle"! Join quickly - first come, first served.';

      // Defer to root scaffold messenger for in-app prompt
      NotificationPromptBus.showSpotOpenPrompt(inAppMessage);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Firestore-backed app notifications
  // ─────────────────────────────────────────────────────────────

  // Firestore notifications collection (instance reference, optional)
  final CollectionReference _notificationsRef =
      FirebaseFirestore.instance.collection('notifications');

  /// Create a simple notification document for a user.
  static Future<void> createNotification({
    required String toUserId,
    required String type,
    required String message,
    String? gameId,
  }) async {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': toUserId,
        'type': type,
        'message': message,
        'gameId': gameId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
  }
  
  /// Stream notifications for the currently signed-in user.
  Stream<QuerySnapshot> watchNotificationsForCurrentUser() {
    final user = AuthController.instance.currentUser;
    if (user == null) {
      return const Stream<QuerySnapshot>.empty();
    }

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }
}

/// Simple bus to show prompts from places where `BuildContext` is not
/// available (e.g. FirebaseMessaging foreground callbacks).
class NotificationPromptBus {
  static void Function(String message)? _showPrompt;

  /// Called once from the app root with a function that can show SnackBars.
  static void registerPromptHandler(void Function(String message) handler) {
    _showPrompt = handler;
  }

  static void showSpotOpenPrompt(String message) {
    final handler = _showPrompt;
    if (handler != null) {
      handler(message);
    }
  }
}
