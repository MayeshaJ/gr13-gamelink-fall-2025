import 'package:flutter/material.dart';

import '../../controllers/game_list_controller.dart';
import '../../models/game.dart';
import 'game_tile.dart';

class GameListView extends StatelessWidget {
  const GameListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
      ),
      body: StreamBuilder<List<Game>>(
        stream: GameListController.instance.watchGames(),
        builder: (BuildContext context, AsyncSnapshot<List<Game>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Game> games = snapshot.data ?? <Game>[];
          if (games.isEmpty) {
            return const Center(child: Text('No games yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              final Game game = games[index];
              return GameTile(game: game);
            },
          );
        },
      ),
    );
  }
}

