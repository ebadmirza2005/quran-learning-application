import 'package:flutter/material.dart';
import 'package:quran_learning_application/screen/teacher_screen/tutor_call_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController tabController;
  RealtimeChannel? _callChannel;


  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _listenForIncomingCalls();
  }


  void _listenForIncomingCalls() {
    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) return;

    _callChannel = supabase
        .channel('incoming_calls_$currentUserId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'calls',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'receiver_id',
        value: currentUserId,
      ),
      callback: (payload) {
        final newCall = payload.newRecord;
        if (newCall['status'] == 'calling' && mounted) {
          // 💡 Required named parameters yahan map kiye gaye hain
          _showIncomingCallDialog(
            context: context,
            channelId: newCall['channel_id'] ?? '',
            callerName: newCall['caller_name'] ?? 'Tutor',
            callId: newCall['id'] ?? '',
          );
        }
      },
    )
        .subscribe();
  }

  void _showIncomingCallDialog({
    required BuildContext context,
    required String channelId,
    required String callerName,
    required String callId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.call, color: Color(0xff0f766e)),
              SizedBox(width: 8),
              Text("Incoming Call"),
            ],
          ),
          content: Text(
            "$callerName is calling you...",
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            // ❌ DECLINE BUTTON
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Dialog close
                await supabase
                    .from('calls')
                    .update({'status': 'rejected'})
                    .eq('id', callId);
              },
              child: const Text("Decline", style: TextStyle(color: Colors.red)),
            ),

            // 🟢 ACCEPT BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0f766e),
              ),
              onPressed: () async {
                // 1. Dialog ko close karein
                Navigator.of(dialogContext).pop();

                // 2. Supabase mein call status update karein
                try {
                  await supabase
                      .from('calls')
                      .update({'status': 'accepted'})
                      .eq('id', callId);
                } catch (e) {
                  debugPrint("Error updating call status: $e");
                }

                // 3. Call Screen par Navigate karein
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TutorCallScreen(
                        channelId: channelId,
                        receiverName: callerName,
                      ),
                    ),
                  );
                }
              },
              child: const Text("Accept", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    if(_callChannel != null) {
      supabase.removeChannel(_callChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd2dad2),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f766e),
        foregroundColor: Colors.white,
        title: const Text("Classroom"),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "My Tutors"),
            Tab(text: "Invites"),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: const [
          MyTutorsTab(),
          StudentInvitesTab(),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// MY TUTORS TAB (ACCEPTED INVITES)
// -------------------------------------------------------------
class MyTutorsTab extends StatefulWidget {
  const MyTutorsTab({super.key});

  @override
  State<MyTutorsTab> createState() => _MyTutorsTabState();
}

class _MyTutorsTabState extends State<MyTutorsTab> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _myTutorsFuture;

  @override
  void initState() {
    super.initState();
    _loadAcceptedTutors();
  }

  Future<List<Map<String, dynamic>>> _fetchAcceptedTutors() async {
    final currentStudentId = supabase.auth.currentUser?.id;
    if (currentStudentId == null) return [];

    // 1. Invites table se sirf 'accepted' status waale records lao
    final List<dynamic> invitesResponse = await supabase
        .from('invites')
        .select()
        .eq('student_id', currentStudentId)
        .eq('status', 'accepted')
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> acceptedInvites = List<Map<String, dynamic>>.from(invitesResponse);

    if (acceptedInvites.isEmpty) return [];

    // 2. Unique tutor IDs nikalain
    final tutorIds = acceptedInvites
        .map((e) => e['tutor_id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet()
        .toList();

    if (tutorIds.isEmpty) return [];

    // 3. Tutors ki details fetch karein
    final List<dynamic> tutorsResponse = await supabase
        .from('tutors')
        .select()
        .filter('id', 'in', tutorIds);

    final Map<String, Map<String, dynamic>> tutorMap = {
      for (var t in tutorsResponse) t['id'].toString(): Map<String, dynamic>.from(t)
    };

    // 4. Invites aur Tutors data merge karein
    List<Map<String, dynamic>> resultList = [];
    for (var invite in acceptedInvites) {
      final tId = invite['tutor_id']?.toString();
      if (tId != null && tutorMap.containsKey(tId)) {
        var tutorData = tutorMap[tId]!;
        resultList.add({
          'invite_id': invite['id'],
          'selected_skills': invite['selected_skills'],
          'duration': invite['duration'],
          'tutor_id': tId,
          'name': tutorData['name'] ?? 'Unknown Tutor',
          'profile_image': tutorData['profile_image'],
          'city': tutorData['city'] ?? '',
          'country': tutorData['country'] ?? '',
          'hourly_rate': invite['hourly_rate'] ?? tutorData['hourly_rate'] ?? 0.0,
        });
      }
    }

    return resultList;
  }

  void _loadAcceptedTutors() {
    _myTutorsFuture = _fetchAcceptedTutors();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _myTutorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xff0f766e)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading tutors: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        }

        final tutors = snapshot.data ?? [];

        if (tutors.isEmpty) {
          return const Center(
            child: Text(
              "No Tutors Found!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _loadAcceptedTutors();
            });
          },
          color: const Color(0xff0f766e),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: tutors.length,
            itemBuilder: (context, index) {
              final item = tutors[index];
              final String name = item['name'];
              final String? profileImage = item['profile_image'];
              final String location = "${item['city']}, ${item['country']}".trim();
              final List<dynamic> skills = item['selected_skills'] ?? [];

              return Card(
                color: Colors.white,
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xff0f766e).withOpacity(0.1),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: (profileImage != null && profileImage.isNotEmpty)
                              ? Image.network(
                            profileImage,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person, color: Color(0xff0f766e), size: 30),
                          )
                              : const Icon(Icons.person, color: Color(0xff0f766e), size: 30),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xff0f766e),
                              ),
                            ),
                            if (location.length > 2) ...[
                              const SizedBox(height: 2),
                              Text(
                                location,
                                style: const TextStyle(color: Colors.black54, fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              "Subjects: ${skills.isNotEmpty ? skills.join(', ') : 'All'}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat, color: Color(0xff0f766e)),
                        onPressed: () {
                          // TODO: Direct Chat or Call screen navigation
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.phone,
                          color: Color(0xff0f766e),
                        ),

                        onPressed: () async {

                          try {

                            final studentUser =
                                supabase.auth.currentUser;


                            if(studentUser == null){
                              return;
                            }


                            final tutorId =
                            item['tutor_id'].toString();


                            final tutorName =
                            item['name'].toString();


                            final channelId =
                                "call_${item['invite_id']}_${DateTime.now().millisecondsSinceEpoch}";


                            await supabase
                                .from('calls')
                                .insert({

                              'caller_id': studentUser.id,

                              'caller_name': "Student",

                              'receiver_id': tutorId,

                              'channel_id': channelId,

                              'status': 'calling',

                            });



                            if(!mounted) return;


                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TutorCallScreen(
                                  channelId: channelId,
                                  receiverName: tutorName,
                                ),
                              ),
                            );


                          } catch(e){

                            debugPrint(
                                "Student Call Error: $e"
                            );


                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content:
                                Text("Call Error: $e"),
                              ),
                            );

                          }

                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// ALL INVITES TAB (PENDING & REJECTED ONLY)
// -------------------------------------------------------------
class StudentInvitesTab extends StatefulWidget {
  const StudentInvitesTab({super.key});

  @override
  State<StudentInvitesTab> createState() => _StudentInvitesTabState();
}

class _StudentInvitesTabState extends State<StudentInvitesTab> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _myInvitesFuture;

  @override
  void initState() {
    super.initState();
    _loadMyInvites();
  }

  Future<List<Map<String, dynamic>>> _fetchInvitesWithTutorDetails() async {
    final currentStudentId = supabase.auth.currentUser?.id;
    if (currentStudentId == null) return [];

    // Sirf wohi invites fetch hongay jo ACCEPTED nahi hain (yaani pending ya rejected)
    final List<dynamic> invitesResponse = await supabase
        .from('invites')
        .select()
        .eq('student_id', currentStudentId)
        .neq('status', 'accepted')
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> invites = List<Map<String, dynamic>>.from(invitesResponse);

    if (invites.isEmpty) return [];

    final tutorIds = invites
        .map((e) => e['tutor_id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet()
        .toList();

    if (tutorIds.isEmpty) return invites;

    final List<dynamic> tutorsResponse = await supabase
        .from('tutors')
        .select('id, name, profile_image')
        .filter('id', 'in', tutorIds);

    final Map<String, Map<String, dynamic>> tutorMap = {
      for (var t in tutorsResponse) t['id'].toString(): Map<String, dynamic>.from(t)
    };

    for (var invite in invites) {
      final tId = invite['tutor_id']?.toString();
      if (tId != null && tutorMap.containsKey(tId)) {
        invite['tutors'] = tutorMap[tId];
      }
    }

    return invites;
  }

  void _loadMyInvites() {
    _myInvitesFuture = _fetchInvitesWithTutorDetails();
  }

  // Invite Delete karne ke liye function
  Future<void> _deleteInvite(dynamic inviteId) async {
    try {
      await supabase.from('invites').delete().eq('id', inviteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invite removed successfully!"),
            backgroundColor: Color(0xff0f766e),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          _loadMyInvites();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete invite: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _myInvitesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xff0f766e)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading invites: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        }

        final invites = snapshot.data ?? [];

        if (invites.isEmpty) {
          return const Center(
            child: Text(
              "No Invitation Found!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _loadMyInvites();
            });
          },
          color: const Color(0xff0f766e),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final invite = invites[index];

              final tutorData = invite['tutors'] as Map<String, dynamic>?;
              final tutorName = tutorData?['name'] ?? 'Unknown Tutor';
              final String duration = invite['duration'] ?? 'N/A';
              final String status = invite['status'] ?? 'pending';
              final double rate = (invite['hourly_rate'] as num? ?? 0.0).toDouble();
              final List<dynamic> skills = invite['selected_skills'] ?? [];
              final inviteId = invite['id'];

              return Card(
                color: Colors.white,
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              "Tutor: $tutorName",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xff0f766e),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: status == 'pending'
                                      ? Colors.orange.withOpacity(0.15)
                                      : Colors.red.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: status == 'pending'
                                        ? Colors.orange.shade800
                                        : Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _deleteInvite(inviteId),
                                borderRadius: BorderRadius.circular(20),
                                child: const Padding(
                                  padding: EdgeInsets.all(2.0),
                                  child: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Duration: $duration",
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(text: "Skills: ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            TextSpan(text: skills.isNotEmpty ? skills.join(', ') : 'None', style: const TextStyle(color: Colors.black87)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(text: "Rate: ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            TextSpan(text: "\$$rate / hour", style: const TextStyle(color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}