import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/button.dart';
import '../../utils/text.dart';
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

  String _verificationStatus = 'unverified'; // Default status
  bool _isLoadingStatus = true;

  // Profile Completion state variables
  double _profileCompletionPercentage = 0.0;
  List<String> _missingProfileFields = [];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _fetchTutorData();
  }

  // Supabase se tutor status & profile data fetch aur calculate karne ka method
  Future<void> _fetchTutorData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('tutors')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          String status = (data['verification_status'] ?? 'unverified').toString();

          // Profile completion calculation
          _calculateProfileCompletion(data);

          setState(() {
            _verificationStatus = status;
          });

          final prefs = await SharedPreferences.getInstance();

          if (status == 'verified' && mounted) {
            bool hasShownVerifiedPopup = prefs.getBool('has_shown_verified_dialog_${user.id}') ?? false;
            if (!hasShownVerifiedPopup) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                _showVerifiedDialog(context);
                await prefs.setBool('has_shown_verified_dialog_${user.id}', true);
              });
            }
          }
          else if (status == 'failed' && mounted) {
            bool hasShownFailedPopup = prefs.getBool('has_shown_failed_dialog_${user.id}') ?? false;
            if (!hasShownFailedPopup) {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                _showFailedDialog(context);
                await prefs.setBool('has_shown_failed_dialog_${user.id}', true);
              });
            }
          }
        }
      }
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

  // Calculation function
  void _calculateProfileCompletion(Map<String, dynamic> data) {
    int totalSteps = 4;
    int completedSteps = 0;
    List<String> missing = [];

    // 1. Profile Picture Check
    final profileImg = data['profile_image'] ?? data['profile_image_url'] ?? data['avatar_url'];
    if (profileImg != null && profileImg.toString().trim().isNotEmpty) {
      completedSteps++;
    } else {
      missing.add("Profile Picture");
    }

    // 2. Bio / About
    final bioText = data['bio'] ?? data['about'];
    if (bioText != null && bioText.toString().trim().isNotEmpty) {
      completedSteps++;
    } else {
      missing.add("Bio/About");
    }

    // 3. Hourly Rate
    final hourlyRate = data['hourly_rate'];
    if (hourlyRate != null && (num.tryParse(hourlyRate.toString()) ?? 0) > 0) {
      completedSteps++;
    } else {
      missing.add("Hourly Rate");
    }

    // 4. Audio/Video Sample
    final audioUrl = data['recitation_audio_url'];
    final videoUrl = data['recitation_video_url'];
    if ((audioUrl != null && audioUrl.toString().trim().isNotEmpty) ||
        (videoUrl != null && videoUrl.toString().trim().isNotEmpty)) {
      completedSteps++;
    } else {
      missing.add("Audio/Video Sample");
    }

    setState(() {
      _profileCompletionPercentage = completedSteps / totalSteps;
      _missingProfileFields = missing;
    });
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
                Center(child: Text("No Students Found!")),
                Center(child: Text("No Invitation Found!")),
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