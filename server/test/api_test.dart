import 'dart:convert';

import 'package:mercer_server/shop_server.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late ShopStore store;
  late Handler handler;

  setUp(() {
    store = ShopStore();
    handler = buildHandler(store);
  });

  test('health and product search pages', () async {
    final health = await handler(_req('GET', '/health'));
    expect(health.statusCode, 200);

    final page = await _jsonBody(await handler(_req('GET', '/v1/products?limit=8&page=1')));
    expect((page['items'] as List).length, 8);
    expect(page['hasMore'], isTrue);

    final honey = await _jsonBody(await handler(_req('GET', '/v1/products?q=honey')));
    expect((honey['items'] as List).single['name'], 'Honey');
  });

  test('auth, cart, favorite, address, payment, and order', () async {
    final login = await _jsonBody(
      await handler(_req('POST', '/v1/auth/login', body: {'email': 'ada@mercer.shop', 'password': 'mercer123'})),
    );
    final token = login['token'] as String;

    final denied = await handler(_req('GET', '/v1/cart'));
    expect(denied.statusCode, 401);

    final synced = await handler(_req(
      'POST',
      '/v1/cart/sync',
      body: {
        'items': [
          {'productId': 'mk-01', 'quantity': 1},
          {'productId': 'mk-08', 'quantity': 2},
        ],
      },
      token: token,
    ));
    expect(synced.statusCode, 200);

    final fav = await handler(_req('POST', '/v1/favorites/mk-11', body: {}, token: token));
    expect(fav.statusCode, 200);
    final favs = await _jsonBody(await handler(_req('GET', '/v1/favorites', token: token)));
    expect((favs['items'] as List).single['id'], 'mk-11');

    final address = await _jsonBody(await handler(_req(
      'POST',
      '/v1/addresses',
      body: {
        'fullName': 'Ada Mercer',
        'line1': '12 Sabine St',
        'city': 'Austin',
        'region': 'TX',
        'postalCode': '78701',
      },
      token: token,
    )));

    final cart = await _jsonBody(await handler(_req('GET', '/v1/cart', token: token)));
    final subtotal = (cart['items'] as List).fold<double>(0, (sum, line) => sum + (line['lineTotal'] as num));
    final shipping = subtotal >= 60 ? 0 : 5;
    final due = roundMoney(subtotal + shipping + roundMoney(subtotal * 0.0825));

    final declined = await handler(_req(
      'POST',
      '/v1/payments/test',
      body: {
        'method': 'stripe',
        'cardNumber': '4000000000000002',
        'amount': due,
      },
      token: token,
    ));
    expect(declined.statusCode, 402);

    final paid = await _jsonBody(await handler(_req(
      'POST',
      '/v1/payments/test',
      body: {
        'method': 'stripe',
        'cardNumber': '4242424242424242',
        'amount': due,
      },
      token: token,
    )));

    final order = await handler(_req(
      'POST',
      '/v1/orders',
      body: {
        'addressId': address['id'],
        'paymentReference': paid['reference'],
      },
      token: token,
    ));
    expect(order.statusCode, 201);

    final orders = await _jsonBody(await handler(_req('GET', '/v1/orders', token: token)));
    expect((orders['items'] as List), hasLength(1));
    final emptyCart = await _jsonBody(await handler(_req('GET', '/v1/cart', token: token)));
    expect(emptyCart['items'], isEmpty);
  });

  test('paypal sandbox and profile update', () async {
    final login = await _jsonBody(
      await handler(_req('POST', '/v1/auth/login', body: {'email': 'ada@mercer.shop', 'password': 'mercer123'})),
    );
    final token = login['token'] as String;
    final bad = await handler(_req(
      'POST',
      '/v1/payments/test',
      body: {
        'method': 'paypal',
        'email': 'buyer@mercer.test',
        'password': 'nope',
        'amount': 10,
      },
      token: token,
    ));
    expect(bad.statusCode, 400);

    final profile = await _jsonBody(await handler(_req(
      'PATCH',
      '/v1/profile',
      body: {
        'name': 'Ada M.',
        'phone': '512-555-0199',
      },
      token: token,
    )));
    expect(profile['name'], 'Ada M.');
    expect(profile['phone'], '512-555-0199');
  });
}

Request _req(
  String method,
  String path, {
  Map<String, dynamic>? body,
  String? token,
}) {
  return Request(
    method,
    Uri.parse('http://localhost$path'),
    body: body == null ? null : jsonEncode(body),
    headers: {
      if (body != null) 'content-type': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
    },
  );
}

Future<Map<String, dynamic>> _jsonBody(Response response) async {
  final raw = await response.readAsString();
  return jsonDecode(raw) as Map<String, dynamic>;
}
