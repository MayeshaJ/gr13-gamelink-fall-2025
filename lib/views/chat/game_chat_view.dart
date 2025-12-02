import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/app_user.dart';
import '../../controllers/notification_controller.dart';
import '../../models/game.dart';
import '../../controllers/game_controller.dart';


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
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _sending = false;

  CollectionReference get _messagesRef => FirebaseFirestore.instance
      .collection('games')
      .doc(widget.gameId)
      .collection('messages');

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty) return;

    setState(() => _sending = true);

    final AppUser? user = AuthController.instance.currentUser;
    if (user == null) return;

    String senderName = 'Unknown';

    try {
      final userData =
      await UserController.instance.getUserDocument(uid: user.uid);
      if (userData != null) {
        final firstName = userData['firstName'] ?? '';
        final lastName = userData['lastName'] ?? '';
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          senderName = "$firstName $lastName".trim();
        }
      }
    } catch (_) {}

     final text = _msgCtrl.text.trim();

    try {
      await _messagesRef.add({
        'senderId': user.uid,
        'senderName': senderName,
        'text': _msgCtrl.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Create notifications for all other players in the game
      try {
        final gameSnap = await FirebaseFirestore.instance
            .collection('games')
            .doc(widget.gameId)
            .get();

        if (gameSnap.exists) {
          final gameData = gameSnap.data() as Map<String, dynamic>;
          final String hostId = gameData['hostId'] as String? ?? '';
          final List<String> participants =
              List<String>.from(gameData['participants'] ?? []);

          final Set<String> recipients = {
            ...participants,
            if (hostId.isNotEmpty) hostId,
          };

          // Sender shouldn't get a notification about their own message
          recipients.remove(user.uid);

          final String shortText =
              text.length > 80 ? '${text.substring(0, 77)}...' : text;

          for (final uid in recipients) {
            await NotificationController.createNotification(
              toUserId: uid,
              type: 'chat_message',
              message: '$senderName: $shortText',
              gameId: widget.gameId,
              category: 'chat',
            );
          }
        }
      } catch (_) {
        // Don't block sending messages if notifications fail
      }

      _msgCtrl.clear();

      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to send message: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  // -------------------------------------------------------
  // LEFT / RIGHT CHAT BUBBLE BUILDER
  // -------------------------------------------------------
  Widget _buildMessageItem(Map<String, dynamic> data) {
    final senderId = data['senderId'] ?? '';
    final text = data['text'] ?? '';
    final senderName = data['senderName'] ?? 'Unknown';

    final isMe =
        senderId == AuthController.instance.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue.shade400 : Colors.grey.shade200,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft:
              isMe ? const Radius.circular(12) : const Radius.circular(0),
              bottomRight:
              isMe ? const Radius.circular(0) : const Radius.circular(12),
            ),
          ),
          child: Column(
            crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(
                  senderName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
              if (!isMe) const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat – ${widget.gameTitle}"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesRef.orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No messages yet. Say something!",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                Future.delayed(const Duration(milliseconds: 200), () {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollCtrl,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildMessageItem(data);
                  },
                );
              },
            ),
          ),

          // MESSAGE INPUT
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _sending ? null : _sendMessage,
                  icon: _sending
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
