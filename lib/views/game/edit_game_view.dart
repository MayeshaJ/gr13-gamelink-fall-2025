import 'package:flutter/material.dart';
import '../../controllers/game_controller.dart';
import '../../models/game.dart';
import '../../controllers/notification_controller.dart';


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
        const SnackBar(
          content: Text("Game updated!"),
          backgroundColor: Colors.green,
        ),
      );

      // Return true to indicate successful update
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => loading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update game: ${e.toString().replaceFirst('Exception: ', '')}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Game")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "Title"),
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
                  Text(selectedDate!.toString()),
                  ElevatedButton(
                    onPressed: _pickDate,
                    child: const Text("Pick Date & Time"),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: loading ? null : _updateGame,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
