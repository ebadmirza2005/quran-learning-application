import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  static final _supabase = Supabase.instance.client;

  static Future<void> sendMessage({
    required String receiverId,
    required String messageText,
    required bool isReceiverTutor,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      await _supabase.from('messages').insert({
        'sender_id': currentUser.id,
        'receiver_id': receiverId,
        'message_text': messageText,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint("✅ Message saved in Supabase database.");

      String actualSenderName = "Someone";

      final studentSender = await _supabase
          .from('students')
          .select('full_name, name')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (studentSender != null) {
        actualSenderName = studentSender['full_name'] ?? studentSender['name'] ?? "Someone";
      } else {
        final tutorSender = await _supabase
            .from('tutors')
            .select('full_name, name')
            .eq('id', currentUser.id)
            .maybeSingle();
        if (tutorSender != null) {
          actualSenderName = tutorSender['full_name'] ?? tutorSender['name'] ?? "Someone";
        }
      }

      final targetTable = isReceiverTutor ? 'tutors' : 'students';

      final receiverData = await _supabase

          .from(targetTable)
          .select('fcm_token')
          .eq('id', receiverId)
          .maybeSingle();

      final String? fcmToken = receiverData?['fcm_token'];

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _supabase.functions.invoke('send-push-notification', body: {
          'to': fcmToken,
          'title': "New Message from $actualSenderName",
          'body': messageText,
          'data': {
            'type': 'chat',
            'sender_id': currentUser.id,
          }
        });
        debugPrint("🚀 Push Notification dispatched to $actualSenderName!");
      } else {
        debugPrint("⚠️ Receiver FCM Token not found.");
      }
    } catch (e) {
      debugPrint("❌ Chat Send Error: $e");
    }
  }
}