import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatController {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // This is our message model inside the subcollection:
  // games/{gameId}/messages/{messageId}

  Future<void> sendMessage({
    required String gameId,
    required String text,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception("Not logged in");
    }

    final messageData = {
      "senderId": currentUser.uid,
      "senderName": currentUser.displayName ?? "Unknown",
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
    };

    await _db
        .collection("games")
        .doc(gameId)
        .collection("messages")
        .add(messageData);
  }
}
