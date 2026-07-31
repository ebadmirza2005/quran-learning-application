import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class InviteService {
  static final _supabase = Supabase.instance.client;

  static Future<void> sendInvite({
    required String tutorId,
    required String subjectName,
    String duration = "1 Hour", // 👈 Duration yahan add karein (Default 1 Hour)
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      // 1. Student Name Fetch
      final studentData = await _supabase
          .from('students')
          .select('full_name, name')
          .eq('id', currentUser.id)
          .maybeSingle();

      final String studentName =
          studentData?['full_name'] ?? studentData?['name'] ?? "A Student";

      // 2. Invites Table Me Insert (Duration Pass Kar Diya Hai)
      await _supabase.from('invites').insert({
        'student_id': currentUser.id,
        'tutor_id': tutorId,
        'subject': subjectName,
        'duration': duration, // 👈 Null error yahan se fix ho jayega
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint("✅ Invite saved in database.");

      // 3. Tutor FCM Token Fetch
      final tutorData = await _supabase
          .from('tutors')
          .select('fcm_token')
          .eq('id', tutorId)
          .maybeSingle();

      final String? tutorFcmToken = tutorData?['fcm_token'];

      // 4. Notification Dispatch
      if (tutorFcmToken != null && tutorFcmToken.isNotEmpty) {
        await NotificationService.sendPushNotification(
          recipientFcmToken: tutorFcmToken,
          title: "New Class Invite! 📚",
          body: "$studentName sent you a tuition request for $subjectName.",
          dataPayLoad: {
            'type': 'invite',
            'student_id': currentUser.id,
            'tutor_id': tutorId,
            'subject': subjectName,
            'duration': duration,
          },
        );
      } else {
        debugPrint("⚠️ Tutor FCM Token missing.");
      }
    } catch (e) {
      debugPrint("❌ Send Invite Error: $e");
    }
  }
}