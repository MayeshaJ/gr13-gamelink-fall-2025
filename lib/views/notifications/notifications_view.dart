import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/notification_controller.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final controller = NotificationController.instance;

    return Scaffold(
      backgroundColor: kDarkNavy,
      appBar: AppBar(
        backgroundColor: kDarkNavy,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 22.sp),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'NOTIFICATIONS',
          style: GoogleFonts.teko(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All', Icons.notifications),
                  SizedBox(width: 8.w),
                  _buildFilterChip('chat', 'Chat', Icons.chat_bubble_outline),
                  SizedBox(width: 8.w),
                  _buildFilterChip('game_update', 'Updates', Icons.sports),
                  SizedBox(width: 8.w),
                  _buildFilterChip('reminder', 'Reminders', Icons.alarm),
                ],
              ),
            ),
          ),
          
          Divider(height: 1, color: Colors.white.withOpacity(0.1)),
          
          // Notifications List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 48.sp,
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No notifications yet',
                          style: GoogleFonts.barlowSemiCondensed(
                            color: Colors.grey[400],
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allDocs = snapshot.data!.docs;
                
                // Filter based on selected category
                final filteredDocs = _selectedFilter == 'all'
                    ? allDocs
                    : allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final category = data['category'] as String? ?? 'general';
                        return category == _selectedFilter;
                      }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getFilterIcon(_selectedFilter),
                          size: 48.sp,
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No ${_getFilterLabel(_selectedFilter).toLowerCase()} notifications',
                          style: GoogleFonts.barlowSemiCondensed(
                            color: Colors.grey[400],
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final message = data['message'] as String? ?? '';
                    final createdAt = (data['createdAt'] as Timestamp?)
                            ?.toDate()
                            .toLocal()
                            .toString()
                            .substring(0, 16) ??
                        '';
                    final read = data['read'] as bool? ?? false;
                    final category = data['category'] as String? ?? 'general';

                    return Container(
                      color: read ? Colors.transparent : const Color(0xFF243447).withOpacity(0.5),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                        leading: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: (read ? Colors.grey[600]! : _getCategoryColor(category)).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            _getCategoryIcon(category),
                            color: read ? Colors.grey[500] : _getCategoryColor(category),
                            size: 20.sp,
                          ),
                        ),
                        title: Text(
                          message,
                          style: GoogleFonts.barlowSemiCondensed(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: read ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              createdAt,
                              style: GoogleFonts.barlowSemiCondensed(
                                color: Colors.grey[400],
                                fontSize: 11.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(category).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                _getCategoryLabel(category),
                                style: GoogleFonts.barlowSemiCondensed(
                                  color: _getCategoryColor(category),
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? kNeonGreen : const Color(0xFF243447),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? kNeonGreen : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isSelected ? Colors.black : Colors.grey[400],
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.barlowSemiCondensed(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'game_update':
        return Icons.sports;
      case 'reminder':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'chat':
        return 'Chat';
      case 'game_update':
        return 'Update';
      case 'reminder':
        return 'Reminder';
      default:
        return 'All';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'game_update':
        return Icons.sports;
      case 'reminder':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'chat':
        return Colors.blue;
      case 'game_update':
        return kNeonGreen;
      case 'reminder':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'chat':
        return 'CHAT';
      case 'game_update':
        return 'UPDATE';
      case 'reminder':
        return 'REMINDER';
      default:
        return 'GENERAL';
    }
  }
}
