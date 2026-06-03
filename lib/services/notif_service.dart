import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotifService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);
  }

  static Future<void> analyserEtNotifier(double value, String moment) async {
    String title = "Glycémie normale";
    String body = "$value mg/dL ($moment)";

    if (value < 70) {
      title = "⚠️ Hypoglycémie";
      body = "Attention: $body";
    } else if (value > 180) {
      title = "⚠️ Hyperglycémie";
      body = "Attention: $body";
    }

    const androidDetails = AndroidNotificationDetails(
      'glycemie_channel',
      'Glycémie',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      title,
      body,
      details,
    );
  }
}