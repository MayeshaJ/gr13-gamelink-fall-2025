import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => context.pushNamed('notifications'),
              icon: Icon(
                Icons.notifications_outlined,
                color: kNeonGreen,
                size: 22.sp,
              ),
            ),
          ],
        ),
        body: Center(
          child: Text(
            'Please log in to host games.',
            style: GoogleFonts.barlowSemiCondensed(color: Colors.grey[400], fontSize: 14.sp),
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
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.pushNamed('notifications'),
            icon: Icon(
              Icons.notifications_outlined,
              color: kNeonGreen,
              size: 22.sp,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Create Game Button at the top
          Padding(
            padding: EdgeInsets.all(12.w),
            child: SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton(
                onPressed: () => context.pushNamed('create-game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'CREATE A GAME',
                      style: GoogleFonts.barlowSemiCondensed(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
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
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.error_outline,
                            size: 40.sp,
                            color: Colors.red,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Failed to load your games',
                            style: GoogleFonts.barlowSemiCondensed(fontSize: 14.sp, color: Colors.white),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.barlowSemiCondensed(color: Colors.grey, fontSize: 12.sp),
                          ),
                          SizedBox(height: 12.h),
                          SizedBox(
                            height: 40.h,
                            child: ElevatedButton(
                              onPressed: _refreshStream,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kNeonGreen,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                              ),
                              child: Text('Retry', style: GoogleFonts.barlowSemiCondensed(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                            ),
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
                      padding: EdgeInsets.all(20.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.sports_esports_outlined,
                            size: 48.sp,
                            color: Colors.grey[600],
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'NO HOSTED GAMES YET',
                            style: GoogleFonts.teko(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[400],
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Tap "Create a Game" to get started!',
                            style: GoogleFonts.barlowSemiCondensed(
                              color: Colors.grey[500],
                              fontSize: 13.sp,
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
                    padding: EdgeInsets.all(12.w),
                    children: [
                      // Active games section
                      if (activeGames.isNotEmpty) ...[
                        Text(
                          'ACTIVE GAMES (${activeGames.length})',
                          style: GoogleFonts.teko(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: kNeonGreen,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        ...activeGames.map((game) => Padding(
                              padding: EdgeInsets.only(bottom: 10.h),
                              child: GameLogTile(
                                game: game,
                                onGameUpdated: _refreshStream,
                                onGameDeleted: _refreshStream,
                              ),
                            )),
                      ],

                      // Cancelled games section
                      if (cancelledGames.isNotEmpty) ...[
                        if (activeGames.isNotEmpty) SizedBox(height: 16.h),
                        Text(
                          'CANCELLED GAMES (${cancelledGames.length})',
                          style: GoogleFonts.teko(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        ...cancelledGames.map((game) => Padding(
                              padding: EdgeInsets.only(bottom: 10.h),
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

