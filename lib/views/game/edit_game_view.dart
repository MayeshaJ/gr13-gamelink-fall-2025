import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/game_controller.dart';
import '../../models/game.dart';
import '../../controllers/notification_controller.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);

class EditGameView extends StatefulWidget {
  final GameModel game;

  const EditGameView({super.key, required this.game});

  @override
  State<EditGameView> createState() => _EditGameViewState();
}

class _EditGameViewState extends State<EditGameView> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;
  late TextEditingController locationCtrl;
  late TextEditingController maxPlayersCtrl;

  DateTime? selectedDate;
  bool loading = false;

  final GameController gameController = GameController();

  @override
  void initState() {
    super.initState();

    titleCtrl = TextEditingController(text: widget.game.title);
    descCtrl = TextEditingController(text: widget.game.description);
    locationCtrl = TextEditingController(text: widget.game.location);
    maxPlayersCtrl =
        TextEditingController(text: widget.game.maxPlayers.toString());

    selectedDate = widget.game.date;
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    locationCtrl.dispose();
    maxPlayersCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: selectedDate,
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDate!),
      );

      if (time != null) {
        setState(() {
          selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _updateGame() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

   // Compare against original to see if schedule changed
    final DateTime oldDate = widget.game.date;
    final String oldLocation = widget.game.location;

    final DateTime newDate = selectedDate ?? widget.game.date;
    final String newLocation = locationCtrl.text.trim();

    final bool dateChanged = !oldDate.isAtSameMomentAs(newDate);
    final bool locationChanged = oldLocation != newLocation;

    final bool scheduleChanged = dateChanged || locationChanged;

    try {
      await gameController.updateGame(widget.game.id, {
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'location': newLocation,
        'maxPlayers': int.tryParse(maxPlayersCtrl.text.trim()) ?? 0,
        'date': newDate,
      });

      setState(() => loading = false);

      // Notify participants if the schedule changed
      if (scheduleChanged) {
        final Set<String> recipientIds = {
          ...widget.game.participants,
        };

        // notify waitlist
        recipientIds.addAll(widget.game.waitlist);

        // Host already knows they changed it
        recipientIds.remove(widget.game.hostId);

        final String formattedDate =
            newDate.toLocal().toString().substring(0, 16);

        final String baseTitle = widget.game.title;

        for (final uid in recipientIds) {
          String msg;
          if (dateChanged && locationChanged) {
            msg =
                'The game "$baseTitle" has been rescheduled to $formattedDate at $newLocation.';
          } else if (dateChanged) {
            msg = 'The game "$baseTitle" has been rescheduled to $formattedDate.';
          } else {
            msg =
                'The location for "$baseTitle" has changed to $newLocation.';
          }

          await NotificationController.createNotification(
            toUserId: uid,
            type: 'game_rescheduled',
            message: msg,
            gameId: widget.game.id,
            category: 'game_update',
          );
        }
      }


      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Game updated!",
            style: GoogleFonts.barlowSemiCondensed(fontSize: 14.sp),
          ),
          backgroundColor: kNeonGreen,
        ),
      );

      // Return true to indicate successful update
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => loading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to update game: ${e.toString().replaceFirst('Exception: ', '')}",
            style: GoogleFonts.barlowSemiCondensed(fontSize: 14.sp),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkNavy,
      appBar: AppBar(
        backgroundColor: kDarkNavy,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 22.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'EDIT GAME',
          style: GoogleFonts.teko(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(12.w),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: titleCtrl,
                  label: "Game Title",
                  icon: Icons.sports_esports_outlined,
                ),
                SizedBox(height: 12.h),
                _buildTextField(
                  controller: descCtrl,
                  label: "Description",
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
                SizedBox(height: 12.h),
                _buildTextField(
                  controller: locationCtrl,
                  label: "Location",
                  icon: Icons.location_on_outlined,
                ),
                SizedBox(height: 12.h),
                _buildTextField(
                  controller: maxPlayersCtrl,
                  label: "Max Players",
                  icon: Icons.people_outline,
                  keyboardType: TextInputType.number,
                ),

                SizedBox(height: 16.h),

                // Date Picker
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF243447),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, color: kNeonGreen, size: 18.sp),
                          SizedBox(width: 10.w),
                          Text(
                            selectedDate == null
                                ? "No date selected"
                                : "${selectedDate!.year}-${_two(selectedDate!.month)}-${_two(selectedDate!.day)} ${_two(selectedDate!.hour)}:${_two(selectedDate!.minute)}",
                            style: GoogleFonts.barlowSemiCondensed(
                              color: selectedDate == null ? Colors.grey[500] : Colors.white,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 32.h,
                        child: OutlinedButton(
                          onPressed: _pickDate,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kNeonGreen,
                            side: const BorderSide(color: kNeonGreen, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                          ),
                          child: Text(
                            'CHANGE',
                            style: GoogleFonts.barlowSemiCondensed(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    onPressed: loading ? null : _updateGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kNeonGreen,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: kNeonGreen.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                    child: loading
                        ? SizedBox(
                            height: 18.h,
                            width: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 18.sp),
                              SizedBox(width: 8.w),
                              Text(
                                'SAVE CHANGES',
                                style: GoogleFonts.barlowSemiCondensed(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.barlowSemiCondensed(color: Colors.white, fontSize: 14.sp),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.barlowSemiCondensed(
          color: Colors.grey[500],
          fontSize: 13.sp,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.grey[600],
          size: 20.sp,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 12.h,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: kNeonGreen, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
