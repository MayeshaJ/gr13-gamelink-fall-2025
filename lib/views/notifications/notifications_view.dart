import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../controllers/notification_controller.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NotificationController.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: controller.watchNotificationsForCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final message = data['message'] as String? ?? '';
              final createdAt = (data['createdAt'] as Timestamp?)
                      ?.toDate()
                      .toLocal()
                      .toString()
                      .substring(0, 16) ??
                  '';
              final read = data['read'] as bool? ?? false;

              return ListTile(
                leading: Icon(
                  read
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                ),
                title: Text(message),
                subtitle: Text(createdAt),
                onTap: () {
                  controller.markAsRead(doc.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}
