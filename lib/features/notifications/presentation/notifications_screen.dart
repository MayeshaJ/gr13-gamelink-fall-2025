import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/notification_repository.dart';
import '../../models/app_notification.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // If user isn't logged in yet, show a message.
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
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              NotificationRepository.instance.markAllAsRead(userId);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationRepository.instance.watchNotificationsForUser(userId),
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final notif = notifications[index];

              return ListTile(
                leading: Icon(
                  _iconForType(notif.type),
                  color: notif.read ? Colors.grey : Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  notif.title,
                  style: notif.read
                      ? null
                      : const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  notif.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: notif.read
                    ? null
                    : const Icon(Icons.brightness_1, size: 10),
                onTap: () {
                  // For now: mark as read.
                  NotificationRepository.instance.markAsRead(
                    userId: userId,
                    notificationId: notif.id,
                  );

                  // Later: navigate to Game Details or Chat based on notif.gameId / notif.type.
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForType(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.hostJoin:
        return Icons.person_add;
      case AppNotificationType.waitlistSpot:
        return Icons.event_available;
      case AppNotificationType.cancelled:
        return Icons.cancel;
      case AppNotificationType.rescheduled:
        return Icons.schedule;
      case AppNotificationType.startReminder:
        return Icons.alarm;
      case AppNotificationType.chatMessage:
        return Icons.chat;
    }
  }
}
