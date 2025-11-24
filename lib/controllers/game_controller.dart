import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart';

class GameController {
  final CollectionReference gamesRef =
  FirebaseFirestore.instance.collection('games');

  // ─────────────────────────────────────────────────────────────
  // CREATE GAME
  // ─────────────────────────────────────────────────────────────
  Future<String> createGame(GameModel game) async {
    final doc = await gamesRef.add(game.toMap());
    return doc.id;
  }

  // ─────────────────────────────────────────────────────────────
  // GET ALL GAMES (for listing screen)
  // ─────────────────────────────────────────────────────────────
  Stream<List<GameModel>> getAllGames() {
    return gamesRef.orderBy('date').snapshots().map(
          (snapshot) {
        return snapshot.docs
            .map((doc) => GameModel.fromDocument(doc))
            .toList();
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // GET ONE GAME (for edit / host tools)
  // ─────────────────────────────────────────────────────────────
  Future<GameModel?> getGameById(String id) async {
    final doc = await gamesRef.doc(id).get();
    if (!doc.exists) return null;
    return GameModel.fromDocument(doc);
  }

  // ─────────────────────────────────────────────────────────────
  // EDIT GAME
  // ─────────────────────────────────────────────────────────────
  Future<void> updateGame(String id, Map<String, dynamic> data) async {
    await gamesRef.doc(id).update(data);
  }

  // ─────────────────────────────────────────────────────────────
  // CANCEL GAME
  // ─────────────────────────────────────────────────────────────
  Future<void> cancelGame(String id) async {
    await gamesRef.doc(id).update({'isCancelled': true});
  }
}
