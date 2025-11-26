import 'package:cloud_firestore/cloud_firestore.dart';

// ───────────────────────────────────────────────
// GameModel: Full Firestore-integrated model (Team's implementation)
// ───────────────────────────────────────────────
class GameModel {
  final String id;                 // game document ID
  final String hostId;             // user ID of host
  final String title;              // game name
  final String description;        // details about the game
  final DateTime date;             // game date/time
  final String location;           // address or field location
  final int maxPlayers;            // max participants
  final List<String> participants; // joined user IDs
  final List<String> waitlist;     // waitlisted user IDs
  final bool isCancelled;          // cancellation flag
  final DateTime createdAt;

  GameModel({
    required this.id,
    required this.hostId,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.maxPlayers,
    required this.participants,
    required this.waitlist,
    required this.isCancelled,
    required this.createdAt,
  });

  // ───────────────────────────────────────────────
  // Convert Firestore → GameModel
  // ───────────────────────────────────────────────
  factory GameModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GameModel(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      maxPlayers: data['maxPlayers'] ?? 0,
      participants: List<String>.from(data['participants'] ?? []),
      waitlist: List<String>.from(data['waitlist'] ?? []),
      isCancelled: data['isCancelled'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // ───────────────────────────────────────────────
  // Convert GameModel → Firestore
  // ───────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'location': location,
      'maxPlayers': maxPlayers,
      'participants': participants,
      'waitlist': waitlist,
      'isCancelled': isCancelled,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ───────────────────────────────────────────────
  // Clone with modifications
  // ───────────────────────────────────────────────
  GameModel copyWith({
    String? title,
    String? description,
    DateTime? date,
    String? location,
    int? maxPlayers,
    List<String>? participants,
    List<String>? waitlist,
    bool? isCancelled,
  }) {
    return GameModel(
      id: id,
      hostId: hostId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      location: location ?? this.location,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      participants: participants ?? this.participants,
      waitlist: waitlist ?? this.waitlist,
      isCancelled: isCancelled ?? this.isCancelled,
      createdAt: createdAt,
    );
  }
}

// ───────────────────────────────────────────────
// Game: Minimal model for game list skeleton (Mayesha's implementation)
// ───────────────────────────────────────────────
enum GameStatus { open, closed }

class Game {
  final String id;
  final String title;
  final String hostName;
  final DateTime dateTime;
  final String location;
  final String sport;
  final GameStatus status;
  final List<String> participantIds; // Added to track participants

  const Game({
    required this.id,
    required this.title,
    required this.hostName,
    required this.dateTime,
    required this.location,
    required this.sport,
    required this.status,
    this.participantIds = const [], // Default to empty list
  });

  Game copyWith({
    String? id,
    String? title,
    String? hostName,
    DateTime? dateTime,
    String? location,
    String? sport,
    GameStatus? status,
    List<String>? participantIds,
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      hostName: hostName ?? this.hostName,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      sport: sport ?? this.sport,
      status: status ?? this.status,
      participantIds: participantIds ?? this.participantIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'hostName': hostName,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'sport': sport,
      'status': status.name,
      'participantIds': participantIds,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as String,
      title: map['title'] as String,
      hostName: map['hostName'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      location: map['location'] as String,
      sport: map['sport'] as String,
      status: _statusFromString(map['status'] as String),
      participantIds: List<String>.from(map['participantIds'] ?? []),
    );
  }

  static GameStatus _statusFromString(String value) {
    switch (value) {
      case 'open':
        return GameStatus.open;
      case 'closed':
        return GameStatus.closed;
      default:
        return GameStatus.open;
    }
  }
}
