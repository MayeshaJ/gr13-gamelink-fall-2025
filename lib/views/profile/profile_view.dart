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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditProfileView(user: _userData!),
                ),
              ).then((_) {
                // refresh profile after editing
                _loadUserData();
              });
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Email',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(_userData!.email),
            const SizedBox(height: 20),

            Text(
              'Name',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(_userData!.name.isEmpty ? 'Not set' : _userData!.name),
            const SizedBox(height: 20),

            Text(
              'User ID',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(_userData!.uid),
          ],
        ),
      ),
    );
  }
}
