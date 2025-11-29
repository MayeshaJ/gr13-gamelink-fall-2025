import 'dart:async';

import 'package:game_link_group13/models/game.dart';
import 'package:game_link_group13/controllers/game_controller.dart';
import 'package:game_link_group13/controllers/user_controller.dart';
import 'package:game_link_group13/controllers/auth_controller.dart';

/// Controller for managing the game list UI state.
/// Integrates with GameController to fetch real-time data from Firestore.
class GameListController {
  GameListController._internal() {
    _preloadCurrentUser();
    _initialize();
  }

  static final GameListController instance = GameListController._internal();

  final GameController _gameController = GameController();
  final UserController _userController = UserController.instance;
  
  StreamSubscription<List<Game>>? _gamesSubscription;
  final StreamController<List<Game>> _gamesStreamController =
      StreamController<List<Game>>.broadcast();
  
  // Cache for host names to avoid repeated Firestore calls
  final Map<String, String> _hostNameCache = <String, String>{};
  
  // Track current game models for async host name updates
  List<GameModel>? _currentGameModels;
  
  /// Pre-load current user's name into cache to avoid delays when viewing own games
  /// This is called during initialization to ensure current user's name is available
  void _preloadCurrentUser() {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser != null && !_hostNameCache.containsKey(currentUser.uid)) {
      // Fetch current user's name asynchronously without blocking
      _userController.getUserDocument(uid: currentUser.uid).then((userData) {
        if (userData != null) {
          final firstName = userData['firstName'] ?? '';
          final lastName = userData['lastName'] ?? '';
          String name;
          if (firstName.isEmpty && lastName.isEmpty) {
            name = 'Unknown';
          } else if (firstName.isEmpty) {
            name = lastName;
          } else if (lastName.isEmpty) {
            name = firstName;
          } else {
            name = '$firstName $lastName';
          }
          _hostNameCache[currentUser.uid] = name;
          // If we have current game models, update them with the new name
          if (_currentGameModels != null) {
            _updateGamesWithCachedNames();
          }
        } else {
          _hostNameCache[currentUser.uid] = 'Unknown';
        }
      }).catchError((_) {
        _hostNameCache[currentUser.uid] = 'Unknown';
      });
    }
  }
  
  /// Update games list with cached host names (used when current user name loads)
  void _updateGamesWithCachedNames() {
    if (_currentGameModels == null) return;
    
    final currentUser = AuthController.instance.currentUser;
    final String? currentUserId = currentUser?.uid;
    
    // Filter out cancelled games AND games hosted by current user
    final List<GameModel> activeGames = _currentGameModels!
        .where((model) => !model.isCancelled && model.hostId != currentUserId)
        .toList();
    
    final List<Game> updatedGames = activeGames.map((model) {
      final String hostName = _hostNameCache[model.hostId] ?? 'Unknown';
      final String sport = _deriveSport(model.title, model.description);
      final bool isFull = model.participants.length >= model.maxPlayers;
      final GameStatus status = isFull ? GameStatus.closed : GameStatus.open;

      return Game(
        id: model.id,
        title: model.title,
        hostName: hostName,
        dateTime: model.date,
        location: model.location,
        sport: sport,
        status: status,
        maxPlayers: model.maxPlayers,
        participantIds: model.participants,
        waitlist: model.waitlist,
      );
    }).toList();

    if (!_useOrderBy) {
      updatedGames.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    }

    _gamesStreamController.add(updatedGames);
  }
  
  /// Ensure current user's name is in cache (call this after creating a game)
  Future<void> ensureCurrentUserNameCached() async {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser != null && !_hostNameCache.containsKey(currentUser.uid)) {
      try {
        final userData = await _userController.getUserDocument(uid: currentUser.uid);
        if (userData != null) {
          final firstName = userData['firstName'] ?? '';
          final lastName = userData['lastName'] ?? '';
          String name;
          if (firstName.isEmpty && lastName.isEmpty) {
            name = 'Unknown';
          } else if (firstName.isEmpty) {
            name = lastName;
          } else if (lastName.isEmpty) {
            name = firstName;
          } else {
            name = '$firstName $lastName';
          }
          _hostNameCache[currentUser.uid] = name;
        } else {
          _hostNameCache[currentUser.uid] = 'Unknown';
        }
      } catch (_) {
        _hostNameCache[currentUser.uid] = 'Unknown';
      }
    }
  }

  // Track the last emitted games list to provide immediate value to new listeners
  List<Game> _lastGames = <Game>[];
  
  /// Stream of games for the list view.
  /// Returns a stream that always has data available to prevent StreamBuilder waiting state.
  Stream<List<Game>> watchGames() {
    // Create a stream that immediately emits the last known state, then continues with updates
    return Stream<List<Game>>.multi((controller) {
      // Emit last known games immediately
      controller.add(_lastGames);
      
      // Then listen to updates
      final subscription = _gamesStreamController.stream.listen(
        (games) {
          _lastGames = games;
          controller.add(games);
        },
        onError: (error) => controller.addError(error),
        onDone: () => controller.close(),
        cancelOnError: false,
      );
      
      // Cancel subscription when controller closes
      controller.onCancel = () {
        subscription.cancel();
      };
    });
  }

  bool _useOrderBy = false; // Start without orderBy to avoid index issues - can enable later
  Timer? _safetyTimer; // Safety timer to detect if Firestore stream is hanging
  bool _hasReceivedData = false; // Track if we've received any data from Firestore
  
  void _initialize() {
    // Cancel any existing safety timer
    _safetyTimer?.cancel();
    
    // Emit initial empty list immediately to prevent infinite loading
    _lastGames = <Game>[];
    _gamesStreamController.add(<Game>[]);
    _hasReceivedData = false;
    
    print('GameListController: Initializing Firestore stream (useOrderBy: $_useOrderBy)...');
    
    // Add a safety timeout - if no data received in 5 seconds, log warning
    _safetyTimer = Timer(const Duration(seconds: 5), () {
      if (!_hasReceivedData) {
        print('GameListController: WARNING - No data received from Firestore after 5 seconds');
        print('GameListController: This might indicate a Firestore connection or permission issue');
        print('GameListController: Check Firestore rules and network connection');
        // Keep the empty list that was already emitted - UI should show empty state
      }
    });
    
    // Subscribe to Firestore games stream and convert GameModel to Game
    _gamesSubscription = _gameController
        .getAllGames(useOrderBy: _useOrderBy)
        .asyncMap((List<GameModel> gameModels) async {
      // Cancel safety timer if we received data
      _safetyTimer?.cancel();
      _hasReceivedData = true;
      print('GameListController: Received ${gameModels.length} games from Firestore');
      try {
        // Store current game models for async host name updates
        _currentGameModels = gameModels;
        // Convert GameModel list to Game list (async conversion for host names)
        final games = await _convertGameModelsToGames(gameModels);
        print('GameListController: Converted to ${games.length} Game objects');
        // Sort by date if we're not using orderBy
        if (!_useOrderBy) {
          games.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        }
        return games;
      } catch (e, stackTrace) {
        // If conversion fails, return empty list and log error
        print('GameListController: Error converting games: $e');
        print('Stack trace: $stackTrace');
        return <Game>[];
      }
    }).listen(
      (List<Game> games) {
        print('GameListController: Emitting ${games.length} games to stream');
        _lastGames = games; // Update last known games
        _gamesStreamController.add(games);
      },
      onError: (error, stackTrace) {
        // Cancel safety timer
        _safetyTimer?.cancel();
        
        // Log error with stack trace
        print('GameListController: Error loading games: $error');
        print('Stack trace: $stackTrace');
        
        // Check if it's a Firestore index error
        final errorStr = error.toString().toLowerCase();
        if (errorStr.contains('index') || 
            errorStr.contains('requires an index') ||
            errorStr.contains('the query requires an index')) {
          print('GameListController: Firestore index missing. Retrying without orderBy...');
          // Retry without orderBy
          if (_useOrderBy) {
            _useOrderBy = false;
            _gamesSubscription?.cancel();
            Future.delayed(const Duration(milliseconds: 100), () {
              _initialize();
            });
            return;
          }
        }
        
        // Check for permission errors
        if (errorStr.contains('permission') || errorStr.contains('permission-denied')) {
          print('GameListController: Permission denied - check Firestore rules');
          print('GameListController: Make sure Firestore security rules allow reading games');
        }
        
        // Emit empty list so UI can still render
        _gamesStreamController.add(<Game>[]);
      },
      cancelOnError: false, // Keep listening even if there's an error
    );
  }

  /// Convert GameModel list to Game list, fetching host names as needed.
  /// Returns games immediately with cached/placeholder host names,
  /// then updates asynchronously as host names are fetched.
  /// Filters out games hosted by the current user (they appear in Game Logs instead).
  Future<List<Game>> _convertGameModelsToGames(
    List<GameModel> gameModels,
  ) async {
    final currentUser = AuthController.instance.currentUser;
    final String? currentUserId = currentUser?.uid;
    
    // Filter out cancelled games AND games hosted by current user
    final List<GameModel> activeGames = gameModels
        .where((model) => !model.isCancelled && model.hostId != currentUserId)
        .toList();

    // Convert GameModel to Game immediately using cached host names or placeholder
    
    final List<Game> games = activeGames.map((model) {
      // If this is the current user's game and we have their name cached, use it
      // Otherwise use cached name or placeholder
      String hostName;
      if (model.hostId == currentUserId && _hostNameCache.containsKey(currentUserId!)) {
        hostName = _hostNameCache[currentUserId]!;
      } else {
        hostName = _hostNameCache[model.hostId] ?? 'Loading...';
      }
      
      final String sport = _deriveSport(model.title, model.description);
      final bool isFull = model.participants.length >= model.maxPlayers;
      final GameStatus status = isFull ? GameStatus.closed : GameStatus.open;

      return Game(
        id: model.id,
        title: model.title,
        hostName: hostName,
        dateTime: model.date,
        location: model.location,
        sport: sport,
        status: status,
        maxPlayers: model.maxPlayers,
        participantIds: model.participants,
        waitlist: model.waitlist,
      );
    }).toList();

    // Collect unique host IDs that need fetching
    final Set<String> hostIdsToFetch = activeGames
        .map((model) => model.hostId)
        .where((hostId) => !_hostNameCache.containsKey(hostId))
        .toSet();

    // Fetch host names asynchronously in the background (don't await)
    if (hostIdsToFetch.isNotEmpty) {
      // Start fetching but don't wait - update stream as names arrive
      _fetchHostNamesAsync(hostIdsToFetch);
    }

    // Return games immediately
    return games;
  }

  /// Fetch host names asynchronously and update the games list when done.
  void _fetchHostNamesAsync(Set<String> hostIdsToFetch) {
    Future.wait(
      hostIdsToFetch.map((hostId) async {
        try {
          final userData = await _userController.getUserDocument(uid: hostId);
          if (userData != null) {
            final firstName = userData['firstName'] ?? '';
            final lastName = userData['lastName'] ?? '';
            String name;
            if (firstName.isEmpty && lastName.isEmpty) {
              name = 'Unknown';
            } else if (firstName.isEmpty) {
              name = lastName;
            } else if (lastName.isEmpty) {
              name = firstName;
            } else {
              name = '$firstName $lastName';
            }
            _hostNameCache[hostId] = name;
          } else {
            _hostNameCache[hostId] = 'Unknown';
          }
        } catch (_) {
          // If fetching fails, cache 'Unknown' to avoid repeated calls
          _hostNameCache[hostId] = 'Unknown';
        }
      }),
    ).then((_) {
      // After all host names are fetched, update the games list using current models
      if (_currentGameModels == null) return;
      
      final currentUser = AuthController.instance.currentUser;
      final String? currentUserId = currentUser?.uid;
      
      // Filter out cancelled games AND games hosted by current user
      final List<GameModel> activeGames = _currentGameModels!
          .where((model) => !model.isCancelled && model.hostId != currentUserId)
          .toList();
      
      final List<Game> updatedGames = activeGames.map((model) {
        final String hostName = _hostNameCache[model.hostId] ?? 'Unknown';
        final String sport = _deriveSport(model.title, model.description);
        final bool isFull = model.participants.length >= model.maxPlayers;
        final GameStatus status = isFull ? GameStatus.closed : GameStatus.open;

        return Game(
          id: model.id,
          title: model.title,
          hostName: hostName,
          dateTime: model.date,
          location: model.location,
          sport: sport,
          status: status,
          maxPlayers: model.maxPlayers,
          participantIds: model.participants,
          waitlist: model.waitlist,
        );
      }).toList();

      // Sort by date if not using orderBy
      if (!_useOrderBy) {
        updatedGames.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      }

      // Emit updated games with real host names
      _gamesStreamController.add(updatedGames);
    }).catchError((error) {
      print('Error fetching host names: $error');
      // Still update with 'Unknown' for failed fetches
      if (_currentGameModels == null) return;
      
      final currentUser = AuthController.instance.currentUser;
      final String? currentUserId = currentUser?.uid;
      
      // Filter out cancelled games AND games hosted by current user
      final List<GameModel> activeGames = _currentGameModels!
          .where((model) => !model.isCancelled && model.hostId != currentUserId)
          .toList();
      
      final List<Game> updatedGames = activeGames.map((model) {
        final String hostName = _hostNameCache[model.hostId] ?? 'Unknown';
        final String sport = _deriveSport(model.title, model.description);
        final bool isFull = model.participants.length >= model.maxPlayers;
        final GameStatus status = isFull ? GameStatus.closed : GameStatus.open;

        return Game(
          id: model.id,
          title: model.title,
          hostName: hostName,
          dateTime: model.date,
          location: model.location,
          sport: sport,
          status: status,
          maxPlayers: model.maxPlayers,
          participantIds: model.participants,
          waitlist: model.waitlist,
        );
      }).toList();
      
      if (!_useOrderBy) {
        updatedGames.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      }
      
      _gamesStreamController.add(updatedGames);
    });
  }

  /// Derive sport from game title or description using keyword matching.
  String _deriveSport(String title, String description) {
    final String combined = '${title.toLowerCase()} ${description.toLowerCase()}';
    
    // Common sport keywords
    if (combined.contains('soccer') || combined.contains('football')) {
      return 'soccer';
    } else if (combined.contains('basketball') || combined.contains('b-ball')) {
      return 'basketball';
    } else if (combined.contains('tennis')) {
      return 'tennis';
    } else if (combined.contains('volleyball')) {
      return 'volleyball';
    } else if (combined.contains('cricket')) {
      return 'cricket';
    } else if (combined.contains('baseball')) {
      return 'baseball';
    } else if (combined.contains('hockey')) {
      return 'hockey';
    } else if (combined.contains('esports') || combined.contains('gaming')) {
      return 'esports';
    }
    
    // Default fallback
    return 'other';
  }

  /// Refresh the game list by re-fetching from Firestore.
  /// Note: Since we're using a stream, this will automatically update
  /// when new games are added. This method can trigger a manual refresh.
  Future<void> refresh() async {
    // The stream will automatically update when Firestore changes,
    // but we can trigger a refresh by re-subscribing if needed
    _gamesSubscription?.cancel();
    _initialize();
  }

  void dispose() {
    _gamesSubscription?.cancel();
    _gamesStreamController.close();
  }
}