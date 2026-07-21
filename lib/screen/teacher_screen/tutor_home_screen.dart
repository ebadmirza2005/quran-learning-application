import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/button.dart';
import '../../utils/text.dart';
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

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    _fetchVerificationStatus();
  }

  // Supabase se status fetch karne ka method
  Future<void> _fetchVerificationStatus() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('tutors')
            .select('verification_status')
            .eq('id', user.id)
            .maybeSingle();

        if (data != null && data['verification_status'] != null) {
          String status = data['verification_status'].toString();

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
      debugPrint("Error fetching status: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
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
          if (!_isLoadingStatus && _verificationStatus != 'verified')
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: _buildVerificationCard(),
              ),
            ),
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

  Widget _buildVerificationCard() {
    if (_verificationStatus == 'pending') {
      return Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            TextWidget(
              text: "⏳ Your screening test has been submitted and is currently under review. Results will be updated within 12 hours.",
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
              // Retake karne par status reset hoga
              final user = supabase.auth.currentUser;
              if (user != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('has_shown_failed_dialog_${user.id}');
              }
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TutorTestScreen()),
              );
              _fetchVerificationStatus();
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
              _fetchVerificationStatus();
            },
          ),
          const SizedBox(height: 14),
        ],
      );
    }
  }
}