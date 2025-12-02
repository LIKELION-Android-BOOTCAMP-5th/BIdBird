import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseManager {
  static final FirebaseManager _shared = FirebaseManager();
  static FirebaseManager get shared => _shared;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  FirebaseMessaging get fcm => _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<String?> getFcmToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken(
      vapidKey:
          "BBMVGr2Cf0iITb26AyO-7tzN7HmpHjJQpoYIX-DSvlHvL9b40mV9zkPtiFi1fzs7upnZO-4CErbhLI4bRO6TfAA",
    );
    return fcmToken;
  }
}
