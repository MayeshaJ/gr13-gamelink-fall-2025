import 'package:flutter/material.dart';

import '../../controllers/game_list_controller.dart';
import '../../models/game.dart';
import 'game_tile.dart';
import '../../widgets/loading_indicator.dart';
import 'game_list_empty.dart';

class GameListView extends StatelessWidget {
  const GameListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
      ),
      body: RefreshIndicator(
        onRefresh: () => GameListController.instance.refresh(),
        child: StreamBuilder<List<Game>>(
          stream: GameListController.instance.watchGames(),
          builder: (BuildContext context, AsyncSnapshot<List<Game>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingIndicator(message: 'Loading games...');
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('Failed to load games'),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => GameListController.instance.refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final List<Game> games = snapshot.data ?? <Game>[];
            if (games.isEmpty) {
              return GameListEmpty(
                onRefresh: () => GameListController.instance.refresh(),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }
}

