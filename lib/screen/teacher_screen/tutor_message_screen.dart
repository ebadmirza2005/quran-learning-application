import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quran_learning_application/utils/text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'tutor_chat_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _supabase = Supabase.instance.client;
  late final String _currentUserId;

  final Map<String, Map<String, dynamic>> _partnerCache = {};
  final Set<String> _validUserIds = {};
  bool _isLoadingInitial = true;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser!.id;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final tutors = await _supabase.from('tutors').select('id');
      final students = await _supabase.from('students').select('id');

      for (var t in tutors) {
        _validUserIds.add(t['id'].toString());
      }
      for (var s in students) {
        _validUserIds.add(s['id'].toString());
      }
    } catch (e) {
      debugPrint("Error loading valid user IDs: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _getPartnerDetailsCached(String id) async {
    if (_partnerCache.containsKey(id)) {
      return _partnerCache[id];
    }

    try {
      var partnerData = await _supabase.from('tutors').select('name, profile_image').eq('id', id).maybeSingle();
      if (partnerData == null) {
        partnerData = await _supabase.from('students').select('name, profile_image').eq('id', id).maybeSingle();
      }

      if (partnerData != null) {
        _partnerCache[id] = partnerData;
        return partnerData;
      }
    } catch (e) {
      debugPrint("Error fetching partner details: $e");
    }
    return null;
  }

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
  Widget build(BuildContext context) {
    if (_isLoadingInitial) {
      return const Scaffold(
        backgroundColor: Color(0xffd2dad2),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xff0f766e)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: const Text("Messages"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
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

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          final allMessages = snapshot.data ?? [];

          final myMessages = allMessages.where((msg) {
            return msg['sender_id'] == _currentUserId || msg['receiver_id'] == _currentUserId;
          }).toList();

          final List<String> chatPartnerIds = [];
          final List<Map<String, dynamic>> distinctRecentChats = [];

          for (var msg in myMessages) {
            final String partnerId = msg['sender_id'] == _currentUserId
                ? msg['receiver_id']
                : msg['sender_id'];

            if (_validUserIds.contains(partnerId)) {
              if (!chatPartnerIds.contains(partnerId)) {
                chatPartnerIds.add(partnerId);
                distinctRecentChats.add({
                  'partner_id': partnerId,
                  'last_message': msg['message_text'],
                  'time': msg['created_at'],
                });
              }
            }
          }

          if (distinctRecentChats.isEmpty) {
            return const Center(
              child: Text(
                "No Conversation Found!",
                style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: distinctRecentChats.length,
            itemBuilder: (context, index) {
              final chat = distinctRecentChats[index];
              final partnerId = chat['partner_id'];
              final lastMessage = chat['last_message'];
              final messageTime = chat['time'];

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getPartnerDetailsCached(partnerId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting && !_partnerCache.containsKey(partnerId)) {
                    return const SizedBox(height: 72);
                  }

                  final partnerData = userSnapshot.data ?? _partnerCache[partnerId];
                  if (partnerData == null) {
                    return const SizedBox.shrink();
                  }

                  final String partnerName = partnerData['name'] ?? "Unknown Name";
                  final String? partnerImage = partnerData['profile_image'];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xff0f766e),
                        backgroundImage: partnerImage != null && partnerImage.toString().isNotEmpty
                            ? NetworkImage(partnerImage.toString())
                            : null,
                        child: partnerImage == null || partnerImage.toString().isEmpty
                            ? Text(
                          partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18
                          ),
                        )
                            : null,
                      ),
                      title: Text(
                        partnerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        lastMessage ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextWidget(
                            text: _formatMessageTime(messageTime),
                            textSize: 11,
                            textColor: Colors.black45,
                            textWeight: FontWeight.w500,
                          ),
                          const SizedBox(height: 4),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TutorChatScreen(
                              receiverId: partnerId,
                              receiverName: partnerName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}