import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/game.dart';
import '../../controllers/game_controller.dart';
import 'edit_game_view.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);

/// A tile widget for displaying a game in the Host Games page.
/// Shows Edit and Delete buttons. Matches the game_tile.dart style.
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
    final bool isFull = remaining == 0;
    final int waitlistCount = widget.game.waitlist.length;
    final bool isCancelled = widget.game.isCancelled;

    return Container(
      decoration: BoxDecoration(
        color: isCancelled 
            ? const Color(0xFF243447).withOpacity(0.5) 
            : const Color(0xFF243447),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isCancelled 
              ? Colors.red.withOpacity(0.3) 
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.r),
          onTap: () {
            // Navigate to game details
            context.pushNamed('game-details', pathParameters: {'id': widget.game.id});
          },
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Status Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.game.title.toUpperCase(),
                        style: GoogleFonts.teko(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: isCancelled ? Colors.grey[400] : Colors.white,
                          height: 1,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (isCancelled)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                        child: Text(
                          'CANCELLED',
                          style: GoogleFonts.barlowSemiCondensed(
                            color: Colors.red,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 8.h),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14.sp, color: Colors.grey[400]),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        widget.game.location,
                        style: GoogleFonts.barlowSemiCondensed(
                          color: isCancelled ? Colors.grey[500] : Colors.grey[300], 
                          fontSize: 12.sp,
                        ),
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
                      style: GoogleFonts.barlowSemiCondensed(
                        color: isCancelled ? Colors.grey[500] : Colors.grey[300], 
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 10.h),

                // Capacity Info
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 16.sp, color: isCancelled ? Colors.grey[500] : kNeonGreen),
                    SizedBox(width: 4.w),
                    Text(
                      '$joined/$capacity',
                      style: GoogleFonts.barlowSemiCondensed(
                        color: isCancelled ? Colors.grey[500] : Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isFull && !isCancelled) ...[
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

                SizedBox(height: 12.h),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit button
                    SizedBox(
                      height: 32.h,
                      child: OutlinedButton.icon(
                        onPressed: isCancelled ? null : () => _navigateToEdit(context),
                        icon: Icon(Icons.edit, size: 14.sp),
                        label: Text(
                          'Edit',
                          style: GoogleFonts.barlowSemiCondensed(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isCancelled ? Colors.grey[600] : kNeonGreen,
                          side: BorderSide(
                            color: isCancelled ? Colors.grey[600]! : kNeonGreen,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),

                    // Delete button
                    SizedBox(
                      height: 32.h,
                      child: ElevatedButton.icon(
                        onPressed: _isDeleting ? null : () => _confirmDelete(context),
                        icon: _isDeleting
                            ? SizedBox(
                                width: 12.w,
                                height: 12.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(Icons.delete, size: 14.sp),
                        label: Text(
                          'Delete',
                          style: GoogleFonts.barlowSemiCondensed(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.red.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
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
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF243447),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          title: Text(
            'Delete Game',
            style: GoogleFonts.teko(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Text(
            widget.game.isCancelled
                ? 'Are you sure you want to permanently delete "${widget.game.title}"?'
                : 'Are you sure you want to delete "${widget.game.title}"?\n\nAll participants will be notified.',
            style: GoogleFonts.barlowSemiCondensed(
              fontSize: 14.sp,
              color: Colors.grey[300],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 14.sp,
                  color: Colors.grey[400],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
        SnackBar(
          content: Text(
            'Game deleted successfully',
            style: GoogleFonts.barlowSemiCondensed(fontSize: 14.sp),
          ),
          backgroundColor: kNeonGreen,
        ),
      );

      widget.onGameDeleted?.call();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete game: ${e.toString().replaceFirst('Exception: ', '')}',
            style: GoogleFonts.barlowSemiCondensed(fontSize: 14.sp),
          ),
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
