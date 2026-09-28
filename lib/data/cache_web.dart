import 'package:shared_preferences/shared_preferences.dart';

import 'local_cache.dart';
import 'models.dart';

Future<LocalCache> createCache() async {
  final prefs = await SharedPreferences.getInstance();
  return PrefsCache(prefs);
}

class PrefsCache implements LocalCache {
  PrefsCache(this.prefs);

  final SharedPreferences prefs;

  Future<void> _put(String key, String value) => prefs.setString(key, value);

  @override
  Future<List<Address>> addresses() async => decodeList(prefs.getString('addresses')).map(Address.fromJson).toList();

  @override
  Future<List<CartLine>> cart() async => decodeList(prefs.getString('cart')).map(CartLine.fromJson).toList();

  @override
  Future<List<String>> favoriteIds() async {
    return decodeList(prefs.getString('favorites')).map((row) => row['id'] as String).toList();
  }

  @override
  Future<List<ShopOrder>> orders() async => decodeList(prefs.getString('orders')).map(ShopOrder.fromJson).toList();

  @override
  Future<List<Product>> products() async => decodeList(prefs.getString('products')).map(Product.fromJson).toList();

  @override
  Future<void> saveAddresses(List<Address> addresses) => _put('addresses', encodeList(addresses.map((a) => a.toJson()).toList()));

  @override
  Future<void> saveCart(List<CartLine> lines) => _put('cart', encodeList(lines.map((line) => line.toJson()).toList()));

  @override
  Future<void> saveFavoriteIds(List<String> ids) => _put('favorites', encodeList([for (final id in ids) {'id': id}]));

  @override
  Future<void> saveOrders(List<ShopOrder> orders) => _put('orders', encodeList(orders.map((order) => order.toJson()).toList()));

  @override
  Future<void> saveProducts(List<Product> products) => _put('products', encodeList(products.map((p) => p.toJson()).toList()));
}
