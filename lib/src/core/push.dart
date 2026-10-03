// Push notifications via Firebase Cloud Messaging (Android + iOS).
// The device token is registered with P2P-backend (`/api/devices`, app "ptp"); the backend sends through
// notify("ptp", …) on a new message, a new application, or an application status change.
// ponytail: web push skipped (needs a VAPID key + service worker); in-app notifications cover web.
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api.dart';

abstract class Push {
  static bool get supported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Current FCM token (sent on logout so the backend forgets this device).
  static String? token;
  static StreamSubscription<String>? _refreshSub;

  /// Ask permission, get the token and register it. Safe to call repeatedly; never throws.
  static Future<void> register(ApiClient api) async {
    if (!supported) return;
    try {
      final perm = await FirebaseMessaging.instance.requestPermission();
      if (perm.authorizationStatus == AuthorizationStatus.denied) return;
      final t = await FirebaseMessaging.instance.getToken();
      if (t == null) return;
      await _send(api, t);
      _refreshSub ??= FirebaseMessaging.instance.onTokenRefresh.listen((t) => _send(api, t));
    } catch (e) {
      // iOS without an APNs key in Firebase, emulators without Play services, etc.
      debugPrint('Push registration skipped: $e');
    }
  }

  static Future<void> _send(ApiClient api, String t) async {
    token = t;
    await api.post('/api/devices', {'token': t, 'app': 'ptp', 'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'});
  }

  /// Screen for a tapped notification (backend data: type + ids).
  static String? routeFor(Map<String, dynamic> data) => switch (data['type']) {
        'message' when data['senderId'] != null => '/chat/${data['senderId']}',
        'application_received' => '/dashboard?tab=incoming',
        'application_status' => '/dashboard?tab=sent',
        _ => null,
      };

  /// Open the right screen when the user taps a notification (app in background or cold start).
  static Future<void> listenForTaps(void Function(String route) open) async {
    if (!supported) return;
    void handle(RemoteMessage m) {
      final r = routeFor(m.data);
      if (r != null) open(r);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(handle);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) handle(initial);
  }
}
