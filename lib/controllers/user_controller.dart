import 'package:cloud_firestore/cloud_firestore.dart';

class UserController {
  UserController._internal();

  static final UserController instance = UserController._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createUserDocument({
    required String uid,
    required String email,
    String firstName = '',
    String lastName = '',
    String photoUrl = '',
  }) async {
    // create a user document in Firestore
    // Check if document already exists to avoid overwriting existing data
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      // Document already exists, don't overwrite
      return;
    }
    
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'primarySport': '',
      'skillLevel': '',
      'bio': '',
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

  Future<void> updateUserDocument({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    // update selected fields in Firestore
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> clearUserPhoto({
    required String uid,
  }) async {
    // remove saved photo url
    await _db.collection('users').doc(uid).update({
      'photoUrl': '',
    });
  }
}
