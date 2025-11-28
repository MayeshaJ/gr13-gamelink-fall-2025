import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/game_list_controller.dart';
import '../../controllers/search_controller.dart' as gl;
import '../../models/game.dart';
import 'game_tile.dart';
import '../../widgets/loading_indicator.dart';
import 'game_list_empty.dart';

class GameListView extends StatefulWidget {
  const GameListView({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<GameListView> createState() => _GameListViewState();
}

class _GameListViewState extends State<GameListView> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  bool _suppressSearchListener = false;
  String _syncedQuery = '';

  @override
  void initState() {
    super.initState();
    final String initialQuery =
        widget.initialQuery ?? gl.SearchController.instance.state.query;
    _syncedQuery = initialQuery;
    _searchController = TextEditingController(text: initialQuery);
    gl.SearchController.instance.updateQuery(initialQuery);
    _searchController.addListener(_handleSearchChanged);
    _searchFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant GameListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String newQuery = widget.initialQuery ?? '';
    if (newQuery != _syncedQuery) {
      _applyRouterQuery(newQuery);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    if (_suppressSearchListener) {
      return;
    }
    final String newQuery = _searchController.text;
    gl.SearchController.instance.updateQuery(newQuery);
    if (newQuery == _syncedQuery) {
      return;
    }
    _syncedQuery = newQuery;
    _updateQueryParam(newQuery);
  }

  void _applyRouterQuery(String value) {
    _suppressSearchListener = true;
    _searchController
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
    _suppressSearchListener = false;
    _syncedQuery = value;
    gl.SearchController.instance.updateQuery(value);
  }

  void _updateQueryParam(String value) {
    final Map<String, String> params = <String, String>{};
    if (value.isNotEmpty) {
      params['q'] = value;
    }
    context.goNamed('games', queryParameters: params);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: StreamBuilder<List<Game>>(
        stream: GameListController.instance.watchGames(),
        initialData: <Game>[], // Provide initial data to prevent waiting state
        builder: (BuildContext context, AsyncSnapshot<List<Game>> snapshot) {
          // With initialData, snapshot should always have data
          // Only show loading on first connection if we truly have no data
          if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
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

          final List<Game> allGames = snapshot.data ?? <Game>[];
          
          // Use StreamBuilder for search state with proper initial data
          return StreamBuilder<gl.SearchState>(
            stream: gl.SearchController.instance.watch(),
            initialData: gl.SearchController.instance.state,
            builder:
                (BuildContext context, AsyncSnapshot<gl.SearchState> searchSnap) {
              // Use search state from snapshot or fallback to current state
              final gl.SearchState search = searchSnap.connectionState == ConnectionState.waiting
                  ? gl.SearchController.instance.state
                  : (searchSnap.data ?? gl.SearchController.instance.state);

              // Apply filters
              final String q = search.query.trim().toLowerCase();
              bool matches(Game g) {
                if (q.isEmpty) {
                  return true;
                }
                final String sport = g.sport.toLowerCase();
                final String host = g.hostName.toLowerCase();
                final String title = g.title.toLowerCase();
                final String location = g.location.toLowerCase();
                return sport.contains(q) ||
                    host.contains(q) ||
                    title.contains(q) ||
                    location.contains(q);
              }

              final List<Game> games =
                  allGames.where((Game g) => matches(g)).toList();
              
              // Show empty state if no games match search
              if (allGames.isEmpty) {
                return GameListEmpty(
                  onRefresh: () => GameListController.instance.refresh(),
                );
              }

              return Column(
                children: <Widget>[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Search by game, location, or sport',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => GameListController.instance.refresh(),
                      child: games.isEmpty
                          ? SingleChildScrollView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 48),
                                child: GameListEmpty(
                                  onRefresh: () => GameListController.instance
                                      .refresh(),
                                ),
                              ),
                            )
                          : ListView.separated(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: games.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder:
                                  (BuildContext context, int index) {
                                final Game game = games[index];
                                return GameTile(game: game);
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
