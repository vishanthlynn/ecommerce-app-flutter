import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/shop_controllers.dart';
import 'data/api_client.dart';
import 'data/cache.dart';
import 'data/session_store.dart';
import 'services/firebase_gate.dart';
import 'services/notify.dart';
import 'ui/pages.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseGate.tryInit();
  await initNotifications();
  final session = SessionStore();
  await session.init();
  final cache = await openLocalCache();
  Get.put(session, permanent: true);
  Get.put<LocalCache>(cache, permanent: true);
  Get.put(ApiClient(session: session), permanent: true);
  Get.put(AuthController(), permanent: true);
  Get.put(CartController(), permanent: true);
  Get.put(FavoritesController(), permanent: true);
  Get.put(OrdersController(), permanent: true);
  Get.put(CatalogController(), permanent: true);
  runApp(const MercerApp());
}

class MercerApp extends StatelessWidget {
  const MercerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Mercer',
      debugShowCheckedModeBanner: false,
      theme: buildMercerTheme(),
      home: const ShellPage(),
    );
  }
}
