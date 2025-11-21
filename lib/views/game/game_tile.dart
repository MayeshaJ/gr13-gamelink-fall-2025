import 'package:flutter/material.dart';

import '../../models/game.dart';

class GameTile extends StatelessWidget {
  final Game game;
  final VoidCallback? onTap;

  const GameTile({
    super.key,
    required this.game,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime dt = game.dateTime.toLocal();
    final String dateText =
        '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';

    final bool isOpen = game.status == GameStatus.open;
    final Color chipColor = isOpen ? Colors.green : Colors.red;
    final String chipText = isOpen ? 'Open' : 'Closed';

    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(game.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('${game.hostName} • ${game.location}'),
            const SizedBox(height: 4),
            Text(dateText),
          ],
        ),
        trailing: Chip(
          label: Text(
            chipText,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: chipColor,
        ),
      ),
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}


