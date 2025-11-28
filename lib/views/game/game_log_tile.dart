import 'package:flutter/material.dart';

import '../../models/game.dart';
import '../../controllers/game_controller.dart';
import 'edit_game_view.dart';

/// A tile widget for displaying a game in the Game Logs page.
/// Shows Edit and Cancel/Delete buttons instead of Join button.
class GameLogTile extends StatefulWidget {
  final GameModel game;
  final VoidCallback? onGameUpdated;
  final VoidCallback? onGameDeleted;

  const GameLogTile({
    super.key,
    required this.game,
    this.onGameUpdated,
    this.onGameDeleted,
  });

  @override
  State<GameLogTile> createState() => _GameLogTileState();
}

class _GameLogTileState extends State<GameLogTile> {
  final GameController _gameController = GameController();
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final DateTime dt = widget.game.date.toLocal();
    final String dateText =
        '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';

    final int capacity = widget.game.maxPlayers;
    final int joined = widget.game.participants.length;
    final int remaining = capacity > joined ? capacity - joined : 0;
    final int waitlistCount = widget.game.waitlist.length;
    final bool isCancelled = widget.game.isCancelled;

    return Card(
      color: isCancelled ? Colors.grey.shade200 : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Game title and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.game.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                      color: isCancelled ? Colors.grey : null,
                    ),
                  ),
                ),
                if (isCancelled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Cancelled',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Location and date
            Text(
              widget.game.location,
              style: TextStyle(
                color: isCancelled ? Colors.grey : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateText,
              style: TextStyle(
                color: isCancelled ? Colors.grey : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),

            // Capacity info
            Text(
              'Capacity: $capacity • Joined: $joined • Remaining: $remaining',
              style: TextStyle(
                fontSize: 12,
                color: isCancelled ? Colors.grey : null,
              ),
            ),
            if (waitlistCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$waitlistCount on waitlist',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: isCancelled ? Colors.grey : Colors.grey.shade600,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit button - disabled if cancelled
                OutlinedButton.icon(
                  onPressed: isCancelled
                      ? null
                      : () => _navigateToEdit(context),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),

                // Delete button
                ElevatedButton.icon(
                  onPressed: _isDeleting ? null : () => _confirmDelete(context),
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.delete, size: 18),
                  label: Text(_isDeleting ? 'Deleting...' : 'Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEdit(BuildContext context) async {
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditGameView(game: widget.game),
      ),
    );

    // If game was updated, notify parent to refresh
    if (result == true) {
      widget.onGameUpdated?.call();
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Game'),
          content: Text(
            widget.game.isCancelled
                ? 'Are you sure you want to permanently delete "${widget.game.title}"?'
                : 'Are you sure you want to delete "${widget.game.title}"?\n\nAll participants will be notified.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteGame();
    }
  }

  Future<void> _deleteGame() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await _gameController.deleteGame(widget.game.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onGameDeleted?.call();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete game: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}

