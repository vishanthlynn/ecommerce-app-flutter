import 'package:sqflite/sqflite.dart';

import 'local_cache.dart';
import 'models.dart';

Future<LocalCache> createCache() async {
  try {
    final cache = SqliteCache();
    await cache.open();
    return cache;
  } catch (_) {
    return MemoryCache();
  }
}

class SqliteCache implements LocalCache {
  Database? _db;

  Future<void> open() async {
    final folder = await getDatabasesPath();
    _db = await openDatabase(
      '$folder/mercer.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE kv (key TEXT PRIMARY KEY, value TEXT)');
      },
    );
  }

  Future<void> _put(String key, String value) async {
    await _db!.insert('kv', {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> _get(String key) async {
    final rows = await _db!.query('kv', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<List<Product>> products() async {
    return decodeList(await _get('products')).map(Product.fromJson).toList();
  }

  @override
  Future<void> saveProducts(List<Product> products) => _put('products', encodeList(products.map((p) => p.toJson()).toList()));

  @override
  Future<List<CartLine>> cart() async => decodeList(await _get('cart')).map(CartLine.fromJson).toList();

  @override
  Future<void> saveCart(List<CartLine> lines) => _put('cart', encodeList(lines.map((line) => line.toJson()).toList()));

  @override
  Future<List<String>> favoriteIds() async {
    final raw = await _get('favorites');
    if (raw == null || raw.isEmpty) return [];
    final decoded = decodeList(raw);
    return decoded.map((row) => row['id'] as String).toList();
  }

  @override
  Future<void> saveFavoriteIds(List<String> ids) {
    return _put('favorites', encodeList([for (final id in ids) {'id': id}]));
  }

  @override
  Future<List<ShopOrder>> orders() async => decodeList(await _get('orders')).map(ShopOrder.fromJson).toList();

  @override
  Future<void> saveOrders(List<ShopOrder> orders) => _put('orders', encodeList(orders.map((order) => order.toJson()).toList()));

  @override
  Future<List<Address>> addresses() async => decodeList(await _get('addresses')).map(Address.fromJson).toList();

  @override
  Future<void> saveAddresses(List<Address> addresses) {
    return _put('addresses', encodeList(addresses.map((address) => address.toJson()).toList()));
  }
}
