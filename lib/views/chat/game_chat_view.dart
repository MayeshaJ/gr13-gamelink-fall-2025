import 'package:flutter/material.dart';

class GameChatView extends StatefulWidget {
  final String gameId;
  final String gameTitle;

  const GameChatView({
    super.key,
    required this.gameId,
    required this.gameTitle,
  });

  @override
  State<GameChatView> createState() => _GameChatViewState();
}

class _GameChatViewState extends State<GameChatView> {
  final TextEditingController _messageCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  // NOTE: In Iteration 2 we will actually send messages here.
  Future<void> _handleSend() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    // For now, just show a placeholder SnackBar.
    // In the next iteration, this will call a controller method and write to Firestore.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat sending will be implemented in the next iteration.'),
      ),
    );

    _messageCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat - ${widget.gameTitle}'),
      ),
      body: Column(
        children: [
          // Messages area (will be wired to Firestore stream later)
          Expanded(
            child: Center(
              child: Text(
                'No messages yet.\nChat for this game will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const Divider(height: 1),

          // Input area
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _handleSend,
                    icon: _sending
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
