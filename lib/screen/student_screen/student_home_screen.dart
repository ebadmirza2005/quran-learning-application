import 'package:flutter/material.dart';
import 'package:quran_learning_application/screen/teacher_screen/tutor_call_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/button.dart';
import '../../utils/text.dart';
import 'student_chat_screen.dart';

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
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await supabase
                    .from('calls')
                    .update({'status': 'rejected'})
                    .eq('id', callId);
              },
              child: const Text("Decline", style: TextStyle(color: Colors.red)),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0f766e),
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                try {
                  await supabase
                      .from('calls')
                      .update({'status': 'accepted'})
                      .eq('id', callId);
                } catch (e) {
                  debugPrint("Error updating call status: $e");
                }

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

    final List<dynamic> invitesResponse = await supabase
        .from('invites')
        .select()
        .eq('student_id', currentStudentId)
        .eq('status', 'accepted')
        .order('created_at', ascending: false);

    List<Map<String, dynamic>> acceptedInvites =
    List<Map<String, dynamic>>.from(invitesResponse);

    if (acceptedInvites.isEmpty) return [];

    final tutorIds = acceptedInvites
        .map((e) => e['tutor_id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet()
        .toList();

    if (tutorIds.isEmpty) return [];

    final List<dynamic> tutorsResponse = await supabase
        .from('tutors')
        .select()
        .filter('id', 'in', tutorIds);

    final Map<String, Map<String, dynamic>> tutorMap = {
      for (var t in tutorsResponse)
        t['id'].toString(): Map<String, dynamic>.from(t)
    };

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
          'hourly_rate':
          invite['hourly_rate'] ?? tutorData['hourly_rate'] ?? 0.0,
          'current_rating': tutorData['rating'] ?? 0.0, // Fetched rating column directly
        });
      }
    }

    return resultList;
  }

  void _loadAcceptedTutors() {
    setState(() {
      _myTutorsFuture = _fetchAcceptedTutors();
    });
  }

  Future<void> _endContract(dynamic inviteId) async {
    bool? confirm = await showDialog<bool>(
      barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
        title: Center(child: const TextWidget(text: "End Contract", textWeight: FontWeight.bold, textColor: Color(0xff0f766e),)),
        content: const Text(
            "Terminating this contract will discontinue your scheduled sessions with this tutor. You will no longer be able to join their classroom. Do you wish to proceed?"),
        actions: [
          Row(
            children: [
              Expanded(child: ElevatedButtonWidget(buttonText: "No",
                  textColor: Colors.white,
                  buttonColor: Color(0xff0f766e),
                  onTap: () => Navigator.of(context).pop(false))),
              SizedBox(width: 10,),
              Expanded(child: ElevatedButtonWidget(buttonText: "Yes",
                buttonColor: Color(0xff0f766e),
                textColor: Colors.white,
                onTap: () {
                  Navigator.of(context).pop(true);
                },))
            ],
          )
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('invites').delete().eq('id', inviteId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Contract ended successfully."),
              backgroundColor: Color(0xff0f766e),
            ),
          );
          _loadAcceptedTutors();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error ending contract: $e")),
          );
        }
      }
    }
  }


  void _showFeedbackDialog(String tutorId, String tutorName) {
    double selectedRating = 5.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                "Feedback for $tutorName",
                style: const TextStyle(
                  color: Color(0xff0f766e),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Rate your experience with this tutor:"),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            selectedRating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0f766e),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updateTutorRatingDirectly(tutorId, selectedRating);
                  },
                  child: const Text(
                    "Submit",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateTutorRatingDirectly(
      String tutorId, double newRating) async {
    final studentId = supabase.auth.currentUser?.id;

    if (studentId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to submit rating")),
        );
      }
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      String storageKey = 'user_rating_${tutorId}_$studentId';
      double? previousUserRating = prefs.getDouble(storageKey);

      final response = await supabase
          .from('tutors')
          .select('rating, rating_count')
          .eq('id', tutorId)
          .maybeSingle();

      if (response == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error: Tutor profile not found!"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      double currentRating = (response['rating'] as num?)?.toDouble() ?? 0.0;
      int currentCount = (response['rating_count'] as num?)?.toInt() ?? 0;

      int updatedCount;
      double updatedRating;

      if (previousUserRating != null) {

        updatedCount = currentCount == 0 ? 1 : currentCount; // Count same rahega

        double currentTotalSum = currentRating * updatedCount;
        double newTotalSum = (currentTotalSum - previousUserRating) + newRating;

        updatedRating = newTotalSum / updatedCount;
      } else {
        updatedCount = currentCount + 1; // Count +1 hoga

        if (currentCount == 0 || currentRating == 0.0) {
          updatedRating = newRating;
        } else {
          updatedRating = ((currentRating * currentCount) + newRating) / updatedCount;
        }
      }

      updatedRating = double.parse(updatedRating.toStringAsFixed(1));

      debugPrint("Student: $studentId | New Rating: $updatedRating | Count: $updatedCount");

      await supabase.from('tutors').update({
        'rating': updatedRating,
        'rating_count': updatedCount,
      }).eq('id', tutorId);

      await prefs.setDouble(storageKey, newRating);

      if (mounted) {
        String message = previousUserRating != null
            ? "Your rating was updated to $newRating!"
            : "Rating submitted successfully!";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xff0f766e),
          ),
        );
        _loadAcceptedTutors();
      }
    } catch (e) {
      debugPrint("Rating Update Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating rating: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadAcceptedTutors();
          },
          color: const Color(0xff0f766e),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: tutors.length,
            itemBuilder: (context, index) {
              final item = tutors[index];
              final String name = item['name'];
              final String? profileImage = item['profile_image'];
              final String duration = item['duration'] ?? 'N/A';
              final double rate = (item['hourly_rate'] as num?)?.toDouble() ?? 0.0;
              final List<dynamic> skills = item['selected_skills'] ?? [];

              return Card(
                color: Colors.white,
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                        const Color(0xff0f766e).withOpacity(0.1),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: (profileImage != null &&
                              profileImage.isNotEmpty)
                              ? Image.network(
                            profileImage,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.person,
                                color: Color(0xff0f766e), size: 30),
                          )
                              : const Icon(Icons.person,
                              color: Color(0xff0f766e), size: 30),
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
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                TextWidget(text: "Teach:  ", textWeight: FontWeight.bold, textColor: Color(0xff0f766e),),
                                TextWidget(text: skills.isNotEmpty ? skills.join(', ') : 'All')
                              ],
                            ),
                            Row(
                              children: [
                                TextWidget(text: "Duration:  ", textWeight: FontWeight.bold, textColor: Color(0xff0f766e),),
                                TextWidget(text: duration,)
                              ],
                            ),
                            Row(
                              children: [
                                TextWidget(text: "Rate:  ", textWeight: FontWeight.bold, textColor: Color(0xff0f766e),),
                                TextWidget(text: '\$$rate / hour',)
                              ],
                            )
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat, color: Color(0xff0f766e)),
                        onPressed: () {
                          try {
                            final studentUser = supabase.auth.currentUser;

                            if (studentUser == null) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please login to start chat")),
                              );
                              return;
                            }

                            final tutorId = item['tutor_id']?.toString() ?? '';
                            final tutorName = item['name']?.toString() ?? 'Tutor';
                            final tutorImage = (item['profile_image'] ??
                                item['avatar_url'] ??
                                item['image'])?.toString();

                            if (tutorId.isEmpty) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Invalid Tutor ID")),
                              );
                              return;
                            }

                            if (!context.mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentChatScreen(
                                  receiverId: tutorId,
                                  receiverName: tutorName,
                                ),
                              ),
                            );
                          } catch (e) {
                            debugPrint("Chat Navigation Error: $e");

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error opening chat: $e"),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.phone,
                          color: Color(0xff0f766e),
                        ),
                        onPressed: () async {
                          try {
                            final studentUser = supabase.auth.currentUser;

                            if (studentUser == null) {
                              return;
                            }

                            final tutorId = item['tutor_id'].toString();
                            final tutorName = item['name'].toString();
                            final tutorImage = item['profile_image'] ?? item['avatar_url'] ?? item['image'];

                            // 🔴 1. Current Student ki Profile (Name & Image) 'students' table se fetch karein
                            final studentProfile = await supabase
                                .from('students') // Aapki students table
                                .select('name, profile_image')
                                .eq('id', studentUser.id)
                                .maybeSingle();

                            final String studentName = studentProfile?['name'] ??
                                'Student';

                            final String? studentImage = studentProfile?['profile_image'];

                            final channelId =
                                "call_${item['invite_id']}_${DateTime.now().millisecondsSinceEpoch}";

                            // 🔴 2. 'calls' table mein actual caller_name aur caller_image save karein
                            await supabase.from('calls').insert({
                              'caller_id': studentUser.id,
                              'caller_name': studentName,        // 👈 Hardcoded 'Student' ki jagah actual name
                              'receiver_id': tutorId,
                              'channel_id': channelId,
                              'status': 'calling',
                            });

                            if (!mounted) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TutorCallScreen(
                                  channelId: channelId,
                                  receiverName: tutorName,
                                  receiverImage: tutorImage?.toString(),
                                ),
                              ),
                            );
                          } catch (e) {
                            debugPrint("Student Call Error: $e");

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Call Error: $e"),
                              ),
                            );
                          }
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: Color(0xff0f766e)),
                        onSelected: (value) {
                          if (value == 'end_contract') {
                            _endContract(item['invite_id']);
                          } else if (value == 'feedback') {
                            _showFeedbackDialog(
                              item['tutor_id'].toString(),
                              name,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'end_contract',
                            child: TextWidget(text: "End Contract", textWeight: FontWeight.bold, textColor: Color(0xff0f766e),),
                          ),
                          const PopupMenuItem<String>(
                            value: 'feedback',
                            child: TextWidget(text: "Feedback", textWeight: FontWeight.bold, textColor: Color(0xff0f766e),),
                          ),
                        ],
                      )
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

              return Stack(
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  TextWidget(text: "Tutor: ", textWeight: FontWeight.bold, textColor: Color(0xff0f766e)),
                                  TextWidget(text: tutorName, textWeight: FontWeight.w600),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: status == 'pending'
                                          ? Color(0xff0f766e).withOpacity(0.15)
                                          : Color(0xffeb5757).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: status == 'pending'
                                            ? Color(0xff0f766e).withOpacity(0.8)
                                            : Color(0xffeb5757).withOpacity(0.8),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              TextWidget(text: "Duration: ",  textWeight: FontWeight.bold, textColor: Color(0xff0f766e)),
                              TextWidget(text: duration, textWeight: FontWeight.w600),
                            ],
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(text: "Skills: ", style: TextStyle(color: Color(0xff0f766e), fontWeight: FontWeight.bold)),
                                TextSpan(text: skills.isNotEmpty ? skills.join(', ') : 'None', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(text: "Rate: ", style: TextStyle(color: Color(0xff0f766e), fontWeight: FontWeight.bold)),
                                TextSpan(text: "\$$rate / hour", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: GestureDetector(
                      onTap: () {
                        _deleteInvite(inviteId);
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Color(0xff0f766e),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],

              );
            },
          ),
        );
      },
    );
  }
}