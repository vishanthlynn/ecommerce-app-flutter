import 'dart:convert';

import 'models.dart';

abstract class LocalCache {
  Future<void> saveProducts(List<Product> products);
  Future<List<Product>> products();
  Future<void> saveCart(List<CartLine> lines);
  Future<List<CartLine>> cart();
  Future<void> saveFavoriteIds(List<String> ids);
  Future<List<String>> favoriteIds();
  Future<void> saveOrders(List<ShopOrder> orders);
  Future<List<ShopOrder>> orders();
  Future<void> saveAddresses(List<Address> addresses);
  Future<List<Address>> addresses();
}

class MemoryCache implements LocalCache {
  List<Product> _products = [];
  List<CartLine> _cart = [];
  List<String> _favorites = [];
  List<ShopOrder> _orders = [];
  List<Address> _addresses = [];

  @override
  Future<List<Address>> addresses() async => List<Address>.from(_addresses);

  @override
  Future<List<CartLine>> cart() async => List<CartLine>.from(_cart);

  @override
  Future<List<String>> favoriteIds() async => List<String>.from(_favorites);

  @override
  Future<List<ShopOrder>> orders() async => List<ShopOrder>.from(_orders);

  @override
  Future<List<Product>> products() async => List<Product>.from(_products);

  @override
  Future<void> saveAddresses(List<Address> addresses) async => _addresses = List.of(addresses);

  @override
  Future<void> saveCart(List<CartLine> lines) async => _cart = List.of(lines);

  @override
  Future<void> saveFavoriteIds(List<String> ids) async => _favorites = List.of(ids);

  @override
  Future<void> saveOrders(List<ShopOrder> orders) async => _orders = List.of(orders);

  @override
  Future<void> saveProducts(List<Product> products) async => _products = List.of(products);
}

String encodeList(List<Map<String, dynamic>> rows) => jsonEncode(rows);

List<Map<String, dynamic>> decodeList(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  final decoded = jsonDecode(raw);
  if (decoded is! List) return [];
  return decoded.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
}
