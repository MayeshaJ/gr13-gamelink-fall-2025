import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;    // who this notification belongs to
  final String type;      // 'player_joined', 'spot_open', 'cancelled', etc.
  final String message;
  final String? gameId;
  final DateTime createdAt;
  final bool read;
  final String category; // 'game_update', 'chat', 'reminder', etc.

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.gameId,
    required this.createdAt,
    required this.read,
    this.category = 'general',
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String,
      type: data['type'] as String? ?? 'generic',
      message: data['message'] as String? ?? '',
      gameId: data['gameId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] as bool? ?? false,
      category: data['category'] as String? ?? 'general',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'message': message,
      'gameId': gameId,
      'createdAt': FieldValue.serverTimestamp(),
      'read': read,
      'category': category,
    };
  }
}
