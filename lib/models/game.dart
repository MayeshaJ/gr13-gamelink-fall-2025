// lib/models/game.dart
enum GameStatus { open, closed }

class Game {
  final String id;
  final String title;
  final String hostName;
  final DateTime dateTime;
  final String location;
  final String sport;
  final GameStatus status;

  const Game({
    required this.id,
    required this.title,
    required this.hostName,
    required this.dateTime,
    required this.location,
    required this.sport,
    required this.status,
  });

  Game copyWith({
    String? id,
    String? title,
    String? hostName,
    DateTime? dateTime,
    String? location,
    String? sport,
    GameStatus? status,
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      hostName: hostName ?? this.hostName,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      sport: sport ?? this.sport,
      status: status ?? this.status,
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