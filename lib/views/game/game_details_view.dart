import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/game_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/game.dart';
import '../../widgets/loading_indicator.dart';
import 'edit_game_view.dart';
import '../chat/game_chat_view.dart';

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
      appBar: AppBar(
        title: const Text('Game Details'),
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
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'THIS GAME HAS BEEN CANCELLED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Title
                Text(
                  gameModel.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                // Game Info
                _buildInfoRow(Icons.person, 'Host', _hostName ?? 'Loading...'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on, 'Location', gameModel.location),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.calendar_today, 'Date & Time', dateText),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.people,
                  'Players',
                  'Joined: $joined / $capacity  •  Remaining: $remaining',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.hourglass_empty,
                  'Waitlist',
                  isCancelled
                      ? 'Game cancelled'
                      : isStarted
                      ? 'Waitlist closed (game already started)'
                      : '$waitlistCount on waitlist',
                ),
                const SizedBox(height: 24),

                // Description
                if (gameModel.description.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gameModel.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                ],

                // Participants List
                Text(
                  'Participants (${gameModel.participants.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (gameModel.participants.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No participants yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...gameModel.participants.map((participantId) {
                    final participantName =
                        _participantNames[participantId] ?? 'Loading...';
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(participantName),
                      subtitle: participantId == gameModel.hostId
                          ? const Text(
                        'Host',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      )
                          : null,
                    );
                  }),

                const SizedBox(height: 32),

                // Action Buttons
                if (currentUserId != null) ...[
                  if (isCancelled) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'This game has been cancelled. No further actions are available.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Leave Button (shown when user is a participant but not host)
                    if (!isStarted && isParticipant && !isHost) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: !_isLeaving
                              ? () => _handleLeave(gameModel, currentUserId)
                              : null,
                          icon: _isLeaving
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.exit_to_app),
                          label: const Text('Leave Game'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey,
                            disabledForegroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Join Button (shown when user is not a participant)
                    if (!isParticipant) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: canJoin && !_isJoining
                              ? () => _handleJoin(gameModel, currentUserId)
                              : null,
                          icon: _isJoining
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.person_add),
                          label: Text(
                            isHost
                                ? 'You are the host'
                                : isStarted
                                ? 'Game has already started'
                                : isFull
                                ? 'Game is full'
                                : 'Join Game',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor:
                            canJoin ? Colors.green : Colors.grey,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!isStarted && isFull && !isHost) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isJoiningWaitlist || _isLeavingWaitlist
                                ? null
                                : () {
                              if (isOnWaitlist) {
                                _handleLeaveWaitlist(
                                    gameModel, currentUserId);
                              } else {
                                _handleJoinWaitlist(
                                    gameModel, currentUserId);
                              }
                            },
                            icon: const Icon(Icons.hourglass_empty),
                            label: Text(
                              isOnWaitlist
                                  ? 'Leave waitlist'
                                  : 'Join waitlist',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],

                  // Host area (info + edit + cancel)
                  if (isHost) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.person),
                        label: const Text('You are the host'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditGameView(game: gameModel),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Game'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isCancelled
                            ? null
                            : () => _confirmCancel(gameModel.id),
                        icon: const Icon(Icons.cancel),
                        label: Text(
                          isCancelled ? 'Game Cancelled' : 'Cancel Game',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                          isCancelled ? Colors.grey : Colors.red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          disabledForegroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Open Chat button (everyone who is logged in can see for now;
                  // we will restrict to host/participants in Iteration 5).
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
                      icon: const Icon(Icons.chat),
                      label: const Text('Open Chat'),
                    ),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Please sign in to join this game',
                      style: TextStyle(color: Colors.grey),
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
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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
