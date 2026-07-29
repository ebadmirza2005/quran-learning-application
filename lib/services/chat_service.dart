import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  static final _supabase = Supabase.instance.client;

  static Future<void> sendMessage({
    required String receiverId,
    required String messageText,
    required String senderName,
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

      final targetTable = isReceiverTutor ? 'tutors' : 'students';
      final receiverData = await _supabase.from(targetTable).select('fcm_token').eq('id', receiverId).maybeSingle();
      final String? fcmToken = receiverData?['fcm_token'];

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _supabase.functions.invoke('send-push-notification', body: {
          'to': fcmToken,
          'title': 'New Message from $senderName',
          'body': messageText,
          'data': {
            'type': 'chat',
            'sender_id': currentUser.id,
          }
        });
        debugPrint("Push notification sent to $fcmToken");
      }
    }catch (e) {
      debugPrint("Error sending message: $e");
    }
  }
}