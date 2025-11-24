import 'package:cloud_firestore/cloud_firestore.dart';

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
