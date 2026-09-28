import 'notify_stub.dart'
    if (dart.library.io) 'notify_io.dart'
    if (dart.library.html) 'notify_web.dart'
    if (dart.library.js_interop) 'notify_web.dart' as platform;

Future<void> initNotifications() => platform.initNotifications();

Future<void> showOrderNotification(String orderId) => platform.showOrderNotification(orderId);
