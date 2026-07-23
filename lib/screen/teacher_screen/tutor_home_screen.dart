import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/button.dart';
import '../../utils/text.dart';
import 'tutor_call_screen.dart';
import 'tutor_chat_screen.dart';
import 'tutor_edit_info.dart';
import 'tutor_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController tabController;
  final supabase = Supabase.instance.client;
  RealtimeChannel? _callChannel;


  String _verificationStatus = 'unverified';
  bool _isLoadingStatus = true;

  double _profileCompletionPercentage = 0.0;
  List<String> _missingProfileFields = [];


  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _fetchTutorData();
    _listenForIncomingCalls();
  }

  void _listenForIncomingCalls() {
    final tutorUser = Supabase.instance.client.auth.currentUser;
    if (tutorUser == null) return;

    _callChannel = Supabase.instance.client
        .channel('incoming_calls_${tutorUser.id}')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert, // Nayi call aane par
      schema: 'public',
      table: 'calls',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'receiver_id',
        value: tutorUser.id,
      ),
      callback: (payload) {
        final newRecord = payload.newRecord;

        // Check karein ke status calling hai ya nahi
        if (newRecord['status'] == 'calling' && mounted) {
          final channelId = newRecord['channel_id']?.toString() ?? '';
          final callerName = newRecord['caller_name']?.toString() ?? 'Student';
          final callId = newRecord['id']?.toString() ?? '';

          _showIncomingCallDialog(
            context: context,
            channelId: channelId,
            callerName: callerName,
            callId: callId,
          );
        }
      },
    )
        .subscribe();
  }

  Future<void> _fetchTutorData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoadingStatus = false;
          });
        }
        return;
      }

      final data = await supabase
          .from('tutors')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        String status = (data['verification_status'] ?? 'unverified').toString();

        _calculateProfileCompletion(data);

        setState(() {
          _verificationStatus = status;
        });

        final prefs = await SharedPreferences.getInstance();

        if (status == 'verified' && mounted) {
          bool hasShownVerifiedPopup = prefs.getBool('has_shown_verified_dialog_${user.id}') ?? false;
          if (!hasShownVerifiedPopup) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                _showVerifiedDialog(context);
                await prefs.setBool('has_shown_verified_dialog_${user.id}', true);
              }
            });
          }
        } else if (status == 'failed' && mounted) {
          bool hasShownFailedPopup = prefs.getBool('has_shown_failed_dialog_${user.id}') ?? false;
          if (!hasShownFailedPopup) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                _showFailedDialog(context);
                await prefs.setBool('has_shown_failed_dialog_${user.id}', true);
              }
            });
          }
        }
      }
    } on AuthException catch (e) {
      debugPrint("Supabase Auth Error: ${e.message}");
    } catch (e) {
      debugPrint("Error fetching tutor data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    }
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
      builder: (dialogContext) { // 👈 Renamed to dialogContext to avoid shadow conflict
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
                await Supabase.instance.client
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
                // 1. Dialog ko pehle close karein safely
                Navigator.of(dialogContext).pop();

                // 2. Database mein call status update karein
                try {
                  await Supabase.instance.client
                      .from('calls')
                      .update({'status': 'accepted'})
                      .eq('id', callId);
                } catch (e) {
                  debugPrint("Error updating call status: $e");
                }

                // 3. Main context use karke Call Screen par Navigate karein
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

  void _calculateProfileCompletion(Map<String, dynamic> data) {
    int totalSteps = 4;
    int completedSteps = 0;
    List<String> missing = [];

    final profileImg = data['profile_image'] ?? data['profile_image_url'] ?? data['avatar_url'];
    if (profileImg != null && profileImg.toString().trim().isNotEmpty) {
      completedSteps++;
    } else {
      missing.add("Profile Picture");
    }

    final bioText = data['bio'] ?? data['about'];
    if (bioText != null && bioText.toString().trim().isNotEmpty) {
      completedSteps++;
    } else {
      missing.add("Bio/About");
    }

    final hourlyRate = data['hourly_rate'];
    if (hourlyRate != null && (num.tryParse(hourlyRate.toString()) ?? 0) > 0) {
      completedSteps++;
    } else {
      missing.add("Hourly Rate");
    }

    final audioUrl = data['recitation_audio_url'];
    final videoUrl = data['recitation_video_url'];
    if ((audioUrl != null && audioUrl.toString().trim().isNotEmpty) ||
        (videoUrl != null && videoUrl.toString().trim().isNotEmpty)) {
      completedSteps++;
    } else {
      missing.add("Audio/Video Sample");
    }

    if (mounted) {
      setState(() {
        _profileCompletionPercentage = completedSteps / totalSteps;
        _missingProfileFields = missing;
      });
    }
  }

  void _showVerifiedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xff0f766e).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xff0f766e),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Profile Verified! 🎉",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff0f766e),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Congratulations! Your profile is verified. Students can now view your profile and send teaching requests.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff0f766e),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Got It",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFailedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_rounded,
                    color: Colors.redAccent,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Test Not Passed ❌",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Unfortunately, you did not meet the passing criteria. Your profile is currently hidden from students. You can retake the test.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Try Again",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    if (_callChannel != null) {
      Supabase.instance.client.removeChannel(_callChannel!); // Clean up
    }
    tabController.dispose();
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
        bottom: TabBar(
          controller: tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          tabs: const [
            Tab(text: "My Students"),
            Tab(text: "Invites"),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!_isLoadingStatus) ...[
            if (_verificationStatus == 'verified' && _profileCompletionPercentage < 1.0)
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TutorEditInfo()),
                    );
                    _fetchTutorData();
                  },
                  child: Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: _buildProfileCompletionCard(),
                  ),
                ),
              ),

            if (_verificationStatus != 'verified')
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 12.0),
                child: Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: _buildVerificationCard(),
                ),
              ),
          ],
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: const [
                StudentsTabWidget(),
                InvitesTabWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletionCard() {
    int percentage = (_profileCompletionPercentage * 100).toInt();

    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Profile Completion",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff0f766e)),
              ),
              Text(
                "$percentage%",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff0f766e)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _profileCompletionPercentage,
            backgroundColor: Colors.grey.shade300,
            color: const Color(0xff0f766e),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    if (_verificationStatus == 'pending') {
      return Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            TextWidget(
              text: "⏳ Your screening test has been submitted and is currently under review. Results will be updated within 2 hours.",
            ),
            const SizedBox(height: 14),
            ElevatedButtonWidget(
              buttonText: "Under Review",
              buttonColor: Colors.grey,
              textColor: Colors.white,
              onTap: null,
            ),
          ],
        ),
      );
    } else if (_verificationStatus == 'failed') {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(14.0),
            child: TextWidget(
              text: "❌ You did not pass the screening test. Your profile is not visible to students. You can retake the test now.",
            ),
          ),
          ElevatedButtonWidget(
            buttonText: "Retake Test",
            buttonColor: Colors.redAccent,
            textColor: Colors.white,
            onTap: () async {
              final user = supabase.auth.currentUser;
              if (user != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('has_shown_failed_dialog_${user.id}');
              }
              if (mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TutorTestScreen()),
                );
                _fetchTutorData();
              }
            },
          ),
          const SizedBox(height: 14),
        ],
      );
    } else {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: TextWidget(
              text: "🔒 A minimum score of 50% (8/15 correct answers) is required to verify your profile. If you fail, your profile will not be visible to students, but you can retake the test for free after a 1-hour cooldown.",
            ),
          ),
          ElevatedButtonWidget(
            buttonText: "Start Test",
            buttonColor: const Color(0xff0f766e),
            textColor: Colors.white,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TutorTestScreen()),
              );
              _fetchTutorData();
            },
          ),
          const SizedBox(height: 14),
        ],
      );
    }
  }
}

class InvitesTabWidget extends StatefulWidget {
  const InvitesTabWidget({super.key});

  @override
  State<InvitesTabWidget> createState() => _InvitesTabWidgetState();
}

class _InvitesTabWidgetState extends State<InvitesTabWidget> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _invitesFuture;
  RealtimeChannel? _inviteChannel;

  @override
  void initState() {
    super.initState();
    _loadInvites();
    _subscribeToInviteChanges();
  }

  @override
  void dispose() {
    if (_inviteChannel != null) {
      supabase.removeChannel(_inviteChannel!);
    }
    super.dispose();
  }

  void _subscribeToInviteChanges() {
    final tutorId = supabase.auth.currentUser?.id;
    if (tutorId == null) return;

    _inviteChannel = supabase
        .channel('invites_tab_$tutorId')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'invites',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'tutor_id',
        value: tutorId,
      ),
      callback: (payload) {
        if (mounted) {
          setState(() {
            _loadInvites();
          });
        }
      },
    )
        .subscribe();
  }

  void _loadInvites() {
    final tutorId = supabase.auth.currentUser?.id;
    if (tutorId != null) {
      _invitesFuture = supabase
          .from('invites')
          .select()
          .eq('tutor_id', tutorId)
          .neq('status', 'accepted')
          .order('created_at', ascending: false);
    } else {
      _invitesFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tutorId = supabase.auth.currentUser?.id;

    if (tutorId == null) {
      return const Center(child: Text("User not logged in."));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _invitesFuture,
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
            ),
          );
        }

        final invites = snapshot.data ?? [];

        if (invites.isEmpty) {
          return const Center(
            child: Text(
              "No Invitation Found!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (mounted) {
              setState(() {
                _loadInvites();
              });
            }
          },
          color: const Color(0xff0f766e),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final invite = invites[index];
              final List<dynamic> skills = invite['selected_skills'] ?? [];
              final String duration = invite['duration']?.toString() ?? 'N/A';
              final String status = invite['status']?.toString() ?? 'pending';
              final double rate = (invite['hourly_rate'] as num? ?? 0.0).toDouble();

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
                        children: [
                          Text(
                            "Duration: $duration",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xff0f766e),
                            ),
                          ),
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
                        ],
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Skills: ",
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: skills.isNotEmpty ? skills.join(', ') : 'None',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Rate: ",
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: "\$$rate / hour",
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      if (status == 'pending') ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  await supabase
                                      .from('invites')
                                      .update({'status': 'rejected'})
                                      .eq('id', invite['id']);
                                  if (mounted) {
                                    setState(() {
                                      _loadInvites();
                                    });
                                  }
                                } catch (e) {
                                  debugPrint("Reject error: $e");
                                }
                              },
                              child: const Text("Reject", style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff0f766e),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                try {
                                  await supabase
                                      .from('invites')
                                      .update({'status': 'accepted'})
                                      .eq('id', invite['id']);
                                  if (mounted) {
                                    setState(() {
                                      _loadInvites();
                                    });
                                  }
                                } catch (e) {
                                  debugPrint("Accept error: $e");
                                }
                              },
                              child: const Text("Accept", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
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

class StudentsTabWidget extends StatefulWidget {
  const StudentsTabWidget({super.key});

  @override
  State<StudentsTabWidget> createState() => _StudentsTabWidgetState();
}

class _StudentsTabWidgetState extends State<StudentsTabWidget> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _studentsFuture;
  RealtimeChannel? _inviteChannel;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _subscribeToInviteChanges();
  }

  @override
  void dispose() {
    if (_inviteChannel != null) {
      supabase.removeChannel(_inviteChannel!);
    }
    super.dispose();
  }

  void _subscribeToInviteChanges() {
    final tutorId = supabase.auth.currentUser?.id;
    if (tutorId == null) return;

    _inviteChannel = supabase
        .channel('my_students_tab_$tutorId')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'invites',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'tutor_id',
        value: tutorId,
      ),
      callback: (payload) {
        if (mounted) {
          setState(() {
            _loadStudents();
          });
        }
      },
    )
        .subscribe();
  }

  void _loadStudents() {
    _studentsFuture = _fetchAcceptedInvitesWithStudentInfo();
  }

  Future<List<Map<String, dynamic>>> _fetchAcceptedInvitesWithStudentInfo() async {
    final tutorId = supabase.auth.currentUser?.id;
    if (tutorId == null) return [];

    final acceptedInvitesRaw = await supabase
        .from('invites')
        .select()
        .eq('tutor_id', tutorId)
        .eq('status', 'accepted')
        .order('created_at', ascending: false);

    final List<Map<String, dynamic>> acceptedInvites =
    List<Map<String, dynamic>>.from(acceptedInvitesRaw);

    if (acceptedInvites.isEmpty) return acceptedInvites;

    final studentIds = acceptedInvites
        .map((invite) => invite['student_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    if (studentIds.isNotEmpty) {
      try {
        final studentsDataRaw = await supabase
            .from('students')
            .select()
            .inFilter('id', studentIds);

        final studentsData = List<Map<String, dynamic>>.from(studentsDataRaw);
        final Map<String, Map<String, dynamic>> studentsById = {
          for (final s in studentsData) s['id'].toString(): s,
        };

        for (final invite in acceptedInvites) {
          final sid = invite['student_id']?.toString();
          if (sid != null && studentsById.containsKey(sid)) {
            invite['student_info'] = studentsById[sid];
          }
        }
      } catch (e) {
        debugPrint("Could not fetch student profiles: $e");
      }
    }

    return acceptedInvites;
  }

  @override
  Widget build(BuildContext context) {
    final tutorId = supabase.auth.currentUser?.id;

    if (tutorId == null) {
      return const Center(child: Text("User not logged in."));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xff0f766e)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading students: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final students = snapshot.data ?? [];

        if (students.isEmpty) {
          return const Center(
            child: Text(
              "No Students Found!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (mounted) {
              setState(() {
                _loadStudents();
              });
            }
          },
          color: const Color(0xff0f766e),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final invite = students[index];
              final studentInfo = invite['student_info'] as Map<String, dynamic>?;
              final String studentId = invite['student_id']?.toString() ?? '';
              final String studentName =
              (studentInfo?['name'] ?? studentInfo?['full_name'] ?? 'Student').toString();
              final String? studentImage =
              (studentInfo?['profile_image'] ?? studentInfo?['avatar_url'])?.toString();
              final List<dynamic> skills = invite['selected_skills'] ?? [];
              final String duration = invite['duration']?.toString() ?? 'N/A';
              final String rate = (invite['hourly_rate'] as num? ?? 0.0).toStringAsFixed(1);

              return Card(
                color: Colors.white,
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xff0f766e).withOpacity(0.1),
                        backgroundImage: (studentImage != null && studentImage.isNotEmpty)
                            ? NetworkImage(studentImage)
                            : null,
                        child: (studentImage == null || studentImage.isEmpty)
                            ? const Icon(Icons.person, color: Color(0xff0f766e))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                TextWidget(text: "Learn"),
                                TextWidget(text: " : "),
                                TextWidget(text: skills.isNotEmpty ? skills.join(', ') : 'None'),
                              ],
                            ),
                            Row(
                              children: [
                                TextWidget(text: "Duration"),
                                TextWidget(text: " : "),
                                TextWidget(text: duration),
                              ],
                            ),
                            Row(
                              children: [
                                TextWidget(text: "Rate"),
                                TextWidget(text: " : "),
                                TextWidget(text: rate),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.message,
                          color: Color(0xff0f766e),
                        ),
                        onPressed: () {
                          if (studentId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Student ID is missing!")),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TutorChatScreen(
                                receiverId: studentId,
                                receiverName: studentName,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.phone,
                          color: Color(0xff0f766e),
                        ),
                        onPressed: () async {
                          if (studentId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Invalid Student ID")),
                            );
                            return;
                          }

                          try {
                            final tutorUser = supabase.auth.currentUser;

                            if (tutorUser == null) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Tutor not logged in")),
                              );
                              return;
                            }

                            // Safe fallback if invite['id'] is null
                            final inviteId = invite['id']?.toString() ?? 'no_invite';
                            final channelId = "call_${inviteId}_${DateTime.now().millisecondsSinceEpoch}";

                            // Insert call into Supabase
                            await supabase.from('calls').insert({
                              'caller_id': tutorUser.id,
                              'caller_name': "Tutor",
                              'receiver_id': studentId,
                              'channel_id': channelId,
                              'status': 'calling',
                            });

                            // Check mounted before using context after async gap
                            if (!context.mounted) return;

                            // Navigate to Call Screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TutorCallScreen(
                                  channelId: channelId,
                                  receiverName: studentName,
                                ),
                              ),
                            );
                          } catch (e) {
                            debugPrint("CALL ERROR: $e");

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Call Error: ${e.toString()}"),
                                backgroundColor: Colors.redAccent,
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