import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final Widget spinner = const CircularProgressIndicator();
    if (message == null || message!.isEmpty) {
      return Center(child: spinner);
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          spinner,
          const SizedBox(height: 12),
          Text(message!),
        ],
      ),
    );
  }
}


