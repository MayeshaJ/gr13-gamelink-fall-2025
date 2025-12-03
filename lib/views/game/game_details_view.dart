import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/game_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/game.dart';
import '../../widgets/loading_indicator.dart';
import 'edit_game_view.dart';
import '../chat/game_chat_view.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);

class GameDetailsView extends StatefulWidget {
  final String gameId;

  const GameDetailsView({
    super.key,
    required this.gameId,
  });

  @override
  State<GameDetailsView> createState() => _GameDetailsViewState();
}

class _GameDetailsViewState extends State<GameDetailsView> {
  final GameController _gameController = GameController();
  final UserController _userController = UserController.instance;
  bool _isJoining = false;
  bool _isLeaving = false;
  bool _isJoiningWaitlist = false;
  bool _isLeavingWaitlist = false;
  Map<String, String> _participantNames = <String, String>{};
  String? _hostName;

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthController.instance.currentUser;
    final currentUserId = currentUser?.uid;

    return Scaffold(
      backgroundColor: kDarkNavy,
      appBar: AppBar(
        backgroundColor: kDarkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'GAME DETAILS',
          style: GoogleFonts.teko(
            fontSize: 24,
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
      body: StreamBuilder<GameModel?>(
        stream: _gameController.watchGame(widget.gameId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Loading game details...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Failed to load game details'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final gameModel = snapshot.data;
          if (gameModel == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Game not found'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Load participant names and host name
          _loadParticipantNames(gameModel.participants);
          _loadHostName(gameModel.hostId);

          final int capacity = gameModel.maxPlayers;
          final int joined = gameModel.participants.length;
          final int remaining = capacity > joined ? capacity - joined : 0;
          final int waitlistCount = gameModel.waitlist.length;

          final bool isFull = joined >= capacity;
          final bool isStarted = DateTime.now().isAfter(gameModel.date);
          final bool isCancelled = gameModel.isCancelled;
          final bool isParticipant = currentUserId != null &&
              gameModel.participants.contains(currentUserId);
          final bool isHost = currentUserId == gameModel.hostId;
          final bool isOnWaitlist = currentUserId != null &&
              gameModel.waitlist.contains(currentUserId);
          final bool canJoin = !isFull &&
              !isParticipant &&
              !isHost &&
              currentUserId != null &&
              !isStarted &&
              !isCancelled;

          final DateTime dt = gameModel.date.toLocal();
          final String dateText =
              '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cancelled banner
                if (isCancelled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'GAME CANCELLED',
                      style: GoogleFonts.teko(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Game Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF243447),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        gameModel.title.toUpperCase(),
                        style: GoogleFonts.teko(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Game Info
                      _buildInfoRow(Icons.person_outline, 'Host', _hostName ?? 'Loading...'),
                      const SizedBox(height: 14),
                      _buildInfoRow(Icons.location_on_outlined, 'Location', gameModel.location),
                      const SizedBox(height: 14),
                      _buildInfoRow(Icons.calendar_today_outlined, 'Date & Time', dateText),
                      const SizedBox(height: 14),
                      _buildInfoRow(
                        Icons.people_outline,
                        'Players',
                        '$joined / $capacity  •  $remaining spots left',
                      ),
                      const SizedBox(height: 14),
                      _buildInfoRow(
                        Icons.hourglass_empty_outlined,
                        'Waitlist',
                        isCancelled
                            ? 'Game cancelled'
                            : isStarted
                            ? 'Closed (game started)'
                            : '$waitlistCount waiting',
                      ),

                      // Description
                      if (gameModel.description.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Divider(color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Text(
                          'DESCRIPTION',
                          style: GoogleFonts.teko(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: kNeonGreen,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          gameModel.description,
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Participants Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF243447),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PARTICIPANTS (${gameModel.participants.length})',
                        style: GoogleFonts.teko(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: kNeonGreen,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (gameModel.participants.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No participants yet',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        )
                      else
                        ...gameModel.participants.map((participantId) {
                          final participantName =
                              _participantNames[participantId] ?? 'Loading...';
                          final isHostParticipant = participantId == gameModel.hostId;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kDarkNavy,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isHostParticipant 
                                    ? kNeonGreen.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isHostParticipant 
                                      ? kNeonGreen.withOpacity(0.3)
                                      : Colors.grey[700],
                                  child: Icon(
                                    Icons.person,
                                    size: 18,
                                    color: isHostParticipant ? kNeonGreen : Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    participantName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isHostParticipant)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: kNeonGreen.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: kNeonGreen, width: 1),
                                    ),
                                    child: Text(
                                      'HOST',
                                      style: TextStyle(
                                        color: kNeonGreen,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                if (currentUserId != null) ...[
                  if (isCancelled) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'This game has been cancelled.',
                        style: TextStyle(
                          color: Colors.red[400],
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else ...[
                    // Leave Button (shown when user is a participant but not host)
                    if (!isStarted && isParticipant && !isHost) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: !_isLeaving
                              ? () => _handleLeave(gameModel, currentUserId)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLeaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.exit_to_app, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'LEAVE GAME',
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
                      const SizedBox(height: 12),
                    ],

                    // Join Button (shown when user is not a participant)
                    if (!isParticipant) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: canJoin && !_isJoining
                              ? () => _handleJoin(gameModel, currentUserId)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canJoin ? kNeonGreen : Colors.grey[700],
                            foregroundColor: canJoin ? Colors.black : Colors.grey[500],
                            disabledBackgroundColor: Colors.grey[800],
                            disabledForegroundColor: Colors.grey[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isJoining
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isHost
                                          ? Icons.person
                                          : isStarted || isFull
                                              ? Icons.block
                                              : Icons.person_add,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isHost
                                          ? 'YOU ARE HOST'
                                          : isStarted
                                              ? 'GAME STARTED'
                                              : isFull
                                                  ? 'GAME FULL'
                                                  : 'JOIN GAME',
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
                      const SizedBox(height: 12),
                      if (!isStarted && isFull && !isHost) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _isJoiningWaitlist || _isLeavingWaitlist
                                ? null
                                : () {
                                    if (isOnWaitlist) {
                                      _handleLeaveWaitlist(gameModel, currentUserId);
                                    } else {
                                      _handleJoinWaitlist(gameModel, currentUserId);
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kNeonGreen,
                              side: BorderSide(color: kNeonGreen, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.hourglass_empty, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  isOnWaitlist ? 'LEAVE WAITLIST' : 'JOIN WAITLIST',
                                  style: GoogleFonts.teko(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],

                  // Host area (info + edit + cancel)
                  if (isHost) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditGameView(game: gameModel),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kNeonGreen,
                          side: BorderSide(color: kNeonGreen, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.edit, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'EDIT GAME',
                              style: GoogleFonts.teko(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isCancelled ? null : () => _confirmCancel(gameModel.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCancelled ? Colors.grey[800] : Colors.red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[800],
                          disabledForegroundColor: Colors.grey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cancel, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              isCancelled ? 'CANCELLED' : 'CANCEL GAME',
                              style: GoogleFonts.teko(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Open Chat button (only for host and participants)
                  if (isHost || isParticipant)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GameChatView(
                                gameId: gameModel.id,
                                gameTitle: gameModel.title,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kNeonGreen,
                          side: const BorderSide(color: kNeonGreen, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.chat),
                        label: Text(
                          'OPEN CHAT',
                          style: GoogleFonts.teko(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Please sign in to join this game',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ——————————————— ADD CONFIRM CANCEL ———————————————

  Future<void> _confirmCancel(String gameId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Game'),
        content: const Text(
          'Are you sure you want to cancel this game?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('No'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Yes, cancel'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelGame(gameId);
    }
  }

  // ————————————————————————————————————————————————

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: kNeonGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadHostName(String hostId) async {
    if (_hostName != null) return;

    try {
      final userData = await _userController.getUserDocument(uid: hostId);
      if (userData != null) {
        final firstName = userData['firstName'] ?? '';
        final lastName = userData['lastName'] ?? '';
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          if (firstName.isEmpty) {
            _hostName = lastName;
          } else if (lastName.isEmpty) {
            _hostName = firstName;
          } else {
            _hostName = '$firstName $lastName';
          }
        } else {
          _hostName = 'Unknown';
        }
      } else {
        _hostName = 'Unknown';
      }
    } catch (_) {
      _hostName = 'Unknown';
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadParticipantNames(List<String> participantIds) async {
    final Set<String> idsToFetch = participantIds
        .where((id) => !_participantNames.containsKey(id))
        .toSet();

    if (idsToFetch.isEmpty) return;

    await Future.wait(
      idsToFetch.map((userId) async {
        try {
          final userData = await _userController.getUserDocument(uid: userId);
          if (userData != null) {
            final firstName = userData['firstName'] ?? '';
            final lastName = userData['lastName'] ?? '';
            String name;
            if (firstName.isNotEmpty || lastName.isNotEmpty) {
              if (firstName.isEmpty) {
                name = lastName;
              } else if (lastName.isEmpty) {
                name = firstName;
              } else {
                name = '$firstName $lastName';
              }
            } else {
              name = 'Unknown';
            }
            _participantNames[userId] = name;
          } else {
            _participantNames[userId] = 'Unknown';
          }
        } catch (_) {
          _participantNames[userId] = 'Unknown';
        }
      }),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleJoin(GameModel game, String userId) async {
    setState(() {
      _isJoining = true;
    });

    try {
      await _gameController.joinGame(game.id, userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully joined the game!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  Future<void> _handleLeave(GameModel game, String userId) async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Game'),
          content: const Text('Are you sure you want to leave this game?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLeaving = true;
    });

    try {
      await _gameController.leaveGame(game.id, userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully left the game'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLeaving = false;
        });
      }
    }
  }

  Future<void> _handleJoinWaitlist(GameModel game, String userId) async {
    setState(() {
      _isJoiningWaitlist = true;
    });

    try {
      await _gameController.joinWaitlist(game.id, userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to waitlist'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningWaitlist = false;
        });
      }
    }
  }

  Future<void> _handleLeaveWaitlist(GameModel game, String userId) async {
    setState(() {
      _isLeavingWaitlist = true;
    });

    try {
      await _gameController.leaveWaitlist(game.id, userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from waitlist'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLeavingWaitlist = false;
        });
      }
    }
  }

  Future<void> _cancelGame(String gameId) async {
    try {
      await _gameController.cancelGame(gameId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game has been cancelled'),
          backgroundColor: Colors.red,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
