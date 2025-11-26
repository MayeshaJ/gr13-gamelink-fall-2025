import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/game_controller.dart';
import '../../controllers/game_list_controller.dart';
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
      appBar: AppBar(title: const Text("Create Game")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "Game Title"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: locationCtrl,
                decoration: const InputDecoration(labelText: "Location"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: maxPlayersCtrl,
                decoration: const InputDecoration(labelText: "Max Players"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(selectedDate == null
                      ? "No date selected"
                      : selectedDate.toString()),
                  ElevatedButton(
                    onPressed: _pickDate,
                    child: const Text("Pick Date & Time"),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: loading ? null : _createGame,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Create Game"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
