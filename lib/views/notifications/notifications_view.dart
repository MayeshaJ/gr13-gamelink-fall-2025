import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/notification_controller.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NotificationController.instance;

    return Scaffold(
      backgroundColor: kDarkNavy,
      appBar: AppBar(
        backgroundColor: kDarkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'NOTIFICATIONS',
          style: GoogleFonts.teko(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: controller.watchNotificationsForCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: kNeonGreen,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.white.withOpacity(0.1),
            ),
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

              return Container(
                color: read ? Colors.transparent : kDarkNavy.withOpacity(0.5),
                child: ListTile(
                leading: Icon(
                  read
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                    color: read ? Colors.grey[400] : kNeonGreen,
                ),
                  title: Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: read ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    createdAt,
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                onTap: () {
                  controller.markAsRead(doc.id);
                },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
