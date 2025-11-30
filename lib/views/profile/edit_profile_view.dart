import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/storage_controller.dart';
import '../../models/app_user.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);

class EditProfileView extends StatefulWidget {
  final AppUser user;

  const EditProfileView({super.key, required this.user});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _saving = false;
  bool _photoUpdating = false;
  late String _photoUrl;
  late String _selectedSport;
  late String _selectedSkillLevel;
  bool _notifyGameUpdates = true;
  bool _notifyChatMessages = true;
  bool _notifyReminders = true;


  final List<String> _sportsOptions = const [
    'Soccer',
    'Basketball',
    'Tennis',
    'Volleyball',
    'Baseball',
    'Hockey',
  ];

  final List<String> _skillLevels = const [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.user.firstName;
    _lastNameController.text = widget.user.lastName;
    _bioController.text = widget.user.bio;
    _photoUrl = widget.user.photoUrl;
    _selectedSport = widget.user.primarySport.isNotEmpty
        ? widget.user.primarySport
        : _sportsOptions.first;
    _selectedSkillLevel = widget.user.skillLevel.isNotEmpty
        ? widget.user.skillLevel
        : _skillLevels.first;
    _notifyGameUpdates = widget.user.notifyGameUpdates;
    _notifyChatMessages = widget.user.notifyChatMessages;
    _notifyReminders = widget.user.notifyReminders;

  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final newFirstName = _firstNameController.text.trim();
    final newLastName = _lastNameController.text.trim();
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
          'firstName': newFirstName,
          'lastName': newLastName,
          'photoUrl': _photoUrl,
          'primarySport': _selectedSport,
          'skillLevel': _selectedSkillLevel,
          'bio': newBio,
          'notifyGameUpdates': _notifyGameUpdates,
          'notifyChatMessages': _notifyChatMessages,
          'notifyReminders': _notifyReminders,
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Player card updated!'),
          backgroundColor: kNeonGreen,
        ),
      );

      context.pop(true); // Return true to indicate successful save
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving profile'),
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
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
    return Scaffold(
      backgroundColor: kDarkNavy,
      appBar: AppBar(
        backgroundColor: kDarkNavy,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'EDIT PLAYER CARD',
          style: GoogleFonts.teko(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Player Photo Editor
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF243447),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kNeonGreen.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'PLAYER PHOTO',
                      style: GoogleFonts.teko(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kNeonGreen,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Stack(
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
                                color: kNeonGreen.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _photoUrl.isNotEmpty
                                ? Image.network(
                                    _photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: kDarkNavy,
                                        child: const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: kNeonGreen,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: kDarkNavy,
                                    child: const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: kNeonGreen,
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _photoUpdating ? null : _changePhoto,
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
                              child: _photoUpdating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Colors.black,
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
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Player Info Card
              Container(
                padding: const EdgeInsets.all(24),
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
                      'PLAYER INFO',
                      style: GoogleFonts.teko(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kNeonGreen,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Name
                    Container(
                      decoration: BoxDecoration(
                        color: kDarkNavy,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Player Name',
                          labelStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.person, color: kNeonGreen),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: kNeonGreen,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
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
              const SizedBox(height: 24),
              // Sport Selection
              Container(
                padding: const EdgeInsets.all(24),
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
                      'FAVORITE SPORT',
                      style: GoogleFonts.teko(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kNeonGreen,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sportsOptions.map((sport) {
                        final isSelected = _selectedSport == sport;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSport = sport;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? kNeonGreen : kDarkNavy,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? kNeonGreen : Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getSportIcon(sport),
                                  size: 20,
                                  color: isSelected ? Colors.black : kNeonGreen,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  sport,
                                  style: GoogleFonts.teko(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.black : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Skill Level
              Container(
                padding: const EdgeInsets.all(24),
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
                    Row(
                      children: [
                        const Icon(Icons.military_tech, color: kNeonGreen),
                        const SizedBox(width: 8),
                        Text(
                          'SKILL LEVEL',
                          style: GoogleFonts.teko(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kNeonGreen,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: _skillLevels.map((level) {
                        final isSelected = _selectedSkillLevel == level;
                        IconData icon;
                        switch (level) {
                          case 'Beginner':
                            icon = Icons.looks_one;
                            break;
                          case 'Intermediate':
                            icon = Icons.looks_two;
                            break;
                          case 'Advanced':
                            icon = Icons.looks_3;
                            break;
                          default:
                            icon = Icons.star;
                        }
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedSkillLevel = level;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? kNeonGreen : kDarkNavy,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? kNeonGreen : Colors.white.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      icon,
                                      size: 24,
                                      color: isSelected ? Colors.black : kNeonGreen,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      level,
                                      style: GoogleFonts.teko(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.black : Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Bio
              Container(
                padding: const EdgeInsets.all(24),
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
                      'ABOUT YOU',
                      style: GoogleFonts.teko(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kNeonGreen,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: kDarkNavy,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _bioController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Tell others about yourself...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: kNeonGreen,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
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
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Notification settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text(
                  'Game updates (joins/leaves, reschedules, cancellations)',
                ),
                value: _notifyGameUpdates,
                onChanged: (value) {
                  setState(() => _notifyGameUpdates = value);
                },
              ),
              SwitchListTile(
                title: const Text('Chat messages'),
                value: _notifyChatMessages,
                onChanged: (value) {
                  setState(() => _notifyChatMessages = value);
                },
              ),
              SwitchListTile(
                title: const Text('Game reminders'),
                value: _notifyReminders,
                onChanged: (value) {
                  setState(() => _notifyReminders = value);
                },
              ),

              const SizedBox(height: 25),
              _saving
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save'),
                    ),
              const SizedBox(height: 32),
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNeonGreen,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: kNeonGreen.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'SAVE PLAYER CARD',
                              style: GoogleFonts.teko(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
