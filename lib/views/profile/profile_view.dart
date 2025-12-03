import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/app_user.dart';
import '../../theme/app_theme.dart';

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
        const SnackBar(
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
    // Wrap with ListenableBuilder to react to theme changes
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, child) {
        final isDark = ThemeController.instance.isDarkMode;
        final accent = AppColors.accent(isDark);
        final bgColor = AppColors.background(isDark);
        final cardColor = AppColors.card(isDark);
        final textPrimary = AppColors.textPrimary(isDark);
        final textSecondary = AppColors.textSecondary(isDark);
        final borderColor = AppColors.border(isDark);

        if (_loading) {
          return Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: CircularProgressIndicator(
                color: accent,
              ),
            ),
          );
        }

        if (_userData == null) {
          return Scaffold(
            backgroundColor: bgColor,
            body: Center(
              child: Text(
                'No profile data found',
                style: TextStyle(color: textPrimary),
              ),
            ),
          );
        }

        final user = _userData!;
        final overallRating = _getOverallRating(user.skillLevel);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Column(
                children: [
                  // FIFA-Style Player Card
                  Container(
                    width: double.infinity,
                    constraints: BoxConstraints(maxWidth: 400.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF243447),
                                AppColors.darkNavy,
                                const Color(0xFF1a2a3a),
                              ]
                            : [
                                AppColors.lightCard,
                                AppColors.lightCardAlt,
                                AppColors.lightCard,
                              ],
                      ),
                      border: Border.all(
                        color: accent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow(isDark),
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
                              painter: DiagonalStripesPainter(isDark: isDark),
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
                                color: accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(0.5),
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
                          padding: EdgeInsets.all(12.w),
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
                                          color: accent,
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
                                          color: isDark 
                                              ? Colors.white.withOpacity(0.2)
                                              : Colors.black.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4.r),
                                        ),
                                        child: Icon(
                                          _getSportIcon(user.primarySport),
                                          color: accent,
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
                                          width: 80.w,
                                          height: 80.h,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: accent,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: accent.withOpacity(0.5),
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
                                                        color: cardColor,
                                                        child: Icon(
                                                          Icons.person,
                                                          size: 40.sp,
                                                          color: accent,
                                                        ),
                                                      );
                                                    },
                                                  )
                                                : Container(
                                                    color: cardColor,
                                                    child: Icon(
                                                      Icons.person,
                                                      size: 40.sp,
                                                      color: accent,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              // Player Name
                              Text(
                                user.fullName.trim().isNotEmpty
                                    ? user.fullName.toUpperCase()
                                    : 'PLAYER',
                                style: GoogleFonts.teko(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                  color: textPrimary,
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
                                  color: accent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: accent,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  user.primarySport.toUpperCase(),
                                  style: GoogleFonts.barlowSemiCondensed(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: accent,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              // Stats Section (FIFA-style)
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: borderColor,
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
                                        color: accent,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildStatItem('SKILL', user.skillLevel.toUpperCase(), isDark),
                                        _buildStatDivider(isDark),
                                        _buildStatItem('STATUS', 'ACTIVE', isDark),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8.h),
                              // Bio Section
                              if (user.bio.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.grey.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10.r),
                                    border: Border.all(
                                      color: borderColor,
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
                                          color: accent,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      SizedBox(height: 3.h),
                                      Text(
                                        user.bio,
                                        style: GoogleFonts.barlowSemiCondensed(
                                          color: textSecondary,
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
                  SizedBox(height: 8.h),
                  // Additional Info Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: borderColor,
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
                            color: textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        _buildInfoRow(Icons.email, 'Email', user.email, isDark, accent),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Appearance Settings Section (Theme Toggle)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.palette_outlined, color: accent, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'APPEARANCE',
                              style: GoogleFonts.teko(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        _buildThemeToggle(isDark, accent, textPrimary, textSecondary),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Notification Settings Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notifications_outlined, color: accent, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'NOTIFICATION SETTINGS',
                              style: GoogleFonts.teko(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        _buildNotificationToggle(
                          icon: Icons.sports,
                          title: 'Game Updates',
                          subtitle: 'Joins, leaves, reschedules, cancellations',
                          value: _notifyGameUpdates,
                          onChanged: (value) {
                            setState(() => _notifyGameUpdates = value);
                            _updateNotificationSetting('notifyGameUpdates', value);
                          },
                          isDark: isDark,
                          accent: accent,
                        ),
                        SizedBox(height: 6.h),
                        _buildNotificationToggle(
                          icon: Icons.chat_bubble_outline,
                          title: 'Chat Messages',
                          subtitle: 'New messages in game chats',
                          value: _notifyChatMessages,
                          onChanged: (value) {
                            setState(() => _notifyChatMessages = value);
                            _updateNotificationSetting('notifyChatMessages', value);
                          },
                          isDark: isDark,
                          accent: accent,
                        ),
                        SizedBox(height: 6.h),
                        _buildNotificationToggle(
                          icon: Icons.alarm,
                          title: 'Game Reminders',
                          subtitle: '1 hour before game starts',
                          value: _notifyReminders,
                          onChanged: (value) {
                            setState(() => _notifyReminders = value);
                            _updateNotificationSetting('notifyReminders', value);
                          },
                          isDark: isDark,
                          accent: accent,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 38.h,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: Icon(Icons.logout, size: 16.sp),
                      label: Text(
                        'SIGN OUT',
                        style: GoogleFonts.barlowSemiCondensed(
                          fontSize: 13.sp,
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
      },
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.teko(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.barlowSemiCondensed(
            fontSize: 9.sp,
            color: AppColors.textSecondary(isDark),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      height: 28.h,
      width: 1,
      color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark, Color accent) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: accent),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 10.sp,
                  color: AppColors.textSecondary(isDark),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                value,
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(isDark),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggle(bool isDark, Color accent, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            size: 16.sp,
            color: accent,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dark Mode',
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                isDark ? 'Navy blue theme active' : 'Light grey theme active',
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 10.sp,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 24.h,
          child: Switch(
            value: isDark,
            onChanged: (value) {
              ThemeController.instance.setDarkMode(value);
            },
            activeColor: accent,
            activeTrackColor: accent.withOpacity(0.3),
            inactiveThumbColor: AppColors.darkGreen,
            inactiveTrackColor: AppColors.darkGreen.withOpacity(0.3),
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
    required bool isDark,
    required Color accent,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(icon, size: 16.sp, color: accent),
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
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 10.sp,
                  color: AppColors.textSecondary(isDark),
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
            activeColor: accent,
            activeTrackColor: accent.withOpacity(0.3),
            inactiveThumbColor: Colors.grey[500],
            inactiveTrackColor: AppColors.switchInactiveTrack(isDark),
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
  final bool isDark;
  
  DiagonalStripesPainter({this.isDark = true});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark 
          ? Colors.white.withOpacity(0.03)
          : Colors.black.withOpacity(0.02)
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
  bool shouldRepaint(covariant DiagonalStripesPainter oldDelegate) => 
      oldDelegate.isDark != isDark;
}
