import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class InviteService {
  static final _supabase = Supabase.instance.client;

  static Future<void> sendInviteNotification({
    required String tutorId,
    required String subjectName,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      // 1. Student Name Fetch Karein
      final studentData = await _supabase
          .from('students')
          .select('full_name, name')
          .eq('id', currentUser.id)
          .maybeSingle();

      final String studentName =
          studentData?['full_name'] ?? studentData?['name'] ?? "A Student";

      // 2. Tutor (Receiver) ka FCM Token Fetch Karein
      final tutorData = await _supabase
          .from('tutors')
          .select('fcm_token')
          .eq('id', tutorId)
          .maybeSingle();

      final String? tutorFcmToken = tutorData?['fcm_token'];

      // 3. Simple Push Notification Send Karein (No duplicate DB insert!)
      if (tutorFcmToken != null && tutorFcmToken.isNotEmpty) {
        await NotificationService.sendPushNotification(
          recipientFcmToken: tutorFcmToken,
          title: "New Class Invite! 📚",
          body: "$studentName sent you a tuition request for $subjectName.",
          dataPayLoad: {
            'type': 'invite',
            'student_id': currentUser.id,
            'subject_name': subjectName,
          }
        );
        debugPrint("🚀 Invite Push Notification sent to Tutor!");
      } else {
        debugPrint("⚠️ Tutor FCM Token missing or tutor is offline.");
      }
    } catch (e) {
      debugPrint("❌ Notification Send Error: $e");
    }
  }
}