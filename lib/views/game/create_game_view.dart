import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/game_controller.dart';
import '../../controllers/game_list_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../theme/app_theme.dart';
import '../../models/game.dart';

class CreateGameView extends StatefulWidget {
  const CreateGameView({super.key});

  @override
  State<CreateGameView> createState() => _CreateGameViewState();
}

class _CreateGameViewState extends State<CreateGameView> {
  final _formKey = GlobalKey<FormState>();

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final maxPlayersCtrl = TextEditingController();

  DateTime? selectedDate;

  bool loading = false;

  final GameController gameController = GameController();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
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

  Future<void> _createGame() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select date & time")),
      );
      return;
    }

    setState(() => loading = true);

    final user = FirebaseAuth.instance.currentUser;

    final game = GameModel(
      id: '',
      hostId: user!.uid,
      title: titleCtrl.text.trim(),
      description: descCtrl.text.trim(),
      date: selectedDate!,
      location: locationCtrl.text.trim(),
      maxPlayers: int.tryParse(maxPlayersCtrl.text.trim()) ?? 0,
      participants: [],
      waitlist: [],
      isCancelled: false,
      createdAt: DateTime.now(),
    );

    final newId = await gameController.createGame(game);

    await GameListController.instance.ensureCurrentUserNameCached();

    // Refresh the games list to show the newly created game
    await GameListController.instance.refresh();

    setState(() => loading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Game created! ID: $newId")),
    );

    context.pop();
  }

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

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textPrimary, size: 22.sp),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'CREATE GAME',
              style: GoogleFonts.teko(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: textPrimary,
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
                      isDark: isDark,
                      accent: accent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: descCtrl,
                      label: "Description",
                      icon: Icons.description_outlined,
                      maxLines: 3,
                      isDark: isDark,
                      accent: accent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: locationCtrl,
                      label: "Location",
                      icon: Icons.location_on_outlined,
                      isDark: isDark,
                      accent: accent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: maxPlayersCtrl,
                      label: "Max Players",
                      icon: Icons.people_outline,
                      keyboardType: TextInputType.number,
                      isDark: isDark,
                      accent: accent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),

                    SizedBox(height: 16.h),

                    // Date Picker
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: borderColor,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, color: accent, size: 18.sp),
                              SizedBox(width: 10.w),
                              Text(
                                selectedDate == null
                                    ? "No date selected"
                                    : "${selectedDate!.year}-${_two(selectedDate!.month)}-${_two(selectedDate!.day)} ${_two(selectedDate!.hour)}:${_two(selectedDate!.minute)}",
                                style: GoogleFonts.barlowSemiCondensed(
                                  color: selectedDate == null ? textSecondary : textPrimary,
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
                                foregroundColor: accent,
                                side: BorderSide(color: accent, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                              ),
                              child: Text(
                                'PICK',
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

                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      height: 46.h,
                      child: ElevatedButton(
                        onPressed: loading ? null : _createGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: accent.withOpacity(0.5),
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
                                  Icon(Icons.add_circle_outline, size: 18.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'CREATE GAME',
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
      },
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color accent,
    required Color textPrimary,
    required Color textSecondary,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.barlowSemiCondensed(color: textPrimary, fontSize: 14.sp),
      validator: (v) => v == null || v.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.barlowSemiCondensed(
          color: textSecondary,
          fontSize: 13.sp,
        ),
        prefixIcon: Icon(
          icon,
          color: textSecondary,
          size: 20.sp,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 12.h,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border(isDark), width: 1),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent, width: 2),
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
