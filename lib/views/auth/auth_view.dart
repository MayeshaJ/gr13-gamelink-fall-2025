import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthController.instance.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;
      context.goNamed('home');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Login failed');
    } catch (_) {
      _showError('Unexpected error during login');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthController.instance.signUp(
        email: email,
        password: password,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await UserController.instance.createUserDocument(
          uid: user.uid,
          email: user.email ?? '',
          firstName: firstName,
          lastName: lastName,
        );
      }

      if (!mounted) return;
      context.goNamed('home');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Signup failed');
    } catch (_) {
      _showError('Unexpected error during signup');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      final userCredential = await AuthController.instance.signInWithGoogle();

      if (userCredential == null) {
        if (mounted) {
          setState(() => _isGoogleLoading = false);
        }
        return;
      }

      final user = userCredential.user;
      if (user != null) {
        final userDoc = await UserController.instance.getUserDocument(uid: user.uid);
        if (userDoc == null) {
          final nameParts = _splitName(user.displayName);
          await UserController.instance.createUserDocument(
            uid: user.uid,
            email: user.email ?? '',
            firstName: nameParts['firstName'] ?? '',
            lastName: nameParts['lastName'] ?? '',
            photoUrl: user.photoURL ?? '',
          );
        }
      }

      if (!mounted) return;
      context.goNamed('home');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Google sign-in failed');
    } catch (e) {
      _showError('Unexpected error during Google sign-in');
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Map<String, String> _splitName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) {
      return {'firstName': '', 'lastName': ''};
    }
    
    final nameParts = displayName.trim().split(' ');
    if (nameParts.isEmpty) {
      return {'firstName': '', 'lastName': ''};
    }
    
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    
    return {'firstName': firstName, 'lastName': lastName};
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkNavy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // GAMELINK Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'GAME',
                      style: GoogleFonts.teko(
                        fontSize: 40.sp,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    Text(
                      'LINK',
                      style: GoogleFonts.teko(
                        fontSize: 40.sp,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: kNeonGreen,
                        height: 1,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 28.h),

                // Auth Card
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF243447),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Custom Tab Bar
                      Row(
                        children: [
                          // Sign In Tab
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _tabController.animateTo(0),
                              child: AnimatedBuilder(
                                animation: _tabController,
                                builder: (context, child) {
                                  final isActive = _tabController.index == 0;
                                  return Column(
                                    children: [
                                      Text(
                                        'SIGN IN',
                                        style: GoogleFonts.teko(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          fontStyle: FontStyle.italic,
                                          color: isActive ? Colors.white : Colors.grey,
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                      Container(
                                        height: 2.h,
                                        decoration: BoxDecoration(
                                          color: isActive ? kNeonGreen : Colors.transparent,
                                          borderRadius: BorderRadius.circular(1.r),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),

                          SizedBox(width: 12.w),

                          // Join Club Tab
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _tabController.animateTo(1),
                              child: AnimatedBuilder(
                                animation: _tabController,
                                builder: (context, child) {
                                  final isActive = _tabController.index == 1;
                                  return Column(
                                    children: [
                                      Text(
                                        'JOIN CLUB',
                                        style: GoogleFonts.teko(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          fontStyle: FontStyle.italic,
                                          color: isActive ? Colors.white : Colors.grey,
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                      Container(
                                        height: 2.h,
                                        decoration: BoxDecoration(
                                          color: isActive ? kNeonGreen : Colors.transparent,
                                          borderRadius: BorderRadius.circular(1.r),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // First Name and Last Name (only for Sign Up)
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          if (_tabController.index == 1) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInputField(
                                        controller: _firstNameController,
                                        hintText: 'First Name',
                                        icon: Icons.person_outline,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: _buildInputField(
                                        controller: _lastNameController,
                                        hintText: 'Last Name',
                                        icon: Icons.person_outline,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Email Field
                      _buildInputField(
                        controller: _emailController,
                        hintText: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      SizedBox(height: 12.h),

                      // Password Field
                      _buildInputField(
                        controller: _passwordController,
                        hintText: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),

                      SizedBox(height: 12.h),

                      // Confirm Password (only for Sign Up)
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          if (_tabController.index == 1) {
                            return Column(
                              children: [
                                _buildInputField(
                                  controller: _confirmPasswordController,
                                  hintText: 'Confirm Password',
                                  icon: Icons.lock_outline,
                                  obscureText: true,
                                ),
                                SizedBox(height: 12.h),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Forgot Password (only for Sign In)
                      AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          if (_tabController.index == 0) {
                            return Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.pushNamed('forgot-password'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.barlowSemiCondensed(
                                    color: kNeonGreen,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      SizedBox(height: 16.h),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: _isLoading || _isGoogleLoading
                              ? null
                              : () {
                                  if (_tabController.index == 0) {
                                    _handleLogin();
                                  } else {
                                    _handleSignup();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kNeonGreen,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: kNeonGreen.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _tabController.index == 0 ? 'ENTER GAME' : 'CREATE ACCOUNT',
                                        style: GoogleFonts.barlowSemiCondensed(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Icon(Icons.arrow_forward, size: 18.sp),
                                  ],
                                ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Divider with "OR"
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.2),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: Text(
                              'OR',
                              style: GoogleFonts.barlowSemiCondensed(
                                fontSize: 13.sp,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withOpacity(0.2),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // Google Sign-In Button
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: OutlinedButton(
                          onPressed: _isLoading || _isGoogleLoading ? null : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: _isGoogleLoading
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/google_logo.png',
                                      height: 20.h,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.g_mobiledata,
                                          size: 22.sp,
                                          color: Colors.white,
                                        );
                                      },
                                    ),
                                    SizedBox(width: 8.w),
                                    Flexible(
                                      child: Text(
                                        'CONTINUE WITH GOOGLE',
                                        style: GoogleFonts.barlowSemiCondensed(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.barlowSemiCondensed(color: Colors.white, fontSize: 15.sp),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.barlowSemiCondensed(
          color: Colors.grey[500],
          fontSize: 14.sp,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.grey[600],
          size: 20.sp,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 14.h,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: kNeonGreen, width: 2),
        ),
      ),
    );
  }
}


