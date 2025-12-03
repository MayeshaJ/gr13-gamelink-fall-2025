import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);


class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    // clean up controllers when screen is destroyed
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthController.instance.signIn(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      // go to home view after successful login
      if (!mounted) return;
      context.goNamed('home');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Login failed'),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unexpected error during login'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToSignup() {
    // navigate to signup view
    context.goNamed('signup');
  }

  // Helper function to split display name into first and last name
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

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final userCredential = await AuthController.instance.signInWithGoogle();

      if (userCredential == null) {
        // User canceled the sign-in
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
          });
        }
        return;
      }

      final user = userCredential.user;
      if (user != null) {
        // Check if user document exists, if not create it
        final userDoc = await UserController.instance.getUserDocument(uid: user.uid);
        if (userDoc == null) {
          // Extract firstName and lastName from displayName
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

      if (!mounted) {
        return;
      }

      // go to home view after successful login
      context.goNamed('home');
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Google sign-in failed'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during Google sign-in: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Body text style using Barlow Semi Condensed
    final bodyStyle = GoogleFonts.barlowSemiCondensed(
      fontSize: 15.sp,
      color: Colors.white,
    );
    
    final labelStyle = GoogleFonts.barlowSemiCondensed(
      fontSize: 14.sp,
      color: Colors.grey[400],
    );

    return Scaffold(
      backgroundColor: kDarkNavy,
      appBar: AppBar(
        backgroundColor: kDarkNavy,
        elevation: 0,
        title: Text(
          'LOGIN',
          style: GoogleFonts.teko(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20.h),
              // Email Field
              TextField(
                controller: _emailController,
                style: bodyStyle,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: labelStyle,
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[500], size: 20.sp),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: kNeonGreen, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                ),
              ),
              SizedBox(height: 12.h),
              // Password Field
              TextField(
                controller: _passwordController,
                style: bodyStyle,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: labelStyle,
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500], size: 20.sp),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: Colors.grey[500],
                      size: 20.sp,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: kNeonGreen, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                ),
              ),
              SizedBox(height: 20.h),
              // Login Button
              SizedBox(
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNeonGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          'LOG IN',
                          style: GoogleFonts.barlowSemiCondensed(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16.h),
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
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
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                ],
              ),
              SizedBox(height: 16.h),
              // Google Sign-In Button
              SizedBox(
                height: 50.h,
                child: OutlinedButton.icon(
                  onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                  icon: _isGoogleLoading
                      ? SizedBox(
                          height: 18.h,
                          width: 18.w,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(Icons.g_mobiledata, size: 22.sp, color: Colors.white),
                  label: Text(
                    'Continue with Google',
                    style: GoogleFonts.barlowSemiCondensed(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              // Create Account Link
              TextButton(
                onPressed: _goToSignup,
                child: Text(
                  'Create an account',
                  style: GoogleFonts.barlowSemiCondensed(
                    fontSize: 14.sp,
                    color: kNeonGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Forgot Password Link
              TextButton(
                onPressed: () => context.pushNamed('forgot-password'),
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.barlowSemiCondensed(
                    fontSize: 14.sp,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
