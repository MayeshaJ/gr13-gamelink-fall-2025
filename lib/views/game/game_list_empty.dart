import 'package:flutter/material.dart';

class GameListEmpty extends StatelessWidget {
  final VoidCallback? onRefresh;
  const GameListEmpty({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.sports_soccer, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'No games yet',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pull to refresh or create a new game.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...<Widget>[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRefresh,
                child: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


