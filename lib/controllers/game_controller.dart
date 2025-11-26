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
  // Note: If orderBy('date') fails due to missing index,
  // the error will be caught in GameListController
  // ─────────────────────────────────────────────────────────────
  Stream<List<GameModel>> getAllGames({bool useOrderBy = true}) {
    final query = useOrderBy 
        ? gamesRef.orderBy('date')
        : gamesRef;
    
    print('GameController: Starting Firestore query (useOrderBy: $useOrderBy)');
    
    try {
      return query.snapshots().map(
            (snapshot) {
          print('GameController: Firestore snapshot received with ${snapshot.docs.length} documents');
          return snapshot.docs
              .map((doc) {
                try {
                  return GameModel.fromDocument(doc);
                } catch (e) {
                  // Skip invalid documents and log error
                  print('GameController: Error parsing game document ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<GameModel>()
              .toList();
        },
      ).handleError((error) {
        print('GameController: Error in Firestore stream: $error');
        // Re-throw so GameListController can handle it
        throw error;
      });
    } catch (e) {
      print('GameController: Exception creating stream: $e');
      // Return a stream that emits empty list on error
      return Stream.value(<GameModel>[]);
    }
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

  // ─────────────────────────────────────────────────────────────
  // JOIN GAME
  // ─────────────────────────────────────────────────────────────
  Future<void> joinGame(String gameId, String userId) async {
    final docRef = gamesRef.doc(gameId);
    
    // Use transaction to ensure atomicity
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) {
        throw Exception('Game not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final List<String> participants = List<String>.from(data['participants'] ?? []);
      final int maxPlayers = data['maxPlayers'] ?? 0;
      final bool isCancelled = data['isCancelled'] ?? false;

      if (isCancelled) {
        throw Exception('Game has been cancelled');
      }

      if (participants.contains(userId)) {
        throw Exception('You are already a participant');
      }

      if (participants.length >= maxPlayers) {
        throw Exception('Game is full');
      }

      // Add user to participants list
      participants.add(userId);
      transaction.update(docRef, {'participants': participants});
    });
  }

  // ─────────────────────────────────────────────────────────────
  // LEAVE GAME
  // ─────────────────────────────────────────────────────────────
  Future<void> leaveGame(String gameId, String userId) async {
    final docRef = gamesRef.doc(gameId);
    
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) {
        throw Exception('Game not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final List<String> participants = List<String>.from(data['participants'] ?? []);

      if (!participants.contains(userId)) {
        throw Exception('You are not a participant');
      }

      // Remove user from participants list
      participants.remove(userId);
      transaction.update(docRef, {'participants': participants});
    });
  }

  // ─────────────────────────────────────────────────────────────
  // GET GAME STREAM (for real-time updates)
  // ─────────────────────────────────────────────────────────────
  Stream<GameModel?> watchGame(String id) {
    return gamesRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GameModel.fromDocument(doc);
    });
  }
}
