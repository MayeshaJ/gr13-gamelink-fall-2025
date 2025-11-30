import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
      setState(() {
        _userData = AppUser.fromMap(data);
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
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
        actions: [
          IconButton(
            onPressed: () async {
              // Navigate to edit profile with user data
              final result = await context.pushNamed(
                'edit-profile',
                extra: user,
              );
              if (result == true || context.mounted) {
                _loadUserData();
              }
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                  child: user.photoUrl.isEmpty
                      ? const Icon(
                          Icons.person,
                          size: 40,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(user.email),
                    const SizedBox(height: 20),
                    Text(
                      'First Name',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(user.firstName.isEmpty ? 'Not set' : user.firstName),
                    const SizedBox(height: 20),
                    Text(
                      'Last Name',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(user.lastName.isEmpty ? 'Not set' : user.lastName),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.sports_soccer, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Favorite sport',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.primarySport.isEmpty
                          ? 'No sport selected'
                          : user.primarySport,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.military_tech, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Skill level',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          user.skillLevel.isEmpty ? 'Not set' : user.skillLevel,
                        ),
                        const SizedBox(width: 8),
                        ..._buildSkillIcons(user.skillLevel.isEmpty
                            ? 'Beginner'
                            : user.skillLevel),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'About',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.bio.isEmpty
                          ? 'Tell others a little about yourself'
                          : user.bio,
                    ),
                    const SizedBox(height: 20),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // FIFA-Style Player Card
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF243447),
                      kDarkNavy,
                      const Color(0xFF1a2a3a),
                    ],
                  ),
                  border: Border.all(
                    color: kNeonGreen,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kNeonGreen.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Diagonal stripe pattern (FIFA-style)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: CustomPaint(
                          painter: DiagonalStripesPainter(),
                        ),
                      ),
                    ),
                    // Edit Button on top right corner
                    Positioned(
                      top: 12,
                      right: 12,
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kNeonGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: kNeonGreen.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    // Card Content
                    Padding(
                      padding: const EdgeInsets.all(20),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: kNeonGreen,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$overallRating',
                                      style: GoogleFonts.teko(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Position (Sport)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      _getSportIcon(user.primarySport),
                                      color: kNeonGreen,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // Player Photo
                              Expanded(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: kNeonGreen,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: kNeonGreen.withOpacity(0.5),
                                            blurRadius: 15,
                                            spreadRadius: 2,
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
                                                    child: const Icon(
                                                      Icons.person,
                                                      size: 60,
                                                      color: kNeonGreen,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: const Color(0xFF243447),
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 60,
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
                          const SizedBox(height: 12),
                          // Player Name
                          Text(
                            user.name.trim().isNotEmpty
                                ? user.name.toUpperCase()
                                : 'PLAYER',
                            style: GoogleFonts.teko(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          // Sport Name
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kNeonGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: kNeonGreen,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              user.primarySport.toUpperCase(),
                              style: GoogleFonts.teko(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: kNeonGreen,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Stats Section (FIFA-style)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: kNeonGreen,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
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
                          const SizedBox(height: 12),
                          // Bio Section
                          if (user.bio.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: kNeonGreen,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.bio,
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 12,
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
              const SizedBox(height: 16),
              // Additional Info Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF243447),
                  borderRadius: BorderRadius.circular(16),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.email, 'Email', user.email),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Sign Out Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout, size: 20),
                  label: Text(
                    'SIGN OUT',
                    style: GoogleFonts.teko(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 32,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: kNeonGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
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
