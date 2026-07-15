import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../student_screen/student_chat_screen.dart';

class StudentMessageScreen extends StatefulWidget {
  const StudentMessageScreen({super.key});

  @override
  State<StudentMessageScreen> createState() => _StudentMessageScreenState();
}

class _StudentMessageScreenState extends State<StudentMessageScreen> {
  final _supabase = Supabase.instance.client;
  late final String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser!.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xffd2dad2),
        appBar: AppBar(
          backgroundColor: Color(0xff0f766e),
          foregroundColor: Colors.white,
          title: Text("Messages"),
          centerTitle: true,
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase.from('messages').stream(primaryKey: ['id']).order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xff0f766e),),
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

              if (myMessages.isEmpty) {
                return const Center(
                  child: Text("No Conversation Found!"),
                );
              }

              final List<String> chatPartnerIds = [];
              final List<Map<String, dynamic>> distinctRecentChats = [];

              for (var msg in myMessages) {
                final String partnerId = msg['sender_id'] == _currentUserId ? msg['receiver_id'] : msg['sender_id'];

                if (!chatPartnerIds.contains(partnerId)) {
                  chatPartnerIds.add(partnerId);
                  distinctRecentChats.add({
                    'partner_id': partnerId,
                    'last_message': msg['message_text'],
                    'time': msg['created_at'],
                  });
                }
              }

              return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: distinctRecentChats.length,
                  itemBuilder: (context, index) {
                    final chat = distinctRecentChats[index];
                    final partnerId = chat['partner_id'];
                    final lastMessage = chat['last_message'];

                    return FutureBuilder<PostgrestMap?>(
                        future: _getPartnerDetails(partnerId),
                        builder: (context, userSnapshot) {
                          String partnerName = "Loading...";
                          String? partnerImage;
                          if (userSnapshot.hasData && userSnapshot.data != null) {
                            partnerName = userSnapshot.data!['name'] ?? "Unknown Name";
                            partnerImage = userSnapshot.data!['profile_image'];
                          }else if(userSnapshot.connectionState == ConnectionState.done) {
                            partnerName = "Chat Partner";
                          }

                          return Card (
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
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                )
                                    : null,
                              ),
                              title: Text(
                                partnerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentChatScreen(
                                      receiverId: partnerId,
                                      receiverName: partnerName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                    );

                  });
            }
        )
    );
  }

  Future<PostgrestMap?> _getPartnerDetails(String id) async {
    try {
      final tutorData = await _supabase.from('tutors').select('name, profile_image').eq('id', id).maybeSingle();
      if (tutorData != null) return tutorData;

      final studentData = await _supabase.from('students').select('name, profile_image').eq('id', id).maybeSingle();
      return studentData;
    }catch (e) {
      return null;
    }
  }
}


