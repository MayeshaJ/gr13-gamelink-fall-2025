import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/notification_controller.dart';

// Color Palette
const kDarkNavy = Color(0xFF1A2332);
const kNeonGreen = Color(0xFF39FF14);


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
  bool _isLoading = true;
  bool _hasAccess = false;

  CollectionReference get _messagesRef => FirebaseFirestore.instance
      .collection('games')
      .doc(widget.gameId)
      .collection('messages');

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final currentUser = AuthController.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _hasAccess = false;
      });
      return;
    }

    try {
      final gameDoc = await FirebaseFirestore.instance
          .collection('games')
          .doc(widget.gameId)
          .get();

      if (!gameDoc.exists) {
        setState(() {
          _isLoading = false;
          _hasAccess = false;
        });
        return;
      }

      final gameData = gameDoc.data() as Map<String, dynamic>;
      final hostId = gameData['hostId'] as String? ?? '';
      final participants = List<String>.from(gameData['participants'] ?? []);

      final isHost = currentUser.uid == hostId;
      final isParticipant = participants.contains(currentUser.uid);

      setState(() {
        _isLoading = false;
        _hasAccess = isHost || isParticipant;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasAccess = false;
      });
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty) return;

    setState(() => _sending = true);

    final user = AuthController.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _sending = false);
      }
      return;
    }

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
            color: isMe ? const Color(0xFF2196F3) : kNeonGreen,
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
                      fontWeight: FontWeight.bold, 
                      fontSize: 12,
                      color: Colors.black,
                  ),
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
      backgroundColor: kDarkNavy,
      appBar: AppBar(
        backgroundColor: kDarkNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "CHAT – ${widget.gameTitle.toUpperCase()}",
          style: GoogleFonts.teko(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: kNeonGreen,
              ),
            )
          : !_hasAccess
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'ACCESS RESTRICTED',
                          style: GoogleFonts.teko(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Only the host and participants can access this chat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kNeonGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'GO BACK',
                            style: GoogleFonts.teko(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesRef.orderBy('timestamp').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: kNeonGreen,
                    ),
                  );
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
            decoration: BoxDecoration(
              color: const Color(0xFF243447),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: kDarkNavy,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: kNeonGreen,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: kNeonGreen,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _sending ? null : _sendMessage,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
