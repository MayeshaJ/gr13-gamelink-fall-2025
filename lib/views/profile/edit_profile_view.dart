import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/storage_controller.dart';
import '../../models/app_user.dart';

class EditProfileView extends StatefulWidget {
  final AppUser user;

  const EditProfileView({super.key, required this.user});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _saving = false;
  bool _photoUpdating = false;
  late String _photoUrl;
  late String _selectedSport;
  late String _selectedSkillLevel;

  final List<String> _sportsOptions = const [
    'Soccer',
    'Basketball',
    'Tennis',
    'Volleyball',
    'Cricket',
    'Baseball',
    'Hockey',
    'Esports',
  ];

  final List<String> _skillLevels = const [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _bioController.text = widget.user.bio;
    _photoUrl = widget.user.photoUrl;
    _selectedSport = widget.user.primarySport.isNotEmpty
        ? widget.user.primarySport
        : _sportsOptions.first;
    _selectedSkillLevel = widget.user.skillLevel.isNotEmpty
        ? widget.user.skillLevel
        : _skillLevels.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
    final newBio = _bioController.text.trim();
    final authUser = AuthController.instance.currentUser;

    if (authUser == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await UserController.instance.updateUserDocument(
        uid: authUser.uid,
        data: {
          'name': newName,
          'photoUrl': _photoUrl,
          'primarySport': _selectedSport,
          'skillLevel': _selectedSkillLevel,
          'bio': newBio,
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving profile'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _changePhoto() async {
    final authUser = AuthController.instance.currentUser;

    if (authUser == null) {
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() {
      _photoUpdating = true;
    });

    try {
      final file = File(pickedFile.path);

      final url = await StorageController.instance.uploadProfilePhoto(
        uid: authUser.uid,
        file: file,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _photoUrl = url;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error uploading profile photo'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _photoUpdating = false;
        });
      }
    }
  }

  void _deletePhoto() {
    if (_photoUrl.isEmpty) {
      return;
    }

    setState(() {
      _photoUrl = '';
    });
  }

  Widget _buildSkillChip(String level, IconData icon) {
    final bool selected = _selectedSkillLevel == level;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(level),
        ],
      ),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedSkillLevel = level;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
                      child: _photoUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 40,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _photoUpdating ? null : _changePhoto,
                        child: CircleAvatar(
                          radius: 16,
                          child: _photoUpdating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                ),
                        ),
                      ),
                    ),
                    if (_photoUrl.isNotEmpty)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _photoUpdating ? null : _deletePhoto,
                          child: const CircleAvatar(
                            radius: 14,
                            child: Icon(
                              Icons.close,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedSport,
                decoration: const InputDecoration(
                  labelText: 'Favorite sport',
                  prefixIcon: Icon(Icons.sports),
                ),
                items: _sportsOptions
                    .map(
                      (sport) => DropdownMenuItem(
                        value: sport,
                        child: Text(sport),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedSport = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Icon(Icons.military_tech),
                    const SizedBox(width: 8),
                    Text(
                      'Skill level',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildSkillChip('Beginner', Icons.looks_one),
                  _buildSkillChip('Intermediate', Icons.looks_two),
                  _buildSkillChip('Advanced', Icons.looks_3),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'About you',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.info_outline),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 25),
              _saving
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
