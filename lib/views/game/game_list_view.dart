import 'package:flutter/material.dart';

import '../../controllers/game_list_controller.dart';
import '../../controllers/search_controller.dart' as gl;
import '../../models/game.dart';
import 'game_tile.dart';
import '../../widgets/loading_indicator.dart';
import 'game_list_empty.dart';

class GameListView extends StatefulWidget {
  const GameListView({super.key});

  @override
  State<GameListView> createState() => _GameListViewState();
}

class _GameListViewState extends State<GameListView> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: gl.SearchController.instance.state.query,
    );
    _searchController.addListener(_handleSearchChanged);
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    gl.SearchController.instance.updateQuery(_searchController.text);
  }

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
          if (allGames.isEmpty) {
            return GameListEmpty(
              onRefresh: () => GameListController.instance.refresh(),
            );
          }

          return StreamBuilder<gl.SearchState>(
            stream: gl.SearchController.instance.watch(),
            initialData: gl.SearchController.instance.state,
            builder:
                (BuildContext context, AsyncSnapshot<gl.SearchState> searchSnap) {
              final gl.SearchState search = searchSnap.data ??
                  const gl.SearchState(); // fallback to default state

              // Build sport options from current game list
              final List<String> sportOptions = allGames
                  .map((Game g) => g.sport.trim().toLowerCase())
                  .where((String sport) => sport.isNotEmpty)
                  .toSet()
                  .map(_capitalize)
                  .toList()
                ..sort();

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

              return Column(
                children: <Widget>[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: RawAutocomplete<String>(
                      textEditingController: _searchController,
                      focusNode: _searchFocusNode,
                      optionsBuilder: (TextEditingValue value) {
                        if (sportOptions.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        final String input = value.text.toLowerCase();
                        if (input.isEmpty) {
                          return sportOptions;
                        }
                        return sportOptions.where(
                          (String option) =>
                              option.toLowerCase().contains(input),
                        );
                      },
                      onSelected: (String selection) {
                        _searchController
                          ..text = selection
                          ..selection = TextSelection.collapsed(
                            offset: selection.length,
                          );
                        gl.SearchController.instance.updateQuery(selection);
                      },
                      fieldViewBuilder: (
                        BuildContext context,
                        TextEditingController controller,
                        FocusNode focusNode,
                        VoidCallback onFieldSubmitted,
                      ) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Search by game, location, or sport',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        );
                      },
                      optionsViewBuilder: (
                        BuildContext context,
                        AutocompleteOnSelected<String> onSelected,
                        Iterable<String> options,
                      ) {
                        if (options.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                                maxWidth: 360,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option =
                                      options.elementAt(index);
                                  return ListTile(
                                    title: Text(option),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
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

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }
  final String lower = value.toLowerCase();
  return lower[0].toUpperCase() + lower.substring(1);
}
