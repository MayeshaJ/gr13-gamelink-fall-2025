import 'dart:async';

import 'package:game_link_group13/models/game.dart';

class GameListController {
  GameListController._internal() {
    _currentGames = List<Game>.from(_mockGames);
    _gamesStreamController = StreamController<List<Game>>.broadcast(
      onListen: () {
        // Immediately deliver the latest snapshot to new listeners
        _gamesStreamController.add(List<Game>.unmodifiable(_currentGames));
      },
    );
  }

  static final GameListController instance = GameListController._internal();

  late final StreamController<List<Game>> _gamesStreamController;
  List<Game> _currentGames = const <Game>[];

  Stream<List<Game>> watchGames() {
    return _gamesStreamController.stream;
  }

  Future<List<Game>> fetchGames() async {
    // Simulate async fetch; replace with repository calls later
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List<Game>.unmodifiable(_currentGames);
  }

  Future<void> refresh() async {
    final List<Game> latest = await fetchGames();
    _currentGames = List<Game>.from(latest);
    _gamesStreamController.add(List<Game>.unmodifiable(_currentGames));
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


