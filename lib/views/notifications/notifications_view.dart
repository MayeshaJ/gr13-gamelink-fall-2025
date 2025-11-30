import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/notification_controller.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);

class NotificationsView extends StatefulWidget{
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final controller = NotificationController.instance;

  // 'all', 'game_update', 'chat', 'reminder'
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedCategory == 'all',
                  onSelected: (_) {
                    setState(() => _selectedCategory = 'all');
                  },
                ),
                ChoiceChip(
                  label: const Text('Game updates'),
                  selected: _selectedCategory == 'game_update',
                  onSelected: (_) {
                    setState(() => _selectedCategory = 'game_update');
                  },
                ),
                ChoiceChip(
                  label: const Text('Chat'),
                  selected: _selectedCategory == 'chat',
                  onSelected: (_) {
                    setState(() => _selectedCategory = 'chat');
                  },
                ),
                ChoiceChip(
                  label: const Text('Reminders'),
                  selected: _selectedCategory == 'reminder',
                  onSelected: (_) {
                    setState(() => _selectedCategory = 'reminder');
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: controller.watchNotificationsForCurrentUser(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No notifications yet'));
                }
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

                // Apply category filter
                final filteredDocs = _selectedCategory == 'all'
                    ? docs
                    : docs.where((doc) {
                        final data =
                            doc.data() as Map<String, dynamic>? ?? {};
                        final category =
                            data['category'] as String? ?? 'general';
                        if (_selectedCategory == 'reminder') {
                          return category == 'reminder';
                        }
                        if (_selectedCategory == 'chat') {
                          return category == 'chat';
                        }
                        if (_selectedCategory == 'game_update') {
                          // treat legacy types as game_update
                          final type = data['type'] as String? ?? '';
                          return category == 'game_update' ||
                              type == 'player_joined' ||
                              type == 'player_left' ||
                              type == 'game_cancelled' ||
                              type == 'game_rescheduled' ||
                              type == 'spot_open';
                        }
                        return true;
                      }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text('No notifications in this category'),
                  );
                }

                return ListView.separated(
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data =
                        doc.data() as Map<String, dynamic>? ?? {};
                    final message = data['message'] as String? ?? '';
                    final createdAt = (data['createdAt'] as Timestamp?)
                            ?.toDate()
                            .toLocal()
                            .toString()
                            .substring(0, 16) ??
                        '';
                    final read = data['read'] as bool? ?? false;
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
          ),
        ],
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
