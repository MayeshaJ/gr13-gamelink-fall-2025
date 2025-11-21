import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthController {
  AuthController._internal();

  static final AuthController instance = AuthController._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppUser? get currentUser {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
    );
  }

  Stream<AppUser?> userChanges() {
    // map firebase user stream to our app user model
    return _auth.authStateChanges().map((user) {
      if (user == null) {
        return null;
      }
      return AppUser(
        uid: user.uid,
        email: user.email ?? '',
      );
    });
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

  Future<void> signOut() async {
    // sign out current user from firebase auth
    await _auth.signOut();
  }
}
