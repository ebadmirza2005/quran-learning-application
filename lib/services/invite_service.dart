import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service.dart';

class InviteService {
  static final _supabase = Supabase.instance.client;

  static Future<void> sendInvite({
    required String tutorId,
    required String subjectName,
}) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      final studentData = await _supabase.from('students').select('name').eq('id', currentUser.id).maybeSingle();
      final String studentName = studentData?['name'] ?? "A Student";

      await _supabase.from('invites').insert({
        'student_id': currentUser.id,
        'tutor_id': tutorId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Invite Saved in database');

      final tutorData = await _supabase.from('tutors').select('fcm_token').eq('id', tutorId).maybeSingle();
      final String? tutorFcmToken = tutorData?['fcm_token'];

      if (tutorFcmToken != null && tutorFcmToken.isNotEmpty) {
        await NotificationService.sendPushNotification(
            recipientFcmToken: tutorFcmToken,
            title: "New Class Invite",
            body: "$studentName sent you a tuition request for $subjectName",
            dataPayLoad: {
              'type': 'invite',
              'student_id': currentUser.id,
              'subject': subjectName
            }
          );
      }
    }catch (e) {
      debugPrint("❌ Error sending invite: $e");
    }
   }
}