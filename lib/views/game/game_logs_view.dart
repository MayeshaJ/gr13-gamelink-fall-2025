import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../controllers/game_controller.dart';
import '../../models/game.dart';
import '../../widgets/loading_indicator.dart';
import 'game_log_tile.dart';

/// Displays all games hosted by the currently logged-in user.
/// Provides Edit and Delete functionality for each game.
class GameLogsView extends StatefulWidget {
  const GameLogsView({super.key});

  @override
  State<GameLogsView> createState() => _GameLogsViewState();
}

class _GameLogsViewState extends State<GameLogsView> {
  final GameController _gameController = GameController();
  
  // Stream subscription management
  Stream<List<GameModel>>? _gamesStream;
  String? _userId;
  
  // Key to force StreamBuilder rebuild when needed
  int _streamKey = 0;

  @override
  void initState() {
    super.initState();
    _initStream();
  }
  
  void _initStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      _gamesStream = _gameController.getGamesByHost(user.uid);
    }
  }
  
  /// Force refresh the stream (called after edits)
  void _refreshStream() {
    setState(() {
      _streamKey++;
      _gamesStream = _gameController.getGamesByHost(_userId!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || _gamesStream == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Hosted Games')),
        body: const Center(
          child: Text('Please log in to view your hosted games.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Hosted Games'),
      ),
      body: StreamBuilder<List<GameModel>>(
        key: ValueKey(_streamKey),
        stream: _gamesStream,
        builder: (BuildContext context, AsyncSnapshot<List<GameModel>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading your games...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load your games',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<GameModel> games = snapshot.data ?? [];

          if (games.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.sports_esports_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hosted games yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Games you create will appear here.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Separate active and cancelled games
          final activeGames = games.where((g) => !g.isCancelled).toList();
          final cancelledGames = games.where((g) => g.isCancelled).toList();

          return RefreshIndicator(
            onRefresh: () async {
              _refreshStream();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Active games section
                if (activeGames.isNotEmpty) ...[
                  Text(
                    'Active Games (${activeGames.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...activeGames.map((game) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GameLogTile(
                          game: game,
                          onGameUpdated: _refreshStream,
                          onGameDeleted: _refreshStream,
                        ),
                      )),
                ],

                // Cancelled games section
                if (cancelledGames.isNotEmpty) ...[
                  if (activeGames.isNotEmpty) const SizedBox(height: 16),
                  Text(
                    'Cancelled Games (${cancelledGames.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...cancelledGames.map((game) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GameLogTile(
                          game: game,
                          onGameUpdated: _refreshStream,
                          onGameDeleted: _refreshStream,
                        ),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

