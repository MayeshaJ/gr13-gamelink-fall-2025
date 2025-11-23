import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType {
  hostJoin,        // Host notified that user joined their game
  waitlistSpot,    // Spot opened for a waitlisted user
  cancelled,       // Game was cancelled
  rescheduled,     // Game time/date changed
  startReminder,   // "Game starting in 1 hour" reminder
  chatMessage,     // New chat message 
}

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final String userId;
  final String? gameId;
  final String? triggeredByUserId;
  final DateTime createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.userId,
    this.gameId,
    this.triggeredByUserId,
    required this.createdAt,
    required this.read,
  });

  factory AppNotification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppNotification(
      id: doc.id,
      type: _typeFromString(data['type'] as String? ?? 'hostJoin'),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      gameId: data['gameId'] as String?,
      triggeredByUserId: data['triggeredByUserId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': _typeToString(type),
      'title': title,
      'body': body,
      'userId': userId,
      'gameId': gameId,
      'triggeredByUserId': triggeredByUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
    };
  }

  static AppNotificationType _typeFromString(String type) {
    switch (type) {
      case 'hostJoin':
        return AppNotificationType.hostJoin;
      case 'waitlistSpot':
        return AppNotificationType.waitlistSpot;
      case 'cancelled':
        return AppNotificationType.cancelled;
      case 'rescheduled':
        return AppNotificationType.rescheduled;
      case 'startReminder':
        return AppNotificationType.startReminder;
      case 'chatMessage':
        return AppNotificationType.chatMessage;
      default:
        return AppNotificationType.hostJoin;
    }
  }

  static String _typeToString(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.hostJoin:
        return 'hostJoin';
      case AppNotificationType.waitlistSpot:
        return 'waitlistSpot';
      case AppNotificationType.cancelled:
        return 'cancelled';
      case AppNotificationType.rescheduled:
        return 'rescheduled';
      case AppNotificationType.startReminder:
        return 'startReminder';
      case AppNotificationType.chatMessage:
        return 'chatMessage';
    }
  }

  AppNotification copyWith({
    bool? read,
  }) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      userId: userId,
      gameId: gameId,
      triggeredByUserId: triggeredByUserId,
      createdAt: createdAt,
      read: read ?? this.read,
    );
  }
}
