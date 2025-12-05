import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../controllers/game_list_controller.dart';
import '../../controllers/search_controller.dart' as gl;
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../theme/app_theme.dart';
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
    
    // Refresh games list when view is initialized with authenticated user
    // This ensures games load immediately after login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = AuthController.instance.currentUser;
      if (currentUser != null) {
        GameListController.instance.refresh();
      }
    });
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
    
    // Only update local state - no route navigation while typing
    // This prevents widget rebuilds and keyboard dismissal
    gl.SearchController.instance.updateQuery(newQuery);
    _syncedQuery = newQuery;
    
    // Trigger setState to update the filtered list immediately
    setState(() {});
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

  void _showFilterDialog(bool isDark, Color accent) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.dialog(isDark),
          title: Text(
            'Filter Games',
            style: GoogleFonts.teko(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('all', 'All Games', isDark, accent, dialogContext),
              _buildFilterOption('joined', 'Joined Games', isDark, accent, dialogContext),
              _buildFilterOption('available', 'Available Games', isDark, accent, dialogContext),
              _buildFilterOption('waitlist', 'Waitlist Games', isDark, accent, dialogContext),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Close',
                style: GoogleFonts.barlowSemiCondensed(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterOption(String value, String title, bool isDark, Color accent, BuildContext dialogContext) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.barlowSemiCondensed(
          color: AppColors.textPrimary(isDark),
          fontSize: 14.sp,
        ),
      ),
      leading: Radio<String>(
        value: value,
        groupValue: _selectedFilter,
        activeColor: accent,
        onChanged: (String? newValue) {
          setState(() {
            _selectedFilter = newValue ?? 'all';
          });
          Navigator.pop(dialogContext);
        },
      ),
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        Navigator.pop(dialogContext);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, child) {
        final isDark = ThemeController.instance.isDarkMode;
        final accent = AppColors.accent(isDark);
        final bgColor = AppColors.background(isDark);
        final cardColor = AppColors.card(isDark);
        final textPrimary = AppColors.textPrimary(isDark);
        final textSecondary = AppColors.textSecondary(isDark);
        final borderColor = AppColors.border(isDark);

        return Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'BROWSE GAMES',
              style: GoogleFonts.teko(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: textPrimary,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => context.pushNamed('notifications'),
                icon: Icon(
                  Icons.notifications_outlined,
                  color: accent,
                  size: 22.sp,
                ),
              ),
            ],
          ),
          body: StreamBuilder<List<Game>>(
            stream: GameListController.instance.watchGames(),
            initialData: <Game>[],
            builder: (BuildContext context, AsyncSnapshot<List<Game>> snapshot) {
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
                            color: textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.barlowSemiCondensed(
                            color: textSecondary,
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          height: 40.h,
                          child: ElevatedButton(
                            onPressed: () => GameListController.instance.refresh(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
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
              
              return StreamBuilder<gl.SearchState>(
                stream: gl.SearchController.instance.watch(),
                initialData: gl.SearchController.instance.state,
                builder: (BuildContext context, AsyncSnapshot<gl.SearchState> searchSnap) {
                  final gl.SearchState search = searchSnap.connectionState == ConnectionState.waiting
                      ? gl.SearchController.instance.state
                      : (searchSnap.data ?? gl.SearchController.instance.state);

                  final String q = search.query.trim().toLowerCase();
                  final String? currentUserId = AuthController.instance.currentUser?.uid;
                  
                  bool matches(Game g) {
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

                  final List<Game> games = allGames.where((Game g) => matches(g)).toList();
                  
                  if (allGames.isEmpty) {
                    return GameListEmpty(
                      onRefresh: () => GameListController.instance.refresh(),
                    );
                  }

                  return GestureDetector(
                    onTap: () {
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
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    style: GoogleFonts.barlowSemiCondensed(
                                      color: textPrimary,
                                      fontSize: 14.sp,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Search by game, location, or sport',
                                      hintStyle: GoogleFonts.barlowSemiCondensed(
                                        color: textSecondary,
                                        fontSize: 14.sp,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: textSecondary,
                                        size: 20.sp,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 12.h,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8.r),
                                        borderSide: BorderSide(
                                          color: accent,
                                          width: 2,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8.r),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onSubmitted: (String value) {
                                      // Only update URL when user submits (presses Enter/Done)
                                      // This prevents route rebuilds while typing
                                      _updateQueryParam(value);
                                      _searchFocusNode.unfocus();
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              IconButton(
                                icon: Icon(
                                  Icons.filter_list,
                                  color: _selectedFilter != 'all' ? accent : textSecondary,
                                  size: 22.sp,
                                ),
                                tooltip: 'Filter games',
                                onPressed: () => _showFilterDialog(isDark, accent),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            color: accent,
                            onRefresh: () => GameListController.instance.refresh(),
                            child: games.isEmpty
                                ? SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 32.h),
                                      child: GameListEmpty(
                                        onRefresh: () => GameListController.instance.refresh(),
                                      ),
                                    ),
                                  )
                                : NotificationListener<ScrollNotification>(
                                    onNotification: (notification) {
                                      if (notification is ScrollStartNotification) {
                                        _searchFocusNode.unfocus();
                                      }
                                      return false;
                                    },
                                    child: ListView.separated(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                      itemCount: games.length,
                                      separatorBuilder: (_, __) => SizedBox(height: 10.h),
                                      itemBuilder: (BuildContext context, int index) {
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
      },
    );
  }
}
