import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/game.dart';
import '../../controllers/game_controller.dart';
import '../../controllers/auth_controller.dart';

class GameTile extends StatefulWidget {
  final Game game;

  const GameTile({
    super.key,
    required this.game,
  });

  @override
  State<GameTile> createState() => _GameTileState();
}

class _GameTileState extends State<GameTile> {
  final GameController _gameController = GameController();
  bool _isJoining = false;

  @override
  Widget build(BuildContext context) {
    final DateTime dt = widget.game.dateTime.toLocal();
    final String dateText =
        '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';

    final currentUser = AuthController.instance.currentUser;
    final String? currentUserId = currentUser?.uid;
    final bool isParticipant = currentUserId != null &&
        widget.game.participantIds.contains(currentUserId);
    final bool isOpen = widget.game.status == GameStatus.open;
    final bool canJoin = isOpen && !isParticipant && currentUserId != null;
    final String? userIdForJoin = canJoin ? currentUserId : null;

    final int capacity = widget.game.maxPlayers;
    final int joined = widget.game.participantIds.length;
    final int remaining = capacity > joined ? capacity - joined : 0;
    final bool isFull = remaining == 0;
    final int waitlistCount = widget.game.waitlist.length;

    return Card(
      child: ListTile(
        onTap: () {
          // Navigate to game details page
          context.pushNamed('game-details', pathParameters: {'id': widget.game.id});
        },
        title: Text(
          widget.game.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('${widget.game.hostName} • ${widget.game.location}'),
            const SizedBox(height: 4),
            Text(dateText),
            const SizedBox(height: 4),
            Text(
              _capitalize(widget.game.sport),
              style: const TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 6),
            Text(
              'Capacity: $capacity • Joined: $joined • Remaining: $remaining',
              style: const TextStyle(fontSize: 12),
            ),
            if (isFull) ...[
              const SizedBox(height: 4),
              Text(
                waitlistCount > 0
                    ? 'Game is full • $waitlistCount on waitlist'
                    : 'Game is full • Waitlist available',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        trailing: ElevatedButton(
          onPressed: canJoin && !_isJoining && userIdForJoin != null
              ? () => _handleJoin(widget.game.id, userIdForJoin)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isParticipant
                ? Colors.grey
                : isOpen
                    ? Colors.green
                    : Colors.grey,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade600,
          ),
          child: _isJoining
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(isParticipant ? 'Joined' : 'Join'),
        ),
      ),
    );
  }

  Future<void> _handleJoin(String gameId, String userId) async {
    setState(() {
      _isJoining = true;
    });

    try {
      await _gameController.joinGame(gameId, userId);

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

  String _two(int n) => n.toString().padLeft(2, '0');
  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}