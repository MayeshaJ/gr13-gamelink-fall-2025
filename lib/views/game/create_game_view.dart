import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/game_controller.dart';
import '../../controllers/game_list_controller.dart';
import '../../models/game.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);

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

    // Ensure current user's name is cached for immediate display in game list
    await GameListController.instance.ensureCurrentUserNameCached();

    setState(() => loading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Game created! ID: $newId")),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkNavy,
      appBar: AppBar(
        backgroundColor: kDarkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'CREATE GAME',
          style: GoogleFonts.teko(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: titleCtrl,
                  label: "Game Title",
                  icon: Icons.sports_esports_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: descCtrl,
                  label: "Description",
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: locationCtrl,
                  label: "Location",
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: maxPlayersCtrl,
                  label: "Max Players",
                  icon: Icons.people_outline,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 24),

                // Date Picker
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF243447),
                    borderRadius: BorderRadius.circular(12),
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
                          Icon(Icons.calendar_today_outlined, color: kNeonGreen, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            selectedDate == null
                                ? "No date selected"
                                : "${selectedDate!.year}-${_two(selectedDate!.month)}-${_two(selectedDate!.day)} ${_two(selectedDate!.hour)}:${_two(selectedDate!.minute)}",
                            style: TextStyle(
                              color: selectedDate == null ? Colors.grey[500] : Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton(
                        onPressed: _pickDate,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kNeonGreen,
                          side: BorderSide(color: kNeonGreen, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'PICK',
                          style: GoogleFonts.teko(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: loading ? null : _createGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kNeonGreen,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: kNeonGreen.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'CREATE GAME',
                                style: GoogleFonts.teko(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
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

  String _two(int n) => n.toString().padLeft(2, '0');

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF243447),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.grey[600],
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: kNeonGreen,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
