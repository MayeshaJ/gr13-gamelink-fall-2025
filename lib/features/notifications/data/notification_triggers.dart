import '../local_notification_service.dart';
import '../models/app_notifications.dart';
import 'notification_repository.dart';

class NotificationTriggers {
  NotificationTriggers._();

  static final instance = NotificationTriggers._();

  /// Host notification when a user joins their game
  Future<void> notifyHostUserJoined({
    required String hostId,
    required String joiningUserName,
    required String gameId,
    required String gameTitle,
  }) async {
    await NotificationRepository.instance.addNotification(
      userId: hostId,
      type: AppNotificationType.hostJoin,
      title: 'New player joined your game',
      body: '$joiningUserName joined $gameTitle',
      gameId: gameId,
      triggeredByUserId: null, // could be joining user id if needed
    );
  }

  /// Waitlist notification when a spot opens for a user
  Future<void> notifyWaitlistSpotOpened({
    required String userId,
    required String gameId,
    required String gameTitle,
  }) async {
    await NotificationRepository.instance.addNotification(
      userId: userId,
      type: AppNotificationType.waitlistSpot,
      title: 'Spot available!',
      body: 'A spot opened up in $gameTitle. Join before it’s gone.',
      gameId: gameId,
    );
  }

  /// Cancellation notification to any user (participants, waitlist)
  Future<void> notifyGameCancelled({
    required String userId,
    required String gameId,
    required String gameTitle,
  }) async {
    await NotificationRepository.instance.addNotification(
      userId: userId,
      type: AppNotificationType.cancelled,
      title: 'Game cancelled',
      body: '$gameTitle has been cancelled by the host.',
      gameId: gameId,
    );
  }

  /// Reschedule notification
  Future<void> notifyGameRescheduled({
    required String userId,
    required String gameId,
    required String gameTitle,
    required DateTime newDateTime,
  }) async {
    final formattedTime =
        '${newDateTime.month}/${newDateTime.day} at ${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}';

    await NotificationRepository.instance.addNotification(
      userId: userId,
      type: AppNotificationType.rescheduled,
      title: 'Game time changed',
      body: '$gameTitle has been rescheduled to $formattedTime.',
      gameId: gameId,
    );
  }

  /// Chat message notification 
  Future<void> notifyChatMessage({
    required String recipientId,
    required String gameId,
    required String gameTitle,
    required String senderName,
    required String messagePreview,
  }) async {
    await NotificationRepository.instance.addNotification(
      userId: recipientId,
      type: AppNotificationType.chatMessage,
      title: 'New message in $gameTitle',
      body: '$senderName: $messagePreview',
      gameId: gameId,
    );
  }

  /// Game start reminder: create local notification on this device
  Future<void> scheduleGameStartReminderForCurrentUser({
    required String gameId,
    required String gameTitle,
    required DateTime gameDateTime,
  }) async {
    await LocalNotificationService.instance.scheduleGameStartReminder(
      gameId: gameId,
      gameTitle: gameTitle,
      gameDateTime: gameDateTime,
    );
  }

  Future<void> cancelGameStartReminderForCurrentUser({
    required String gameId,
  }) async {
    await LocalNotificationService.instance.cancelGameReminder(gameId);
  }
}
