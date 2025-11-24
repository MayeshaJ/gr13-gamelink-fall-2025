import 'package:cloud_firestore/cloud_firestore.dart';

class UserController {
  UserController._internal();

  static final UserController instance = UserController._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserDocument({
    required String uid,
    required String email,
  }) async {
    // create a user document in Firestore
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getUserDocument({
    required String uid,
  }) async {
    // read user document from Firestore
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    return doc.data();
  }
}
