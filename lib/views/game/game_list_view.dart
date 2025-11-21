import 'package:flutter/material.dart';

class GameListView extends StatelessWidget {
  const GameListView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> mockGames = <String>[
      'Pickup Soccer - Saturday 10AM - Central Park',
      'Basketball 3v3 - Friday 6PM - Community Gym',
      'Tennis Doubles - Sunday 2PM - Courts A/B',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mockGames.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          return Card(
            child: ListTile(
              title: Text(mockGames[index]),
            ),
          );
        },
      ),
    );
  }
}


