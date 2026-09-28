import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _plugin = FlutterLocalNotificationsPlugin();
var _ready = false;

Future<void> initNotifications() async {
  try {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  } catch (_) {
    _ready = false;
  }
}

Future<void> showOrderNotification(String orderId) async {
  if (!_ready) return;
  try {
    await _plugin.show(
      id: orderId.hashCode.abs() % 100000,
      title: 'Order placed',
      body: 'Mercer order $orderId is confirmed.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'orders',
          'Orders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  } catch (_) {}
}
