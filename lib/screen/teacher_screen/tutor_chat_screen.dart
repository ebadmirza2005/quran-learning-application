import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TutorChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  const TutorChatScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  State<TutorChatScreen> createState() => _TutorChatScreenState();
}

class _TutorChatScreenState extends State<TutorChatScreen> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  late final String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser!.id;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await _supabase.from('messages').insert({
        'sender_id': _currentUserId,
        'receiver_id': widget.receiverId,
        'message_text': text,
      });
    }catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff0f766e),
          foregroundColor: Colors.white,
          title: Text(widget.receiverName),
          centerTitle: true,
        ),

      body: Column(
        children: [
          Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase
                      .from('messages')
                      .stream(primaryKey: ['id'])
                      .order('created_at', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xff0f766e),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text("No conversation yet"),
                      );
                    }

                    final allMessages = snapshot.data!;

                    final chatMessages = allMessages.where((msg) {
                      final sId = msg['sender_id'];
                      final rId = msg['receiver_id'];
                      return (sId == _currentUserId && rId == widget.receiverId) ||
                          (sId == widget.receiverId && rId == _currentUserId);
                    }).toList();

                    return ListView.builder(
                        reverse: true, // 🌟 Naye messages ko niche se load karne ke liye
                        padding: const EdgeInsets.all(16),
                        itemCount: chatMessages.length,
                        itemBuilder: (context, index) {
                          final msg = chatMessages[index];

                          // 🌟 FIXED: Ab 'isMe' strictly true ya false dynamic bool hai
                          final bool isMe = msg['sender_id'] == _currentUserId;

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xff0f766e) : Colors.grey[300],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: Radius.circular(isMe ? 12 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 12),
                                ),
                              ),
                              child: Text(
                                msg['message_text'] ?? '',
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        });
                  }
              )
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xff0f766e)),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
