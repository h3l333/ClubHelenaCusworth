import 'package:firebase_messaging/firebase_messaging.dart';

class PushService {
  static final _fcm = FirebaseMessaging.instance;

  static Future<String?> init() async {
    final settings = await _fcm.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return null;
    return _fcm.getToken();
  }

  static Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;
}
