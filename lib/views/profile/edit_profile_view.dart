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
  bool _saving = false;
  bool _photoUpdating = false;
  late String _photoUrl;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name;
    _photoUrl = widget.user.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final newName = _nameController.text.trim();
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

      // update only local preview
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

    // only clear local preview
    setState(() {
      _photoUrl = '';
    });
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
              ),
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
    );
  }
}
