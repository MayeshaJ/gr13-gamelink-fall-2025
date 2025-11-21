import 'dart:async';

import 'package:game_link_group13/models/game.dart';

class GameListController {
  GameListController._internal() {
    // Seed initial data on creation
    _gamesStreamController.add(List<Game>.unmodifiable(_mockGames));
  }

  static final GameListController instance = GameListController._internal();

  final StreamController<List<Game>> _gamesStreamController =
      StreamController<List<Game>>.broadcast();

  Stream<List<Game>> watchGames() {
    return _gamesStreamController.stream;
  }

  Future<List<Game>> fetchGames() async {
    // Simulate async fetch; replace with repository calls later
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List<Game>.unmodifiable(_mockGames);
  }

  Future<void> refresh() async {
    final List<Game> latest = await fetchGames();
    _gamesStreamController.add(latest);
  }

  // Mocked data until Firestore wiring is ready
  static final List<Game> _mockGames = <Game>[
    Game(
      id: 'g1',
      title: 'Pickup Soccer',
      hostName: 'Alex',
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      location: 'Central Park Field 3',
      status: GameStatus.open,
    ),
    Game(
      id: 'g2',
      title: '3v3 Basketball',
      hostName: 'Jamie',
      dateTime: DateTime.now().add(const Duration(days: 2, hours: 1)),
      location: 'Community Gym',
      status: GameStatus.open,
    ),
    Game(
      id: 'g3',
      title: 'Tennis Doubles',
      hostName: 'Riley',
      dateTime: DateTime.now().add(const Duration(days: 3, hours: 4)),
      location: 'Courts A/B',
      status: GameStatus.closed,
    ),
  ];
}


