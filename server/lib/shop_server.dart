import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

String hashPassword(String password) {
  return sha256.convert(utf8.encode('mercer::$password')).toString();
}

double roundMoney(double value) => (value * 100).roundToDouble() / 100;

class Product {
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.reviewCount,
    required this.description,
    required this.hue,
    required this.stock,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final double rating;
  final int reviewCount;
  final String description;
  final int hue;
  final int stock;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'rating': rating,
        'reviewCount': reviewCount,
        'description': description,
        'hue': hue,
        'stock': stock,
      };
}

class CartItem {
  CartItem({required this.productId, required this.quantity});

  final String productId;
  int quantity;

  Map<String, dynamic> toJson(Product product) => {
        'productId': product.id,
        'name': product.name,
        'category': product.category,
        'unitPrice': product.price,
        'hue': product.hue,
        'quantity': quantity,
        'lineTotal': roundMoney(product.price * quantity),
      };
}

class Address {
  Address({
    required this.id,
    required this.fullName,
    required this.line1,
    required this.city,
    required this.region,
    required this.postalCode,
  });

  final String id;
  final String fullName;
  final String line1;
  final String city;
  final String region;
  final String postalCode;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'line1': line1,
        'city': city,
        'region': region,
        'postalCode': postalCode,
      };
}

class ShopUser {
  ShopUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.phone = '',
  });

  final String id;
  String name;
  final String email;
  final String passwordHash;
  String phone;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
      };
}

class ShopOrder {
  ShopOrder({
    required this.id,
    required this.createdAt,
    required this.lines,
    required this.total,
    required this.address,
    required this.paymentMethod,
    required this.paymentReference,
  });

  final String id;
  final String createdAt;
  final List<Map<String, dynamic>> lines;
  final double total;
  final Map<String, dynamic> address;
  final String paymentMethod;
  final String paymentReference;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt,
        'lines': lines,
        'total': total,
        'address': address,
        'paymentMethod': paymentMethod,
        'paymentReference': paymentReference,
      };
}

class StoreLocation {
  const StoreLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class ShopStore {
  ShopStore() {
    const password = 'mercer123';
    users['ada@mercer.shop'] = ShopUser(
      id: 'user-ada',
      name: 'Ada Mercer',
      email: 'ada@mercer.shop',
      passwordHash: hashPassword(password),
      phone: '512-555-0148',
    );
  }

  final products = seedProducts();
  final users = <String, ShopUser>{};
  final tokens = <String, String>{};
  final carts = <String, List<CartItem>>{};
  final favorites = <String, Set<String>>{};
  final addresses = <String, List<Address>>{};
  final orders = <String, List<ShopOrder>>{};
  final payments = <String, Map<String, dynamic>>{};
  int _seq = 100;

  String nextId(String prefix) => '$prefix-${_seq++}';

  ShopUser? userFor(Request request) {
    final header = request.headers['authorization'];
    if (header == null || !header.toLowerCase().startsWith('bearer ')) return null;
    final token = header.substring(7).trim();
    final email = tokens[token];
    if (email == null) return null;
    return users[email];
  }
}

Handler buildHandler(ShopStore store) {
  final router = Router()
    ..get('/health', (Request request) => _json({'ok': true}))
    ..post('/v1/auth/register', (Request request) => _register(request, store))
    ..post('/v1/auth/login', (Request request) => _login(request, store))
    ..get('/v1/products', (Request request) => _products(request, store))
    ..get('/v1/products/<id>', (Request request, String id) => _product(store, id))
    ..get('/v1/stores', (Request request) => _json({'items': storeLocations.map((s) => s.toJson()).toList()}))
    ..get('/v1/profile', (Request request) => _profile(request, store))
    ..patch('/v1/profile', (Request request) => _updateProfile(request, store))
    ..get('/v1/cart', (Request request) => _cart(request, store))
    ..post('/v1/cart/sync', (Request request) => _syncCart(request, store))
    ..get('/v1/favorites', (Request request) => _favorites(request, store))
    ..post('/v1/favorites/<id>', (Request request, String id) => _addFavorite(request, store, id))
    ..delete('/v1/favorites/<id>', (Request request, String id) => _removeFavorite(request, store, id))
    ..get('/v1/addresses', (Request request) => _listAddresses(request, store))
    ..post('/v1/addresses', (Request request) => _addAddress(request, store))
    ..delete('/v1/addresses/<id>', (Request request, String id) => _deleteAddress(request, store, id))
    ..post('/v1/payments/test', (Request request) => _pay(request, store))
    ..get('/v1/orders', (Request request) => _orders(request, store))
    ..post('/v1/orders', (Request request) => _placeOrder(request, store));

  return (Request request) async {
    if (request.method == 'OPTIONS') {
      return Response.ok('', headers: _cors);
    }
    try {
      final response = await router(request);
      return response.change(headers: {...response.headers, ..._cors});
    } catch (error) {
      return _json({'error': 'Server error', 'detail': '$error'}, status: 500);
    }
  };
}

const _cors = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET,POST,PATCH,DELETE,OPTIONS',
  'access-control-allow-headers': 'origin,content-type,authorization',
};

Response _json(Object body, {int status = 200}) {
  return Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json', ..._cors},
  );
}

Future<Map<String, dynamic>> _body(Request request) async {
  final raw = await request.readAsString();
  if (raw.trim().isEmpty) return {};
  final decoded = jsonDecode(raw);
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const FormatException('Expected a JSON object');
}

Response _unauthorized() => _json({'error': 'Sign in required.'}, status: 401);

Future<Response> _register(Request request, ShopStore store) async {
  final body = await _body(request);
  final name = (body['name'] ?? '').toString().trim();
  final email = (body['email'] ?? '').toString().trim().toLowerCase();
  final password = (body['password'] ?? '').toString();
  if (name.length < 2) return _json({'error': 'Add your name.'}, status: 400);
  if (!email.contains('@') || !email.contains('.')) {
    return _json({'error': 'Enter a valid email.'}, status: 400);
  }
  if (password.length < 6) {
    return _json({'error': 'Use at least 6 characters.'}, status: 400);
  }
  if (store.users.containsKey(email)) {
    return _json({'error': 'An account with that email already exists.'}, status: 409);
  }
  final user = ShopUser(
    id: store.nextId('user'),
    name: name,
    email: email,
    passwordHash: hashPassword(password),
  );
  store.users[email] = user;
  final token = store.nextId('token');
  store.tokens[token] = email;
  return _json({'token': token, 'user': user.toJson()}, status: 201);
}

Future<Response> _login(Request request, ShopStore store) async {
  final body = await _body(request);
  final email = (body['email'] ?? '').toString().trim().toLowerCase();
  final password = (body['password'] ?? '').toString();
  final user = store.users[email];
  if (user == null || user.passwordHash != hashPassword(password)) {
    return _json({'error': 'Those credentials do not match.'}, status: 401);
  }
  final token = store.nextId('token');
  store.tokens[token] = email;
  return _json({'token': token, 'user': user.toJson()});
}

Response _products(Request request, ShopStore store) {
  final params = request.url.queryParameters;
  final text = (params['q'] ?? '').trim().toLowerCase();
  final category = params['category'];
  final page = int.tryParse(params['page'] ?? '1') ?? 1;
  final limit = int.tryParse(params['limit'] ?? '8') ?? 8;
  final filtered = store.products.where((product) {
    if (category != null && category.isNotEmpty && product.category != category) {
      return false;
    }
    if (text.isEmpty) return true;
    final haystack = '${product.name} ${product.category} ${product.description}'.toLowerCase();
    return haystack.contains(text);
  }).toList();
  final start = (page <= 1 ? 0 : (page - 1) * limit);
  if (start >= filtered.length) {
    return _json({'items': <Object>[], 'page': page, 'hasMore': false, 'total': filtered.length});
  }
  final end = start + limit > filtered.length ? filtered.length : start + limit;
  return _json({
    'items': filtered.sublist(start, end).map((product) => product.toJson()).toList(),
    'page': page,
    'hasMore': end < filtered.length,
    'total': filtered.length,
  });
}

Response _product(ShopStore store, String id) {
  for (final product in store.products) {
    if (product.id == id) return _json(product.toJson());
  }
  return _json({'error': 'Product not found.'}, status: 404);
}

Response _profile(Request request, ShopStore store) {
  final user = store.userFor(request);
  if (user == null) return _unauthorized();
  return _json(user.toJson());
}

Future<Response> _updateProfile(Request request, ShopStore store) async {
  final user = store.userFor(request);
  if (user == null) return _unauthorized();
  final body = await _body(request);
  final name = (body['name'] ?? '').toString().trim();
  if (name.length >= 2) user.name = name;
  if (body.containsKey('phone')) user.phone = (body['phone'] ?? '').toString();
  return _json(user.toJson());
}

Response _cart(Request request, ShopStore store) {
  final user = store.userFor(request);
  if (user == null) return _unauthorized();
  return _json({'items': _cartJson(store, user.email)});
}

List<Map<String, dynamic>> _cartJson(ShopStore store, String email) {
  final items = store.carts[email] ?? [];
  return [
    for (final item in items)
      if (_find(store, item.productId) case final product?) item.toJson(product),
  ];
}

Product? _find(ShopStore store, String id) {
  for (final product in store.products) {
    if (product.id == id) return product;
  }
  return null;
}

Future<Response> _syncCart(Request request, ShopStore store) async {
  final user = store.userFor(request);
  if (user == null) return _unauthorized();
  final body = await _body(request);
  final raw = body['items'];
  if (raw is! List) return _json({'error': 'Items are required.'}, status: 400);
  final next = <CartItem>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final id = entry['productId']?.toString() ?? '';
    final qty = int.tryParse('${entry['quantity']}') ?? 0;
    final product = _find(store, id);
    if (product == null || qty <= 0) continue;
    next.add(CartItem(productId: id, quantity: qty > product.stock ? product.stock : qty));
  }
  store.carts[user.email] = next;
  return _json({'items': _cartJson(store, user.email)});
}

Response _favorites(Request request, ShopStore store) {
  final user = store.userFor(request);
  if (user == null) return _unauthorized();
  final ids = store.favorites[user.email] ?? {};
  final items = store.products.where((product) => ids.contains(product.id)).map((p) => p.toJson()).toList();
  return _json({'items': items});
}

Response _addFavorite(Request request, ShopStore store, String id) {
  final user = store.userFor(request);
  if (user == null) return _unauthorized();
  if (_find(store, id) == null) return _json({'error': 'Product not found.'}, status: 404);
  store.favorites.putIfAbsent(user.email, () => {}).add(id);
  return _json({'ok': true});
}

Response _removeFavorite(Request request, ShopStore store, String id) {
  final user = store.userFor(request);
  if (user == null) return _unauthorized();
  store.favorites[user.email]?.remove(id);
  return _json({'ok': true});
}

Response _listAddresses(Request request, ShopStore store) {
  final user = store.userFor(request);
  if (user == null) return _unauthorized();
  final items = store.addresses[user.email] ?? [];
  return _json({'items': items.map((address) => address.toJson()).toList()});
}

Future<Response> _addAddress(Request request, ShopStore store) async {
  final user = store.userFor(request);
  if (user == null) return _unauthorized();
  final body = await _body(request);
  final address = Address(
    id: store.nextId('addr'),
    fullName: (body['fullName'] ?? '').toString().trim(),
    line1: (body['line1'] ?? '').toString().trim(),
    city: (body['city'] ?? '').toString().trim(),
    region: (body['region'] ?? '').toString().trim(),
    postalCode: (body['postalCode'] ?? '').toString().trim(),
  );
  if ([address.fullName, address.line1, address.city, address.region, address.postalCode].any((v) => v.isEmpty)) {
    return _json({'error': 'Complete the address.'}, status: 400);
  }
  store.addresses.putIfAbsent(user.email, () => []).add(address);
  return _json(address.toJson(), status: 201);
}

Response _deleteAddress(Request request, ShopStore store, String id) {
  final user = store.userFor(request);
  if (user == null) return _unauthorized();
  store.addresses[user.email]?.removeWhere((address) => address.id == id);
  return _json({'ok': true});
}

Future<Response> _pay(Request request, ShopStore store) async {
  final user = store.userFor(request);
  if (user == null) return _unauthorized();
  final body = await _body(request);
  final method = (body['method'] ?? '').toString();
  final amount = (body['amount'] as num?)?.toDouble() ?? 0;
  if (amount <= 0) return _json({'error': 'Amount must be greater than zero.'}, status: 400);
  if (method == 'stripe') {
    final pan = (body['cardNumber'] ?? '').toString().replaceAll(RegExp(r'\s+'), '');
    if (pan == '4000000000000002') {
      return _json({'error': 'Card declined.'}, status: 402);
    }
    if (pan != '4242424242424242') {
      return _json({'error': 'Use Stripe test card 4242424242424242.'}, status: 400);
    }
  } else if (method == 'paypal') {
    final email = (body['email'] ?? '').toString().toLowerCase();
    final password = (body['password'] ?? '').toString();
    if (email != 'buyer@mercer.test' || password != 'sandbox') {
      return _json({'error': 'PayPal sandbox is buyer@mercer.test / sandbox.'}, status: 400);
    }
  } else {
    return _json({'error': 'Unknown payment method.'}, status: 400);
  }
  final reference = store.nextId('pay');
  store.payments[reference] = {
    'email': user.email,
    'amount': roundMoney(amount),
    'method': method,
  };
  return _json({'ok': true, 'reference': reference, 'method': method});
}

Response _orders(Request request, ShopStore store) {
  final user = store.userFor(request);
  if (user == null) return _unauthorized();
  final items = store.orders[user.email] ?? [];
  return _json({'items': items.map((order) => order.toJson()).toList()});
}

Future<Response> _placeOrder(Request request, ShopStore store) async {
  final user = store.userFor(request);
  if (user == null) return _unauthorized();
  final body = await _body(request);
  final addressId = (body['addressId'] ?? '').toString();
  final reference = (body['paymentReference'] ?? '').toString();
  final cart = store.carts[user.email] ?? [];
  if (cart.isEmpty) return _json({'error': 'Cart is empty.'}, status: 400);
  final address = (store.addresses[user.email] ?? []).where((item) => item.id == addressId).firstOrNull;
  if (address == null) return _json({'error': 'Choose a saved address.'}, status: 400);
  final payment = store.payments[reference];
  if (payment == null || payment['email'] != user.email) {
    return _json({'error': 'Payment was not confirmed.'}, status: 400);
  }
  final lines = _cartJson(store, user.email);
  final total = roundMoney(lines.fold<double>(0, (sum, line) => sum + (line['lineTotal'] as num).toDouble()));
  final shipping = total >= 60 || total == 0 ? 0.0 : 5.0;
  final tax = roundMoney(total * 0.0825);
  final due = roundMoney(total + shipping + tax);
  if ((payment['amount'] as double) != due) {
    return _json({'error': 'Payment amount does not match the cart.'}, status: 400);
  }
  final order = ShopOrder(
    id: store.nextId('order'),
    createdAt: DateTime.now().toIso8601String(),
    lines: lines,
    total: due,
    address: address.toJson(),
    paymentMethod: payment['method'] as String,
    paymentReference: reference,
  );
  store.orders.putIfAbsent(user.email, () => []).insert(0, order);
  store.carts[user.email] = [];
  store.payments.remove(reference);
  return _json({
    ...order.toJson(),
    'subtotal': total,
    'shipping': shipping,
    'tax': tax,
  }, status: 201);
}

List<Product> seedProducts() {
  Product item(
    String id,
    String name,
    String category,
    double price,
    double rating,
    int reviews,
    int hue,
    String description,
  ) {
    return Product(
      id: id,
      name: name,
      category: category,
      price: price,
      rating: rating,
      reviewCount: reviews,
      description: description,
      hue: hue,
      stock: 20,
    );
  }

  return [
    item('mk-01', 'Cast Iron Skillet', 'Kitchen', 48, 4.8, 320, 18, '10-inch skillet, pre-seasoned, heavy enough to hold heat for a steak.'),
    item('mk-02', 'Linen Tea Towels', 'Kitchen', 22, 4.6, 140, 40, 'Set of two washed linen towels. They dry glass without leaving lint.'),
    item('mk-03', 'Beech Cutting Board', 'Kitchen', 36, 4.7, 98, 32, 'Edge-grain board with a juice groove and a leather tie.'),
    item('mk-04', 'Glass Storage Set', 'Kitchen', 32, 4.5, 210, 190, 'Three stackable glass boxes with locking lids.'),
    item('mk-05', 'Kettle', 'Kitchen', 64, 4.4, 76, 200, 'Stovetop kettle that whistles once, not forever. 1.5 liters.'),
    item('mk-06', 'Oat Groats', 'Grocery', 9, 4.7, 88, 42, 'Two-pound bag of whole oats. Cook low, with salt, until they shine.'),
    item('mk-07', 'Tomato Passata', 'Grocery', 7, 4.6, 150, 6, 'Glass bottle of strained tomatoes. Nothing else in the ingredient list.'),
    item('mk-08', 'Coffee Beans', 'Grocery', 16, 4.9, 410, 22, 'Twelve ounces, medium roast, chocolate and orange peel.'),
    item('mk-09', 'Olive Oil', 'Grocery', 19, 4.8, 260, 52, '500 ml tin. Green, peppery, good on beans and toast.'),
    item('mk-10', 'Sea Salt', 'Grocery', 8, 4.5, 70, 210, 'Flake salt in a jar. Finish with it, do not boil pasta in it.'),
    item('mk-11', 'Honey', 'Grocery', 12, 4.9, 188, 38, 'Raw wildflower honey. It will crystallize. That is fine.'),
    item('mk-12', 'Dish Soap', 'Wellness', 11, 4.4, 133, 150, 'Unscented soap that cuts grease and does not perfume the kitchen.'),
    item('mk-13', 'Hand Cream', 'Wellness', 14, 4.6, 90, 16, 'Short ingredient list, tube not a jar, fits in a bag.'),
    item('mk-14', 'Wool Dryer Balls', 'Wellness', 18, 4.3, 64, 28, 'Set of three. They shorten the cycle and skip the scented sheet.'),
    item('mk-15', 'Notebook', 'Stationery', 14, 4.8, 240, 220, 'A5, dotted, thread-bound, paper that takes a fountain pen.'),
    item('mk-16', 'Brass Pen', 'Stationery', 28, 4.5, 51, 44, 'Hexagonal brass pen. It gets darker where your hand rests.'),
    item('mk-17', 'Kraft Mailers', 'Stationery', 12, 4.2, 40, 30, 'Pack of ten rigid mailers. For the thing you keep meaning to return.'),
    item('mk-18', 'Desk Calendar', 'Stationery', 18, 4.6, 77, 250, 'A year of thick pages. One month at a time, no quotes.'),
  ];
}

const storeLocations = [
  StoreLocation(
    id: 'store-1',
    name: 'Mercer Congress',
    address: '1200 Congress Ave, Austin',
    latitude: 30.2747,
    longitude: -97.7404,
  ),
  StoreLocation(
    id: 'store-2',
    name: 'Mercer East',
    address: '1801 E 6th St, Austin',
    latitude: 30.2615,
    longitude: -97.7242,
  ),
  StoreLocation(
    id: 'store-3',
    name: 'Mercer Domain',
    address: '11700 Domain Blvd, Austin',
    latitude: 30.4005,
    longitude: -97.7256,
  ),
  StoreLocation(
    id: 'store-4',
    name: 'Mercer South',
    address: '2400 S Congress Ave, Austin',
    latitude: 30.2420,
    longitude: -97.7512,
  ),
];
