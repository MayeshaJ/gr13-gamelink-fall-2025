import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 22.sp),
        ),
        title: Text(
          'EDIT PLAYER CARD',
          style: GoogleFonts.teko(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            children: [
              // Player Photo Editor
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF243447),
                  borderRadius: BorderRadius.circular(10.r),
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
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: kNeonGreen,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Stack(
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
                                color: kNeonGreen.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 1,
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
                                        child: Icon(
                                          Icons.person,
                                          size: 40.sp,
                                          color: kNeonGreen,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: kDarkNavy,
                                    child: Icon(
                                      Icons.person,
                                      size: 40.sp,
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
                              child: _photoUpdating
                                  ? SizedBox(
                                      width: 16.w,
                                      height: 16.h,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : Icon(
                                      Icons.camera_alt,
                                      size: 16.sp,
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
                                padding: EdgeInsets.all(4.w),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 14.sp,
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
              SizedBox(height: 16.h),
              // Player Info Card
              Container(
                padding: EdgeInsets.all(16.w),
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
                      'PLAYER INFO',
                      style: GoogleFonts.teko(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: kNeonGreen,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    // First Name
                    TextField(
                      controller: _firstNameController,
                      style: GoogleFonts.barlowSemiCondensed(color: Colors.white, fontSize: 14.sp),
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        labelStyle: GoogleFonts.barlowSemiCondensed(color: Colors.grey[400], fontSize: 13.sp),
                        prefixIcon: Icon(Icons.person, color: kNeonGreen, size: 20.sp),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: kNeonGreen, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    // Last Name
                    TextField(
                      controller: _lastNameController,
                      style: GoogleFonts.barlowSemiCondensed(color: Colors.white, fontSize: 14.sp),
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        labelStyle: GoogleFonts.barlowSemiCondensed(color: Colors.grey[400], fontSize: 13.sp),
                        prefixIcon: Icon(Icons.person_outline, color: kNeonGreen, size: 20.sp),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: kNeonGreen, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              // Sport Selection
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
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
                      'FAVORITE SPORT',
                      style: GoogleFonts.teko(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: kNeonGreen,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      alignment: WrapAlignment.start,
                      children: _sportsOptions.map((sport) {
                        final isSelected = _selectedSport == sport;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSport = sport;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? kNeonGreen : kDarkNavy,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: isSelected ? kNeonGreen : Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getSportIcon(sport),
                                  size: 16.sp,
                                  color: isSelected ? Colors.black : kNeonGreen,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  sport,
                                  style: GoogleFonts.barlowSemiCondensed(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
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
              SizedBox(height: 16.h),
              // Skill Level
              Container(
                padding: EdgeInsets.all(16.w),
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
                        Icon(Icons.military_tech, color: kNeonGreen, size: 18.sp),
                        SizedBox(width: 6.w),
                        Text(
                          'SKILL LEVEL',
                          style: GoogleFonts.teko(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: kNeonGreen,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
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
                            padding: EdgeInsets.symmetric(horizontal: 3.w),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedSkillLevel = level;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  color: isSelected ? kNeonGreen : kDarkNavy,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: isSelected ? kNeonGreen : Colors.white.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      icon,
                                      size: 20.sp,
                                      color: isSelected ? Colors.black : kNeonGreen,
                                    ),
                                    SizedBox(height: 3.h),
                                    Text(
                                      level,
                                      style: GoogleFonts.barlowSemiCondensed(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
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
              SizedBox(height: 16.h),
              // Bio
              Container(
                padding: EdgeInsets.all(16.w),
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
                      'ABOUT YOU',
                      style: GoogleFonts.teko(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: kNeonGreen,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _bioController,
                      style: GoogleFonts.barlowSemiCondensed(color: Colors.white, fontSize: 14.sp),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Tell others about yourself...',
                        hintStyle: GoogleFonts.barlowSemiCondensed(color: Colors.grey[500], fontSize: 13.sp),
                        contentPadding: EdgeInsets.all(12.w),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: kNeonGreen, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNeonGreen,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: kNeonGreen.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? SizedBox(
                          height: 18.h,
                          width: 18.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'SAVE PLAYER CARD',
                              style: GoogleFonts.barlowSemiCondensed(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
