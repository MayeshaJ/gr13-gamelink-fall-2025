import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/app_user.dart';
import 'edit_profile_view.dart';

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

  List<Widget> _buildSkillIcons(String skillLevel) {
    int count;
    switch (skillLevel) {
      case 'Intermediate':
        count = 2;
        break;
      case 'Advanced':
        count = 3;
        break;
      case 'Beginner':
      default:
        count = 1;
        break;
    }

    return List<Widget>.generate(
      count,
      (_) => const Icon(Icons.sports_esports, size: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userData == null) {
      return const Scaffold(
        body: Center(
          child: Text('No profile data found'),
        ),
      );
    }

    final user = _userData!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (_) => EditProfileView(user: user),
                ),
              )
                  .then((_) {
                _loadUserData();
              });
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
                      'Name',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(user.name.isEmpty ? 'Not set' : user.name),
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
                    Text(
                      'User ID',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(user.uid),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
