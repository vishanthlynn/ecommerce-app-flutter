import 'dart:io';

import 'package:mercer_server/shop_server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final handler = buildHandler(ShopStore());
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('Mercer API on http://${server.address.host}:${server.port}');
}
