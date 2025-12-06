import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/game_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../theme/app_theme.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isJoining = false;
  bool _isLeaving = false;
  bool _isJoiningWaitlist = false;
  bool _isLeavingWaitlist = false;
  Map<String, String> _participantNames = <String, String>{};
  String? _hostName;

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

        final currentUser = AuthController.instance.currentUser;
        final currentUserId = currentUser?.uid;

        return StreamBuilder<GameModel?>(
          stream: _gameController.watchGame(widget.gameId),
          builder: (context, snapshot) {
            Widget? endDrawer;
            if (snapshot.hasData && snapshot.data != null) {
              final gameModel = snapshot.data!;
              endDrawer = _buildParticipantsDrawer(gameModel, isDark, accent, cardColor, textPrimary, textSecondary, borderColor);
            }

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: bgColor,
              endDrawer: endDrawer,
              appBar: AppBar(
                backgroundColor: bgColor,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: textPrimary, size: 22.sp),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  'GAME DETAILS',
                  style: GoogleFonts.teko(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: textPrimary,
                  ),
                ),
                actions: [
                  if (snapshot.hasData && snapshot.data != null)
                    Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: GestureDetector(
                        onTap: () {
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: accent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline,
                                color: accent,
                                size: 20.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '${snapshot.data!.participants.length}',
                                style: GoogleFonts.barlowSemiCondensed(
                                  color: accent,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
              body: _buildBody(snapshot, currentUserId, isDark, accent, cardColor, textPrimary, textSecondary, borderColor),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<GameModel?> snapshot, String? currentUserId, bool isDark, Color accent, Color cardColor, Color textPrimary, Color textSecondary, Color borderColor) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const LoadingIndicator(message: 'Loading game details...');
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load game details', style: GoogleFonts.barlowSemiCondensed(fontSize: 14.sp, color: textPrimary)),
              SizedBox(height: 12.h),
              SizedBox(
                height: 40.h,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: Text('Go Back', style: GoogleFonts.barlowSemiCondensed(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                ),
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
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Game not found', style: GoogleFonts.barlowSemiCondensed(fontSize: 14.sp, color: textPrimary)),
              SizedBox(height: 12.h),
              SizedBox(
                height: 40.h,
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: Text('Go Back', style: GoogleFonts.barlowSemiCondensed(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
    }

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

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCancelled)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'GAME CANCELLED',
                      style: GoogleFonts.teko(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gameModel.title.toUpperCase(),
                        style: GoogleFonts.teko(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: textPrimary,
                          height: 1,
                        ),
                      ),

                      SizedBox(height: 14.h),

                      _buildInfoRow(Icons.person_outline, 'Host', _hostName ?? 'Loading...', accent, textPrimary, textSecondary),
                      SizedBox(height: 10.h),
                      _buildInfoRow(Icons.location_on_outlined, 'Location', gameModel.location, accent, textPrimary, textSecondary),
                      SizedBox(height: 10.h),
                      _buildInfoRow(Icons.calendar_today_outlined, 'Date & Time', dateText, accent, textPrimary, textSecondary),
                      SizedBox(height: 10.h),
                      _buildInfoRow(
                        Icons.people_outline,
                        'Players',
                        '$joined / $capacity  •  $remaining spots left',
                        accent, textPrimary, textSecondary,
                      ),
                      SizedBox(height: 10.h),
                      _buildInfoRow(
                        Icons.hourglass_empty_outlined,
                        'Waitlist',
                        isCancelled
                            ? 'Game cancelled'
                            : isStarted
                            ? 'Closed (game started)'
                            : '$waitlistCount waiting',
                        accent, textPrimary, textSecondary,
                      ),

                      if (gameModel.description.isNotEmpty) ...[
                        SizedBox(height: 14.h),
                        Divider(color: borderColor),
                        SizedBox(height: 10.h),
                        Text(
                          'DESCRIPTION',
                          style: GoogleFonts.teko(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: accent,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          gameModel.description,
                          style: GoogleFonts.barlowSemiCondensed(
                            color: textSecondary,
                            fontSize: 13.sp,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 14.h),

                // Get Directions Button
                SizedBox(
                  width: double.infinity,
                  height: 44.h,
                  child: OutlinedButton.icon(
                    onPressed: () => _openMap(gameModel.location),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    icon: Icon(Icons.directions, size: 18.sp),
                    label: Text(
                      'GET DIRECTIONS',
                      style: GoogleFonts.barlowSemiCondensed(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                if (currentUserId != null && (isHost || isParticipant) && !isCancelled)
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
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
                        foregroundColor: accent,
                        side: BorderSide(color: accent, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      icon: Icon(Icons.chat, size: 18.sp),
                      label: Text(
                        'OPEN GAME CHAT',
                        style: GoogleFonts.barlowSemiCondensed(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        _buildBottomActions(
          gameModel: gameModel,
          currentUserId: currentUserId,
          isHost: isHost,
          isParticipant: isParticipant,
          isOnWaitlist: isOnWaitlist,
          isFull: isFull,
          isStarted: isStarted,
          isCancelled: isCancelled,
          canJoin: canJoin,
          isDark: isDark,
          accent: accent,
          cardColor: cardColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        ),
      ],
    );
  }

  Widget _buildBottomActions({
    required GameModel gameModel,
    required String? currentUserId,
    required bool isHost,
    required bool isParticipant,
    required bool isOnWaitlist,
    required bool isFull,
    required bool isStarted,
    required bool isCancelled,
    required bool canJoin,
    required bool isDark,
    required Color accent,
    required Color cardColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    if (currentUserId == null) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            top: BorderSide(color: borderColor),
          ),
        ),
        child: Text(
          'Please sign in to join this game',
          style: GoogleFonts.barlowSemiCondensed(
            color: textSecondary,
            fontSize: 13.sp,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (isCancelled && !isHost) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            top: BorderSide(color: borderColor),
          ),
        ),
        child: Text(
          'This game has been cancelled.',
          style: GoogleFonts.barlowSemiCondensed(
            color: Colors.red[400],
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      child: SafeArea(
        top: false,
        child: isHost
            ? _buildHostActions(
                gameModel: gameModel,
                isCancelled: isCancelled,
                isParticipant: isParticipant,
                isFull: isFull,
                isStarted: isStarted,
                currentUserId: currentUserId!,
                isDark: isDark,
                accent: accent,
                textSecondary: textSecondary,
              )
            : _buildGuestActions(
                gameModel: gameModel,
                currentUserId: currentUserId,
                isParticipant: isParticipant,
                isOnWaitlist: isOnWaitlist,
                isFull: isFull,
                isStarted: isStarted,
                canJoin: canJoin,
                isDark: isDark,
                accent: accent,
                textSecondary: textSecondary,
              ),
      ),
    );
  }

  Widget _buildHostActions({
    required GameModel gameModel,
    required bool isCancelled,
    required bool isParticipant,
    required bool isFull,
    required bool isStarted,
    required String currentUserId,
    required bool isDark,
    required Color accent,
    required Color textSecondary,
  }) {
    // Host can join if not already a participant, game not full, not started, and not cancelled
    final bool canJoin = !isParticipant && !isFull && !isStarted && !isCancelled;

    return Row(
      children: [
        // Join Game button (only show if host can join)
        if (canJoin) ...[
          Expanded(
            child: SizedBox(
              height: 44.h,
              child: ElevatedButton.icon(
                onPressed: !_isJoining
                    ? () => _handleJoin(gameModel, currentUserId)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppColors.disabled(isDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  elevation: 0,
                ),
                icon: _isJoining
                    ? SizedBox(
                        width: 18.w,
                        height: 18.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Icon(Icons.person_add, size: 18.sp),
                label: Text(
                  'JOIN GAME',
                  style: GoogleFonts.barlowSemiCondensed(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
        ],
        // Edit button
        Expanded(
          child: SizedBox(
            height: 44.h,
            child: OutlinedButton.icon(
              onPressed: isCancelled
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditGameView(game: gameModel),
                        ),
                      );
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                disabledForegroundColor: textSecondary,
                side: BorderSide(
                  color: isCancelled ? textSecondary : accent,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              icon: Icon(Icons.edit, size: 18.sp),
              label: Text(
                'EDIT',
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        // Cancel button
        Expanded(
          child: SizedBox(
            height: 44.h,
            child: ElevatedButton.icon(
              onPressed: isCancelled ? null : () => _confirmCancel(gameModel.id, isDark),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCancelled ? AppColors.disabled(isDark) : Colors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.disabled(isDark),
                disabledForegroundColor: textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: 0,
              ),
              icon: Icon(Icons.cancel, size: 18.sp),
              label: Text(
                isCancelled ? 'CANCELLED' : 'CANCEL',
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestActions({
    required GameModel gameModel,
    required String currentUserId,
    required bool isParticipant,
    required bool isOnWaitlist,
    required bool isFull,
    required bool isStarted,
    required bool canJoin,
    required bool isDark,
    required Color accent,
    required Color textSecondary,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isStarted && isParticipant)
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton.icon(
              onPressed: !_isLeaving
                  ? () => _handleLeave(gameModel, currentUserId, isDark)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.disabled(isDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: 0,
              ),
              icon: _isLeaving
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.exit_to_app, size: 18.sp),
              label: Text(
                'LEAVE GAME',
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

        if (!isParticipant) ...[
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton.icon(
              onPressed: canJoin && !_isJoining
                  ? () => _handleJoin(gameModel, currentUserId)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canJoin ? accent : AppColors.disabled(isDark),
                foregroundColor: canJoin ? Colors.black : textSecondary,
                disabledBackgroundColor: AppColors.disabled(isDark),
                disabledForegroundColor: textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: 0,
              ),
              icon: _isJoining
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Icon(
                      isStarted || isFull ? Icons.block : Icons.person_add,
                      size: 18.sp,
                    ),
              label: Text(
                isStarted
                    ? 'GAME STARTED'
                    : isFull
                        ? 'GAME FULL'
                        : 'JOIN GAME',
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          if (!isStarted && isFull) ...[
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              height: 40.h,
              child: OutlinedButton.icon(
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
                  foregroundColor: accent,
                  side: BorderSide(color: accent, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                icon: (_isJoiningWaitlist || _isLeavingWaitlist)
                    ? SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      )
                    : Icon(Icons.hourglass_empty, size: 16.sp),
                label: Text(
                  isOnWaitlist ? 'LEAVE WAITLIST' : 'JOIN WAITLIST',
                  style: GoogleFonts.barlowSemiCondensed(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildParticipantsDrawer(GameModel gameModel, bool isDark, Color accent, Color cardColor, Color textPrimary, Color textSecondary, Color borderColor) {
    final bgColor = AppColors.background(isDark);
    
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.55,
      backgroundColor: cardColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: accent, size: 22.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'PLAYERS',
                      style: GoogleFonts.teko(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${gameModel.participants.length}/${gameModel.maxPlayers}',
                    style: GoogleFonts.barlowSemiCondensed(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: gameModel.participants.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Text(
                          'No players yet',
                          style: GoogleFonts.barlowSemiCondensed(
                            color: textSecondary,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: gameModel.participants.length,
                      itemBuilder: (context, index) {
                        final participantId = gameModel.participants[index];
                        final participantName =
                            _participantNames[participantId] ?? 'Loading...';
                        final isHostParticipant = participantId == gameModel.hostId;

                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 4.h,
                          ),
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isHostParticipant
                                  ? accent.withOpacity(0.3)
                                  : borderColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16.r,
                                backgroundColor: isHostParticipant
                                    ? accent.withOpacity(0.3)
                                    : AppColors.disabled(isDark),
                                child: Icon(
                                  Icons.person,
                                  size: 16.sp,
                                  color: isHostParticipant
                                      ? accent
                                      : textSecondary,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      participantName,
                                      style: GoogleFonts.barlowSemiCondensed(
                                        color: textPrimary,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isHostParticipant)
                                      Text(
                                        'HOST',
                                        style: GoogleFonts.barlowSemiCondensed(
                                          color: accent,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            if (gameModel.waitlist.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(
                    top: BorderSide(color: borderColor),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_empty, color: Colors.orange, size: 16.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'WAITLIST',
                      style: GoogleFonts.teko(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${gameModel.waitlist.length}',
                      style: GoogleFonts.barlowSemiCondensed(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(String gameId, bool isDark) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.dialog(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        title: Text(
          'Cancel Game',
          style: GoogleFonts.teko(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary(isDark),
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this game?\nThis action cannot be undone.',
          style: GoogleFonts.barlowSemiCondensed(
            fontSize: 14.sp,
            color: AppColors.textSecondary(isDark),
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'No',
              style: GoogleFonts.barlowSemiCondensed(
                color: AppColors.textSecondary(isDark),
                fontSize: 14.sp,
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.r),
              ),
            ),
            child: Text(
              'Yes, cancel',
              style: GoogleFonts.barlowSemiCondensed(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelGame(gameId);
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color accent, Color textPrimary, Color textSecondary) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: accent),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 10.sp,
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: GoogleFonts.barlowSemiCondensed(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Opens Google Maps with directions to the specified location
  /// Uses the search endpoint for better compatibility - falls back to browser if Maps app isn't available
  Future<void> _openMap(String location) async {
    final encodedLocation = Uri.encodeComponent(location);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedLocation');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening maps: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Future<void> _handleLeave(GameModel game, String userId, bool isDark) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.dialog(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          title: Text(
            'Leave Game',
            style: GoogleFonts.teko(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary(isDark),
            ),
          ),
          content: Text(
            'Are you sure you want to leave this game?',
            style: GoogleFonts.barlowSemiCondensed(
              fontSize: 14.sp,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.barlowSemiCondensed(
                  color: AppColors.textSecondary(isDark),
                  fontSize: 14.sp,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              child: Text(
                'Leave',
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
