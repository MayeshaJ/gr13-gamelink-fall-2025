import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageController {
  StorageController._internal();

  static final StorageController instance = StorageController._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    // upload profile photo to Firebase Storage
    final ref = _storage.ref().child('profile_photos').child('$uid.jpg');

    await ref.putFile(file);

    final url = await ref.getDownloadURL();
    return url;
  }
}
