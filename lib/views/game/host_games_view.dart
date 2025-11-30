import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/game_controller.dart';
import '../../models/game.dart';
import '../../widgets/loading_indicator.dart';
import 'game_log_tile.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);

/// Host Games page - shows create game button and list of hosted games
class HostGamesView extends StatefulWidget {
  const HostGamesView({super.key});

  @override
  State<HostGamesView> createState() => _HostGamesViewState();
}

class _HostGamesViewState extends State<HostGamesView> {
  final GameController _gameController = GameController();
  
  // Stream management
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
        backgroundColor: kDarkNavy,
        appBar: AppBar(
          backgroundColor: kDarkNavy,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'HOST GAMES',
            style: GoogleFonts.teko(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => context.pushNamed('notifications'),
              icon: const Icon(
                Icons.notifications_outlined,
                color: kNeonGreen,
              ),
            ),
          ],
        ),
        body: Center(
          child: Text(
            'Please log in to host games.',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kDarkNavy,
      appBar: AppBar(
        backgroundColor: kDarkNavy,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'HOST GAMES',
          style: GoogleFonts.teko(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.pushNamed('notifications'),
            icon: const Icon(
              Icons.notifications_outlined,
              color: kNeonGreen,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Create Game Button at the top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => context.pushNamed('create-game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'CREATE A GAME',
                      style: GoogleFonts.teko(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Divider
          const Divider(height: 1),
          
          // Hosted Games List
          Expanded(
            child: StreamBuilder<List<GameModel>>(
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
                            onPressed: _refreshStream,
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
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'NO HOSTED GAMES YET',
                            style: GoogleFonts.teko(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap "Create a Game" to get started!',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
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
                          'ACTIVE GAMES (${activeGames.length})',
                          style: GoogleFonts.teko(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: kNeonGreen,
                            letterSpacing: 1,
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
                        if (activeGames.isNotEmpty) const SizedBox(height: 24),
                        Text(
                          'CANCELLED GAMES (${cancelledGames.length})',
                          style: GoogleFonts.teko(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                            letterSpacing: 1,
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
          ),
        ],
      ),
    );
  }
}

