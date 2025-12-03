import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      decoration: BoxDecoration(
        color: const Color(0xFF243447),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: () {
            context.pushNamed('game-details', pathParameters: {'id': widget.game.id});
          },
          child: Padding(
            padding: EdgeInsets.all(12.w),
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
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: kNeonGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4.r),
                        border: Border.all(color: kNeonGreen, width: 1),
                      ),
                      child: Text(
                        _capitalize(widget.game.sport),
                        style: GoogleFonts.barlowSemiCondensed(
                          color: kNeonGreen,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8.h),

                // Host and Location
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14.sp, color: Colors.grey[400]),
                    SizedBox(width: 4.w),
                    Text(
                      widget.game.hostName,
                      style: GoogleFonts.barlowSemiCondensed(color: Colors.grey[300], fontSize: 12.sp),
                    ),
                    SizedBox(width: 10.w),
                    Icon(Icons.location_on_outlined, size: 14.sp, color: Colors.grey[400]),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        widget.game.location,
                        style: GoogleFonts.barlowSemiCondensed(color: Colors.grey[300], fontSize: 12.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 6.h),

                // Date
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14.sp, color: Colors.grey[400]),
                    SizedBox(width: 4.w),
                    Text(
                      dateText,
                      style: GoogleFonts.barlowSemiCondensed(color: Colors.grey[300], fontSize: 12.sp),
                    ),
                  ],
                ),

                SizedBox(height: 10.h),

                // Capacity Info and Button
                Row(
                  children: [
                    // Capacity
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.people_outline, size: 16.sp, color: kNeonGreen),
                          SizedBox(width: 4.w),
                          Text(
                            '$joined/$capacity',
                            style: GoogleFonts.barlowSemiCondensed(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isFull) ...[
                            SizedBox(width: 6.w),
                            Text(
                              '• $waitlistCount waitlist',
                              style: GoogleFonts.barlowSemiCondensed(
                                color: Colors.grey[400],
                                fontSize: 11.sp,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Action Button
                    SizedBox(
                      height: 32.h,
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
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                        ),
                        child: _isProcessing
                            ? SizedBox(
                                width: 14.w,
                                height: 14.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                canLeave ? 'LEAVE' : isParticipant ? 'JOINED' : 'JOIN',
                                style: GoogleFonts.barlowSemiCondensed(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
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