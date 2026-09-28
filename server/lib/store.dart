import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

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

class CartLine {
  CartLine({required this.productId, required this.quantity});

  final String productId;
  int quantity;

  Map<String, dynamic> toJson(Product product) => {
        'productId': productId,
        'name': product.name,
        'category': product.category,
        'unitPrice': product.price,
        'hue': product.hue,
        'quantity': quantity,
        'lineTotal': product.price * quantity,
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

class OrderRecord {
  OrderRecord({
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
  StoreLocation({
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

class AppStore {
  AppStore() {
    users['ada@mercer.shop'] = ShopUser(
      id: 'user-ada',
      name: 'Ada Mercer',
      email: 'ada@mercer.shop',
      passwordHash: hashPassword('mercer123'),
      phone: '512-555-0148',
    );
  }

  final products = seedProducts();
  final users = <String, ShopUser>{};
  final tokens = <String, String>{};
  final carts = <String, List<CartLine>>{};
  final favorites = <String, Set<String>>{};
  final addresses = <String, List<Address>>{};
  final orders = <String, List<OrderRecord>>{};
  final stores = seedStores();
  final _random = Random();

  ShopUser? userForToken(String? header) {
    if (header == null || !header.startsWith('Bearer ')) return null;
    final token = header.substring(7);
    final email = tokens[token];
    if (email == null) return null;
    return users[email];
  }

  String issueToken(ShopUser user) {
    final token = List.generate(24, (_) => _random.nextInt(16).toRadixString(16)).join();
    tokens[token] = user.email;
    return token;
  }

  Product? productById(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }
}

String hashPassword(String password) {
  return sha256.convert(utf8.encode('mercer::$password')).toString();
}

String newId(String prefix, Random random) {
  return '$prefix-${random.nextInt(1 << 32).toRadixString(16)}';
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
      stock: 24,
    );
  }

  return [
    item('mc-01', 'Cast Iron Skillet', 'Kitchen', 48, 4.8, 320, 18, '10-inch skillet, pre-seasoned, heavy enough to hold a sear.'),
    item('mc-02', 'Chef Knife', 'Kitchen', 72, 4.7, 188, 200, 'Eight-inch stainless knife with a full tang and a walnut handle.'),
    item('mc-03', 'Linen Napkins', 'Kitchen', 24, 4.5, 96, 42, 'Set of four washed linen napkins in oat.'),
    item('mc-04', 'Dutch Oven', 'Kitchen', 110, 4.9, 140, 8, 'Five-quart enameled pot for beans, bread, and Sunday stew.'),
    item('mc-05', 'Olivewood Spoon', 'Kitchen', 16, 4.4, 70, 30, 'Hand-finished spoon that will not scratch a seasoned pan.'),
    item('mc-06', 'Glass Storage Set', 'Kitchen', 32, 4.6, 210, 190, 'Three glass containers with locking lids.'),
    item('mc-07', 'Coffee Beans', 'Pantry', 18, 4.8, 410, 22, 'Medium roast, cocoa and red apple, twelve ounces.'),
    item('mc-08', 'Extra Virgin Oil', 'Pantry', 22, 4.7, 166, 70, 'Early harvest oil in a 500 ml tin.'),
    item('mc-09', 'Sea Salt', 'Pantry', 9, 4.6, 88, 210, 'Flake salt for finishing, not for the pasta water.'),
    item('mc-10', 'Wildflower Honey', 'Pantry', 14, 4.9, 250, 45, 'Raw seasonal honey. It crystallizes when it is real.'),
    item('mc-11', 'Rolled Oats', 'Pantry', 8, 4.5, 130, 40, 'Thick rolled oats in a paper bag, two pounds.'),
    item('mc-12', 'Black Pepper', 'Pantry', 11, 4.4, 77, 25, 'Whole peppercorns in a refillable jar.'),
    item('mc-13', 'Hand Soap', 'Home', 12, 4.6, 190, 150, 'Cedar and bitter orange, liquid, 12 ounces.'),
    item('mc-14', 'Cotton Towel', 'Home', 18, 4.7, 142, 168, 'Bath towel, low twist cotton, gets better after washing.'),
    item('mc-15', 'Beeswax Candle', 'Home', 20, 4.5, 101, 48, 'A single beeswax pillar, about forty hours.'),
    item('mc-16', 'Wool Throw', 'Home', 86, 4.8, 64, 12, 'Charcoal wool throw, loose weave, long fringe.'),
    item('mc-17', 'Desk Lamp', 'Home', 64, 4.4, 53, 220, 'Steel arm, linen shade, warm bulb included.'),
    item('mc-18', 'Ceramic Mug', 'Home', 22, 4.8, 300, 354, 'Speckled mug, twelve ounces, comfortable handle.'),
    item('mc-19', 'Market Tote', 'Out', 36, 4.6, 175, 130, 'Heavy canvas tote with a flat bottom.'),
    item('mc-20', 'Water Bottle', 'Out', 28, 4.7, 260, 175, 'Double wall, 600 ml, one-hand cap.'),
    item('mc-21', 'Field Notebook', 'Out', 14, 4.9, 340, 55, 'Pocket notebook, dotted, fountain-pen friendly.'),
    item('mc-22', 'Picnic Blanket', 'Out', 54, 4.5, 90, 100, 'Wool top, water-resistant back, straps closed.'),
    item('mc-23', 'Herb Shears', 'Out', 26, 4.4, 48, 115, 'Five blades and a comb. Rinse and hang.'),
    item('mc-24', 'Trail Binoculars', 'Out', 92, 4.3, 39, 140, '8x25, small enough for a jacket pocket.'),
  ];
}

List<StoreLocation> seedStores() {
  return [
    StoreLocation(id: 'st-1', name: 'Mercer Flagship', address: '200 Congress Ave, Austin', latitude: 30.2648, longitude: -97.7472),
    StoreLocation(id: 'st-2', name: 'Mercer East', address: '1200 E 6th St, Austin', latitude: 30.2626, longitude: -97.7265),
    StoreLocation(id: 'st-3', name: 'Mercer Domain', address: '11800 Domain Blvd, Austin', latitude: 30.4021, longitude: -97.7255),
    StoreLocation(id: 'st-4', name: 'Mercer South', address: '400 S Lamar Blvd, Austin', latitude: 30.2554, longitude: -97.7622),
  ];
}
