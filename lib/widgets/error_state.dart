import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ErrorState extends StatelessWidget {
  final String title;
  final String? details;

  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (details != null && details!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  details!,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


