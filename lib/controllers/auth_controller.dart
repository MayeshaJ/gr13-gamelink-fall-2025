import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';

class AuthController {
  AuthController._internal();

  static final AuthController instance = AuthController._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get the Firebase User (not AppUser - use Firestore for full user data)
  User? get firebaseUser => _auth.currentUser;

  // Deprecated: Use firebaseUser and fetch from Firestore instead
  // Keeping for backward compatibility but returning minimal data
  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    // Return minimal AppUser - full data should come from Firestore
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      firstName: '',
      lastName: '',
      photoUrl: user.photoURL ?? '',
    );
  }

  Stream<User?> userChanges() {
    // Return Firebase User stream - fetch AppUser from Firestore when needed
    return _auth.authStateChanges();
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    // create a new user in firebase auth
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    // sign in user in firebase auth
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    // send reset email to user if account exists
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Obtain the auth details from the request
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    // sign out current user from firebase auth and google sign in
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}