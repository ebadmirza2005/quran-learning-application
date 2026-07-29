import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> setupFCMToken({
    required BuildContext context,
    required bool isTutor,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token;

      try {
        // 🟢 iOS par pehle APNS token ka check ya fallback handle karein
        if (Platform.isIOS) {
          String? apnsToken = await _fcm.getAPNSToken();

          // Agar Simulator par chal raha hai aur APNS token NULL hai toh skip karein
          if (apnsToken == null) {
            debugPrint("⚠️ APNS token is null (likely running on iOS Simulator). Skipping FCM token fetch.");
            return;
          }
        }

        token = await _fcm.getToken();
      } catch (e) {
        debugPrint("⚠️ Could not get FCM Token: $e");
      }

      if (token != null) {
        await _saveTokenToSupabase(token, isTutor: isTutor);
      }

      _fcm.onTokenRefresh.listen((newToken) async {
        await _saveTokenToSupabase(newToken, isTutor: isTutor);
      });
    }

    // Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${message.notification?.title}: ${message.notification?.body}",
            ),
            backgroundColor: const Color(0xff0f766e),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  static Future<void> _saveTokenToSupabase(
      String token, {
        required bool isTutor,
      }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final tableName = isTutor ? 'tutors' : 'students';

    try {
      await _supabase.from(tableName).update({
        'fcm_token': token,
      }).eq('id', user.id);

      debugPrint("✅ FCM Token saved in $tableName table successfully!");
    } catch (e) {
      debugPrint("❌ Error saving FCM token: $e");
    }
  }
}