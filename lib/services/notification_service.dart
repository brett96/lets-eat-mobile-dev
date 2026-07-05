import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'user_service.dart';

/// Wraps Firebase Cloud Messaging: requests permission (required on iOS and
/// Android 13+), registers the device token against the signed-in user, and
/// surfaces foreground messages.
class NotificationService {
  NotificationService({FirebaseMessaging? messaging, UserService? userService})
      : _messaging = messaging ?? FirebaseMessaging.instance,
        _userService = userService ?? UserService();

  final FirebaseMessaging _messaging;
  final UserService _userService;

  /// Call once after a user signs in. Registers the FCM token and keeps it in
  /// sync on refresh. Failures are swallowed so notifications never block the
  /// app (e.g. on the iOS simulator, which lacks APNs).
  Future<void> registerForUser(String uid) async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await _messaging.getToken();
      if (token != null) {
        await _userService.saveFcmToken(uid, token);
      }
      _messaging.onTokenRefresh.listen((newToken) {
        _userService.saveFcmToken(uid, newToken);
      });
    } catch (e) {
      debugPrint('NotificationService: could not register FCM token: $e');
    }
  }

  /// Foreground messages (e.g. new group chat / vote result).
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;
}
