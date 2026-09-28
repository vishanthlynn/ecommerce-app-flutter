class Product {
  const Product({
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

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      hue: (json['hue'] as num?)?.toInt() ?? 20,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }
}

class CartLine {
  const CartLine({
    required this.productId,
    required this.name,
    required this.category,
    required this.unitPrice,
    required this.hue,
    required this.quantity,
  });

  final String productId;
  final String name;
  final String category;
  final double unitPrice;
  final int hue;
  final int quantity;

  double get lineTotal => (unitPrice * quantity * 100).roundToDouble() / 100;

  CartLine copyWith({int? quantity}) {
    return CartLine(
      productId: productId,
      name: name,
      category: category,
      unitPrice: unitPrice,
      hue: hue,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'category': category,
        'unitPrice': unitPrice,
        'hue': hue,
        'quantity': quantity,
      };

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      productId: json['productId'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num).toDouble(),
      hue: (json['hue'] as num?)?.toInt() ?? 20,
      quantity: (json['quantity'] as num).toInt(),
    );
  }

  factory CartLine.fromProduct(Product product, {int quantity = 1}) {
    return CartLine(
      productId: product.id,
      name: product.name,
      category: product.category,
      unitPrice: product.price,
      hue: product.hue,
      quantity: quantity,
    );
  }
}

class Address {
  const Address({
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

  String get summary => '$line1, $city, $region $postalCode';

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'line1': line1,
        'city': city,
        'region': region,
        'postalCode': postalCode,
      };

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      line1: json['line1'] as String,
      city: json['city'] as String,
      region: json['region'] as String,
      postalCode: json['postalCode'] as String,
    );
  }
}

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.createdAt,
    required this.lines,
    required this.total,
    required this.addressSummary,
    required this.paymentMethod,
    required this.paymentReference,
  });

  final String id;
  final String createdAt;
  final List<CartLine> lines;
  final double total;
  final String addressSummary;
  final String paymentMethod;
  final String paymentReference;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt,
        'lines': lines.map((line) => line.toJson()).toList(),
        'total': total,
        'addressSummary': addressSummary,
        'paymentMethod': paymentMethod,
        'paymentReference': paymentReference,
      };

  factory ShopOrder.fromJson(Map<String, dynamic> json) {
    final address = json['address'];
    final summary = json['addressSummary'] as String? ??
        (address is Map
            ? '${address['line1']}, ${address['city']}'
            : '');
    return ShopOrder(
      id: json['id'] as String,
      createdAt: json['createdAt'] as String? ?? '',
      lines: ((json['lines'] as List?) ?? [])
          .whereType<Map>()
          .map((line) => CartLine.fromJson(Map<String, dynamic>.from(line)))
          .toList(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      addressSummary: summary,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      paymentReference: json['paymentReference'] as String? ?? '',
    );
  }
}

class StorePin {
  const StorePin({
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

  factory StorePin.fromJson(Map<String, dynamic> json) {
    return StorePin(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class PageResult<T> {
  const PageResult({required this.items, required this.hasMore, required this.page});

  final List<T> items;
  final bool hasMore;
  final int page;
}
