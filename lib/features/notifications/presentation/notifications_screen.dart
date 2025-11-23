import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/notification_repository.dart';
import '../models/app_notifications.dart';
import '../local_notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to see notifications.'),
        ),
      );
    }

    final userId = currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
      ),
      body: Column(
        children: [
          const _RecentAlertsHeader(),
          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: NotificationRepository.instance
                  .watchNotificationsForUser(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading notifications: ${snapshot.error}'),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return const Center(
                    child: Text('No notifications yet.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return _NotificationCard(
                      notification: notif,
                      onTap: () async {
                        await NotificationRepository.instance.markAsRead(
                          userId: userId,
                          notificationId: notif.id,
                        );
                        // Later: navigate to Game Details or Chat based on notif.type/gameId.
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Debug only: generate fake notifications & a reminder
          if (kDebugMode)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  await _generateTestNotifications(userId);
                  final now = DateTime.now().add(const Duration(minutes: 1));
                  await LocalNotificationService.instance
                      .scheduleGameStartReminder(
                    gameId: 'testGame',
                    gameTitle: 'Pickup at Main Gym',
                    gameDateTime: now,
                  );
                },
                child: const Text('Generate test notifications'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _generateTestNotifications(String userId) async {
    await NotificationRepository.instance.addNotification(
      userId: userId,
      type: AppNotificationType.startReminder,
      title: 'Game starting soon!',
      body: 'Pickup at Main Gym starts in 2 hours',
      gameId: 'game1',
    );

    await NotificationRepository.instance.addNotification(
      userId: userId,
      type: AppNotificationType.rescheduled,
      title: 'Game location changed',
      body: '5v5 Friendly Match moved to East Field',
      gameId: 'game2',
    );

    await NotificationRepository.instance.addNotification(
      userId: userId,
      type: AppNotificationType.hostJoin,
      title: 'Successfully joined!',
      body: 'You\'re confirmed for Pickup at Main Gym',
      gameId: 'game3',
    );

    await NotificationRepository.instance.addNotification(
      userId: userId,
      type: AppNotificationType.cancelled,
      title: 'Game cancelled',
      body: 'Beach Volleyball has been cancelled by the host',
      gameId: 'game4',
    );
  }
}

class _RecentAlertsHeader extends StatelessWidget {
  const _RecentAlertsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Icon(Icons.notifications_none),
          const SizedBox(width: 8),
          Text(
            'Recent Alerts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNew = !notification.read;

    return Material(
      color: isNew
          ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
          : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight:
                                isNew ? FontWeight.bold : FontWeight.w500,
                          ),
                    ),
                  ),
                  if (isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'New',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                notification.body,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _timeAgo(notification.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    final days = diff.inDays;
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }
}
