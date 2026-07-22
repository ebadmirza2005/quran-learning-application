import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  const StudentChatScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  late final String _currentUserId;

  String? _receiverProfileUrl;
  bool _isLoadingProfile = true;

  String _formatMessageTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final parsedDate = DateTime.parse(timestamp).toLocal();
      return DateFormat('hh:mm a').format(parsedDate);
    } catch (e) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser!.id;
    _markAllPastMessagesAsRead();
    _fetchReceiverProfile();
  }

  Future<void> _fetchReceiverProfile() async {
    try {
      var response = await _supabase
          .from('students')
          .select('profile_image')
          .eq('id', widget.receiverId.trim())
          .maybeSingle();

      if (response == null || response['profile_image'] == null) {
        response = await _supabase
            .from('tutors')
            .select('profile_image')
            .eq('id', widget.receiverId.trim())
            .maybeSingle();
      }

      if (response != null && response['profile_image'] != null) {
        if (mounted) {
          setState(() {
            _receiverProfileUrl = response!['profile_image'];
            _isLoadingProfile = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching receiver profile image: $e");
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _markAllPastMessagesAsRead() async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', widget.receiverId.trim())
          .eq('receiver_id', _currentUserId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint("Error updating read status: $e");
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await _supabase.from('messages').insert({
        'sender_id': _currentUserId,
        'receiver_id': widget.receiverId.trim(),
        'message_text': text,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'is_read': false,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            _receiverProfileUrl != null && _receiverProfileUrl!.isNotEmpty
            ? CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                    _receiverProfileUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stacktTrace) {
                      return Center(
                        child: Icon(Icons.person, color: Colors.white, size: 24)
                      );
                    },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff0f766e),
                        strokeWidth: 2,
                      ),
                    );
                  },
                ),
              ),
            )
                :
                CircleAvatar(
                  radius: 20,
                  foregroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: CircleAvatar(
                      backgroundColor: Color(0xff0f766e),
                      child: const Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                  ),
                ),

            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.receiverName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
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
                      child: CircularProgressIndicator(color: Color(0xff0f766e)),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No conversation yet"));
                  }

                  final allMessages = snapshot.data!;

                  final chatMessages = allMessages.where((msg) {
                    final sId = msg['sender_id'].toString().trim().toLowerCase();
                    final rId = msg['receiver_id'].toString().trim().toLowerCase();
                    final current = _currentUserId.trim().toLowerCase();
                    final partner = widget.receiverId.trim().toLowerCase();
                    return (sId == current && rId == partner) || (sId == partner && rId == current);
                  }).toList();
                  if (chatMessages.isNotEmpty) {
                    final lastMessage = chatMessages.first;
                    if (lastMessage['sender_id'].toString().trim().toLowerCase() == widget.receiverId.trim().toLowerCase() &&
                        lastMessage['is_read'] == false) {
                      _supabase
                          .from('messages')
                          .update({'is_read': true})
                          .eq('id', lastMessage['id']);
                    }
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = chatMessages[index];

                      final bool isMe = msg['sender_id'].toString().trim().toLowerCase() == _currentUserId.trim().toLowerCase();
                      final bool isRead = msg['is_read'] ?? false;

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xff0f766e) : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isMe ? 12 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 12),
                            ),
                          ),
                          child: IntrinsicWidth(
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  msg['message_text'] ?? '',
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isMe) ...[
                                      Icon(
                                        Icons.done_all,
                                        size: 14,
                                        color: isRead ? Colors.tealAccent : Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isRead ? "Seen" : "Sent",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      _formatMessageTime(msg['created_at']),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isMe ? Colors.white70 : Colors.black45,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.center,
                      onTapOutside: (event) {
                        FocusScope.of(context).unfocus();
                      },
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xff0f766e), width: 2),
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _messageController,
                          builder: (context, value, child) {
                            return value.text.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                              onPressed: () => _messageController.clear(),
                            )
                                : const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xff0f766e),
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}