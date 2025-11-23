import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository._();

  static final instance = NotificationRepository._();

  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userNotificationsRef(String userId) {
    // Structure: users/{userId}/notifications/{notificationId}
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  Stream<List<AppNotification>> watchNotificationsForUser(String userId) {
    return _userNotificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromDocument(doc))
          .toList();
    });
  }

  Future<void> addNotification({
    required String userId,
    required AppNotificationType type,
    required String title,
    required String body,
    String? gameId,
    String? triggeredByUserId,
  }) async {
    final now = DateTime.now();
    final docRef = _userNotificationsRef(userId).doc();

    final notif = AppNotification(
      id: docRef.id,
      type: type,
      title: title,
      body: body,
      userId: userId,
      gameId: gameId,
      triggeredByUserId: triggeredByUserId,
      createdAt: now,
      read: false,
    );

    await docRef.set(notif.toMap());
  }

  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    await _userNotificationsRef(userId)
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _userNotificationsRef(userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }
}
