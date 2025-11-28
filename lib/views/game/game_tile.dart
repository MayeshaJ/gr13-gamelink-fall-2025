import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/game.dart';
import '../../controllers/game_controller.dart';
import '../../controllers/auth_controller.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);

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
  bool _isProcessing = false;

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
    final bool canLeave = isParticipant;

    final int capacity = widget.game.maxPlayers;
    final int joined = widget.game.participantIds.length;
    final int remaining = capacity > joined ? capacity - joined : 0;
    final bool isFull = remaining == 0;
    final int waitlistCount = widget.game.waitlist.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF243447),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.pushNamed('game-details', pathParameters: {'id': widget.game.id});
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Sport
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.game.title.toUpperCase(),
                        style: GoogleFonts.teko(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kNeonGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: kNeonGreen, width: 1),
                      ),
                      child: Text(
                        _capitalize(widget.game.sport),
                        style: TextStyle(
                          color: kNeonGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Host and Location
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      widget.game.hostName,
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.game.location,
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Date
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Text(
                      dateText,
                      style: TextStyle(color: Colors.grey[300], fontSize: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Capacity Info and Button
                Row(
                  children: [
                    // Capacity
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.people_outline, size: 18, color: kNeonGreen),
                          const SizedBox(width: 6),
                          Text(
                            '$joined/$capacity',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isFull) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• $waitlistCount waitlist',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Action Button
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : canLeave
                                ? () => _handleLeave(widget.game.id, currentUserId)
                                : canJoin
                                    ? () => _handleJoin(widget.game.id, currentUserId)
                                    : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canLeave
                              ? Colors.orange
                              : canJoin
                                  ? kNeonGreen
                                  : Colors.grey[700],
                          foregroundColor: canLeave || !canJoin ? Colors.white : Colors.black,
                          disabledBackgroundColor: Colors.grey[800],
                          disabledForegroundColor: Colors.grey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                canLeave ? 'LEAVE' : isParticipant ? 'JOINED' : 'JOIN',
                                style: GoogleFonts.teko(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleJoin(String gameId, String userId) async {
    setState(() {
      _isProcessing = true;
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
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleLeave(String gameId, String userId) async {
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
      _isProcessing = true;
    });

    try {
      await _gameController.leaveGame(gameId, userId);

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
          _isProcessing = false;
        });
      }
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}