import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/app_user.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  AppUser? _userData;
  bool _loading = true;
  
  // Notification settings state
  bool _notifyGameUpdates = true;
  bool _notifyChatMessages = true;
  bool _notifyReminders = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = AuthController.instance.currentUser;

    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final data = await UserController.instance.getUserDocument(uid: user.uid);

    if (data != null) {
      final user = AppUser.fromMap(data);
      setState(() {
        _userData = user;
        _notifyGameUpdates = user.notifyGameUpdates;
        _notifyChatMessages = user.notifyChatMessages;
        _notifyReminders = user.notifyReminders;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    final authUser = AuthController.instance.currentUser;
    if (authUser == null) return;

    try {
      await UserController.instance.updateUserDocument(
        uid: authUser.uid,
        data: {key: value},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update setting'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _getOverallRating(String skillLevel) {
    switch (skillLevel) {
      case 'Beginner':
        return 65;
      case 'Intermediate':
        return 78;
      case 'Advanced':
        return 92;
      default:
        return 50;
    }
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'soccer':
        return Icons.sports_soccer;
      case 'basketball':
        return Icons.sports_basketball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'baseball':
        return Icons.sports_baseball;
      case 'hockey':
        return Icons.sports_hockey;
      default:
        return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: kDarkNavy,
        body: const Center(
          child: CircularProgressIndicator(
            color: kNeonGreen,
          ),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        backgroundColor: kDarkNavy,
        body: const Center(
          child: Text(
            'No profile data found',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final user = _userData!;
    final overallRating = _getOverallRating(user.skillLevel);

    return Scaffold(
      backgroundColor: kDarkNavy,
      appBar: AppBar(
        backgroundColor: kDarkNavy,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.all(12.w),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // FIFA-Style Player Card
              Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: 400.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF243447),
                      kDarkNavy,
                      Color(0xFF1a2a3a),
                    ],
                  ),
                  border: Border.all(
                    color: kNeonGreen,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kNeonGreen.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Diagonal stripe pattern (FIFA-style)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: CustomPaint(
                          painter: DiagonalStripesPainter(),
                        ),
                      ),
                    ),
                    // Edit Button on top right corner
                    Positioned(
                      top: 10.h,
                      right: 10.w,
                      child: InkWell(
                        onTap: () async {
                          final result = await context.pushNamed(
                            'edit-profile',
                            extra: user,
                          );
                          if (result == true || context.mounted) {
                            _loadUserData();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: kNeonGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: kNeonGreen.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.black,
                            size: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    // Card Content
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: [
                          // Top Section: Rating and Position
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Rating & Position
                              Column(
                                children: [
                                  // Overall Rating
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kNeonGreen,
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      '$overallRating',
                                      style: GoogleFonts.teko(
                                        fontSize: 28.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  // Position (Sport)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 3.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Icon(
                                      _getSportIcon(user.primarySport),
                                      color: kNeonGreen,
                                      size: 20.sp,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 12.w),
                              // Player Photo
                              Expanded(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 90.w,
                                      height: 90.h,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: kNeonGreen,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: kNeonGreen.withOpacity(0.5),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: user.photoUrl.isNotEmpty
                                            ? Image.network(
                                                user.photoUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: const Color(0xFF243447),
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 40.sp,
                                                      color: kNeonGreen,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: const Color(0xFF243447),
                                                child: Icon(
                                                  Icons.person,
                                                  size: 40.sp,
                                                  color: kNeonGreen,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          // Player Name
                          Text(
                            user.fullName.trim().isNotEmpty
                                ? user.fullName.toUpperCase()
                                : 'PLAYER',
                            style: GoogleFonts.teko(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4.h),
                          // Sport Name
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: kNeonGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: kNeonGreen,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              user.primarySport.toUpperCase(),
                              style: GoogleFonts.barlowSemiCondensed(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: kNeonGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          // Stats Section (FIFA-style)
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'PLAYER STATS',
                                  style: GoogleFonts.teko(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: kNeonGreen,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem('SKILL', user.skillLevel.toUpperCase()),
                                    _buildStatDivider(),
                                    _buildStatItem('STATUS', 'ACTIVE'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10.h),
                          // Bio Section
                          if (user.bio.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ABOUT',
                                    style: GoogleFonts.teko(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                      color: kNeonGreen,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Text(
                                    user.bio,
                                    style: GoogleFonts.barlowSemiCondensed(
                                      color: Colors.grey[300],
                                      fontSize: 11.sp,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              // Additional Info Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF243447),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACCOUNT INFO',
                      style: GoogleFonts.teko(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    _buildInfoRow(Icons.email, 'Email', user.email),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              // Notification Settings Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF243447),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_outlined, color: kNeonGreen, size: 18.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'NOTIFICATION SETTINGS',
                          style: GoogleFonts.teko(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    _buildNotificationToggle(
                      icon: Icons.sports,
                      title: 'Game Updates',
                      subtitle: 'Joins, leaves, reschedules, cancellations',
                      value: _notifyGameUpdates,
                      onChanged: (value) {
                        setState(() => _notifyGameUpdates = value);
                        _updateNotificationSetting('notifyGameUpdates', value);
                      },
                    ),
                    SizedBox(height: 8.h),
                    _buildNotificationToggle(
                      icon: Icons.chat_bubble_outline,
                      title: 'Chat Messages',
                      subtitle: 'New messages in game chats',
                      value: _notifyChatMessages,
                      onChanged: (value) {
                        setState(() => _notifyChatMessages = value);
                        _updateNotificationSetting('notifyChatMessages', value);
                      },
                    ),
                    SizedBox(height: 8.h),
                    _buildNotificationToggle(
                      icon: Icons.alarm,
                      title: 'Game Reminders',
                      subtitle: '1 hour before game starts',
                      value: _notifyReminders,
                      onChanged: (value) {
                        setState(() => _notifyReminders = value);
                        _updateNotificationSetting('notifyReminders', value);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              // Sign Out Button
              SizedBox(
                width: double.infinity,
                height: 42.h,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: Icon(Icons.logout, size: 18.sp),
                  label: Text(
                    'SIGN OUT',
                    style: GoogleFonts.barlowSemiCondensed(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.teko(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.barlowSemiCondensed(
            fontSize: 9.sp,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 28.h,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: kNeonGreen),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 10.sp,
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                value,
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: kNeonGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(icon, size: 16.sp, color: kNeonGreen),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 10.sp,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 24.h,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: kNeonGreen,
            activeTrackColor: kNeonGreen.withOpacity(0.3),
            inactiveThumbColor: Colors.grey[500],
            inactiveTrackColor: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await AuthController.instance.signOut();

    if (!context.mounted) return;

    context.goNamed('auth');
  }
}

// Custom painter for diagonal stripes (FIFA card effect)
class DiagonalStripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 2;

    const spacing = 30.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
