import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Timezone initialization
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;

        // TODO: handle navigation when user taps a reminder
        // e.g., go to GameDetails page if payload contains a gameId.
        debugPrint('Notification tapped with payload: $payload');
      },
    );

    _initialized = true;
  }

  /// Schedule a reminder 1 hour before [gameDateTime].
  Future<void> scheduleGameStartReminder({
    required String gameId,
    required String gameTitle,
    required DateTime gameDateTime,
  }) async {
    await init();

    final scheduled = gameDateTime.subtract(const Duration(hours: 1));

    // Only schedule if time is in the future
    if (scheduled.isBefore(DateTime.now())) return;

    final id = gameId.hashCode & 0x7fffffff; // make it positive

    await _plugin.zonedSchedule(
      id,
      'Game starting soon',
      'Your game "$gameTitle" starts in 1 hour.',
      tz.TZDateTime.from(scheduled, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'game_reminders',
          'Game Reminders',
          channelDescription: 'Reminders for upcoming games',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: gameId,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> cancelGameReminder(String gameId) async {
    await init();
    final id = gameId.hashCode & 0x7fffffff;
    await _plugin.cancel(id);
  }
}
