import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('[NotificationService] Permission: ${settings.authorizationStatus}');

    final token = await _messaging.getToken();
    print('[NotificationService] FCM Token: $token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('[NotificationService] Foreground message: ${message.messageId}');
      if (message.notification != null) {
        print('[NotificationService] Title: ${message.notification!.title}');
        print('[NotificationService] Body: ${message.notification!.body}');
      }
    });
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
