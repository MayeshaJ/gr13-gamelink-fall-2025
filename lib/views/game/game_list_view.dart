import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/game_list_controller.dart';
import '../../controllers/search_controller.dart' as gl;
import '../../controllers/auth_controller.dart';
import '../../models/game.dart';
import 'game_tile.dart';
import '../../widgets/loading_indicator.dart';
import 'game_list_empty.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);

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
  String _selectedFilter = 'all'; // all, joined, available, waitlist

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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Games'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Games'),
                leading: Radio<String>(
                  value: 'all',
                  groupValue: _selectedFilter,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedFilter = value ?? 'all';
                    });
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  setState(() {
                    _selectedFilter = 'all';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Joined Games'),
                leading: Radio<String>(
                  value: 'joined',
                  groupValue: _selectedFilter,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedFilter = value ?? 'all';
                    });
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  setState(() {
                    _selectedFilter = 'joined';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Available Games'),
                leading: Radio<String>(
                  value: 'available',
                  groupValue: _selectedFilter,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedFilter = value ?? 'all';
                    });
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  setState(() {
                    _selectedFilter = 'available';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Waitlist Games'),
                leading: Radio<String>(
                  value: 'waitlist',
                  groupValue: _selectedFilter,
                  onChanged: (String? value) {
                    setState(() {
                      _selectedFilter = value ?? 'all';
                    });
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  setState(() {
                    _selectedFilter = 'waitlist';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: kDarkNavy,
      appBar: AppBar(
        backgroundColor: kDarkNavy,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'BROWSE GAMES',
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
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Failed to load games',
                      style: GoogleFonts.barlowSemiCondensed(
                        fontSize: 15.sp,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.barlowSemiCondensed(
                        color: Colors.grey,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 40.h,
                      child: ElevatedButton(
                        onPressed: () => GameListController.instance.refresh(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kNeonGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.barlowSemiCondensed(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
              final String? currentUserId = AuthController.instance.currentUser?.uid;
              
              bool matches(Game g) {
                // Search filter
                if (q.isNotEmpty) {
                  final String sport = g.sport.toLowerCase();
                  final String host = g.hostName.toLowerCase();
                  final String title = g.title.toLowerCase();
                  final String location = g.location.toLowerCase();
                  if (!sport.contains(q) &&
                      !host.contains(q) &&
                      !title.contains(q) &&
                      !location.contains(q)) {
                    return false;
                  }
                }
                
                // Status filter
                if (_selectedFilter != 'all' && currentUserId != null) {
                  switch (_selectedFilter) {
                    case 'joined':
                      return g.participantIds.contains(currentUserId);
                    case 'available':
                      return !g.participantIds.contains(currentUserId) &&
                             !g.waitlist.contains(currentUserId);
                    case 'waitlist':
                      return g.waitlist.contains(currentUserId);
                  }
                }
                
                return true;
              }

              final List<Game> games =
                  allGames.where((Game g) => matches(g)).toList();
              
              // Show empty state if no games match search
              if (allGames.isEmpty) {
                return GameListEmpty(
                  onRefresh: () => GameListController.instance.refresh(),
              );
            }

              return GestureDetector(
                onTap: () {
                  // Dismiss keyboard when tapping outside
                  FocusScope.of(context).unfocus();
                },
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44.h,
                              decoration: BoxDecoration(
                                color: const Color(0xFF243447),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                style: GoogleFonts.barlowSemiCondensed(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search by game, location, or sport',
                                  hintStyle: GoogleFonts.barlowSemiCondensed(
                                    color: Colors.grey[500],
                                    fontSize: 14.sp,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey[600],
                                    size: 20.sp,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 12.h,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: const BorderSide(
                                      color: kNeonGreen,
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onSubmitted: (_) {
                                  // Dismiss keyboard when user presses done
                                  _searchFocusNode.unfocus();
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          IconButton(
                            icon: Icon(
                              Icons.filter_list,
                              color: _selectedFilter != 'all'
                                  ? kNeonGreen
                                  : Colors.grey[600],
                              size: 22.sp,
                            ),
                            tooltip: 'Filter games',
                            onPressed: _showFilterDialog,
                          ),
                        ],
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
                                padding: EdgeInsets.only(top: 32.h),
                                child: GameListEmpty(
                                  onRefresh: () => GameListController.instance
                                      .refresh(),
                                ),
                              ),
                            )
                          : NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                // Dismiss keyboard when user starts scrolling
                                if (notification is ScrollStartNotification) {
                                  _searchFocusNode.unfocus();
                                }
                                return false;
                              },
                              child: ListView.separated(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                itemCount: games.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 10.h),
                                itemBuilder:
                                    (BuildContext context, int index) {
                                  final Game game = games[index];
                                  return GameTile(game: game);
                                },
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
