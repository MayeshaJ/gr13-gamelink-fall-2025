import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/game_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/game.dart';
import '../../widgets/loading_indicator.dart';

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

          final bool isFull = gameModel.participants.length >= gameModel.maxPlayers;
          final bool isParticipant = currentUserId != null &&
              gameModel.participants.contains(currentUserId);
          final bool isHost = currentUserId == gameModel.hostId;
          final bool canJoin = !isFull && !isParticipant && !isHost && currentUserId != null;

          final DateTime dt = gameModel.date.toLocal();
          final String dateText =
              '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  '${gameModel.participants.length} / ${gameModel.maxPlayers}',
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
                    final participantName = _participantNames[participantId] ?? 'Loading...';
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(participantName),
                      subtitle: participantId == gameModel.hostId
                          ? const Text('Host', style: TextStyle(fontStyle: FontStyle.italic))
                          : null,
                    );
                  }),

                const SizedBox(height: 32),

                // Action Buttons
                if (currentUserId != null) ...[
                  // Leave Button (shown when user is a participant but not host)
                  if (isParticipant && !isHost) ...[
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
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
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
                              : isFull
                                  ? 'Game is full'
                                  : 'Join Game',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: canJoin ? Colors.green : Colors.grey,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                  // Host message (shown when user is the host)
                  if (isHost) ...[
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
                  ],
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
      if (userData != null && userData['name'] != null) {
        final name = userData['name'] as String;
        _hostName = name.isNotEmpty ? name : 'Unknown';
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
          if (userData != null && userData['name'] != null) {
            final name = userData['name'] as String;
            _participantNames[userId] = name.isNotEmpty ? name : 'Unknown';
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

  String _two(int n) => n.toString().padLeft(2, '0');
}

