import 'package:get/get.dart';

import '../core/logic.dart';
import '../data/api_client.dart';
import '../data/local_cache.dart';
import '../data/models.dart';
import '../data/session_store.dart';
import '../services/firebase_gate.dart';
import '../services/notify.dart';

class AuthController extends GetxController {
  SessionStore get session => Get.find<SessionStore>();
  ApiClient get api => Get.find<ApiClient>();

  final busy = false.obs;
  final error = RxnString();
  final signedIn = false.obs;
  final displayName = ''.obs;
  final phone = ''.obs;

  @override
  void onInit() {
    signedIn.value = session.signedIn;
    displayName.value = session.name ?? '';
    phone.value = session.phone ?? '';
    super.onInit();
  }

  Future<bool> login(String email, String password) async {
    busy.value = true;
    error.value = null;
    try {
      final data = await api.login(email.trim(), password);
      await _persist(data);
      await FirebaseGate.mirrorSignIn(email: email.trim(), password: password);
      return true;
    } on ApiFailure catch (failure) {
      error.value = failure.message;
      return false;
    } finally {
      busy.value = false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    busy.value = true;
    error.value = null;
    try {
      final data = await api.register(name.trim(), email.trim(), password);
      await _persist(data);
      await FirebaseGate.mirrorSignIn(email: email.trim(), password: password);
      return true;
    } on ApiFailure catch (failure) {
      error.value = failure.message;
      return false;
    } finally {
      busy.value = false;
    }
  }

  Future<void> updateProfile(String name, String nextPhone) async {
    final data = await api.updateProfile(name: name, phone: nextPhone);
    await session.save(
      token: session.token!,
      name: data['name'] as String? ?? name,
      email: session.email!,
      userId: session.userId!,
      phone: data['phone'] as String? ?? nextPhone,
    );
    displayName.value = session.name ?? name;
    phone.value = session.phone ?? nextPhone;
  }

  Future<void> logout() async {
    await session.clear();
    signedIn.value = false;
    displayName.value = '';
    phone.value = '';
  }

  Future<void> _persist(Map<String, dynamic> data) async {
    final user = Map<String, dynamic>.from(data['user'] as Map);
    await session.save(
      token: data['token'] as String,
      name: user['name'] as String,
      email: user['email'] as String,
      userId: user['id'] as String,
      phone: user['phone'] as String? ?? '',
    );
    signedIn.value = true;
    displayName.value = session.name ?? '';
    phone.value = session.phone ?? '';
  }
}

class CatalogController extends GetxController {
  ApiClient get api => Get.find<ApiClient>();
  LocalCache get cache => Get.find<LocalCache>();

  final products = <Product>[].obs;
  final status = ViewStatus.loading.obs;
  final failure = Rxn<ApiFailure>();
  final query = ''.obs;
  final category = RxnString();
  final hasMore = false.obs;
  final loadingMore = false.obs;
  int _page = 1;

  @override
  void onInit() {
    super.onInit();
    refreshCatalog();
  }

  Future<void> refreshCatalog() => _load(reset: true);

  Future<void> search(String text) async {
    query.value = text;
    await _load(reset: true);
  }

  Future<void> setCategory(String? next) async {
    category.value = category.value == next ? null : next;
    await _load(reset: true);
  }

  Future<void> loadMore() async {
    if (!hasMore.value || loadingMore.value) return;
    loadingMore.value = true;
    _page += 1;
    try {
      final page = await api.products(query: query.value, category: category.value, page: _page);
      products.addAll(page.items);
      hasMore.value = page.hasMore;
      failure.value = null;
      await cache.saveProducts(products);
    } on ApiFailure catch (error) {
      _page -= 1;
      failure.value = error;
    } finally {
      loadingMore.value = false;
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      _page = 1;
      if (products.isEmpty) status.value = ViewStatus.loading;
    }
    try {
      final page = await api.products(query: query.value, category: category.value, page: 1);
      products.assignAll(page.items);
      hasMore.value = page.hasMore;
      failure.value = null;
      await cache.saveProducts(products);
      status.value = resolveStatus(loading: false, count: products.length);
    } on ApiFailure catch (error) {
      failure.value = error;
      if (products.isEmpty) {
        final cached = await cache.products();
        final filtered = cached.where((product) {
          final needle = query.value.trim().toLowerCase();
          final matchesText = needle.isEmpty ||
              '${product.name} ${product.category} ${product.description}'.toLowerCase().contains(needle);
          final matchesCategory = category.value == null || product.category == category.value;
          return matchesText && matchesCategory;
        }).toList();
        if (filtered.isNotEmpty && error.kind == ApiFailureKind.offline) {
          products.assignAll(filtered);
          hasMore.value = false;
          status.value = ViewStatus.data;
          return;
        }
      }
      status.value = resolveStatus(
        loading: false,
        count: products.isEmpty ? 0 : products.length,
        failure: products.isEmpty ? error : null,
      );
    }
  }
}

class CartController extends GetxController {
  LocalCache get cache => Get.find<LocalCache>();

  final lines = <CartLine>[].obs;

  @override
  void onInit() {
    super.onInit();
    _restore();
  }

  int get count => lines.fold(0, (sum, line) => sum + line.quantity);

  Totals get totals => priceLines(lines.map((line) => (unitPrice: line.unitPrice, quantity: line.quantity)));

  Future<void> _restore() async {
    lines.assignAll(await cache.cart());
  }

  Future<void> add(Product product) async {
    final index = lines.indexWhere((line) => line.productId == product.id);
    if (index == -1) {
      lines.add(CartLine.fromProduct(product));
    } else if (lines[index].quantity < product.stock) {
      lines[index] = lines[index].copyWith(quantity: lines[index].quantity + 1);
    }
    lines.refresh();
    await cache.saveCart(lines);
  }

  Future<void> setQty(String productId, int quantity) async {
    if (quantity <= 0) {
      lines.removeWhere((line) => line.productId == productId);
    } else {
      final index = lines.indexWhere((line) => line.productId == productId);
      if (index != -1) lines[index] = lines[index].copyWith(quantity: quantity);
    }
    lines.refresh();
    await cache.saveCart(lines);
  }

  Future<void> replace(List<CartLine> next) async {
    lines.assignAll(next);
    await cache.saveCart(lines);
  }
}

class FavoritesController extends GetxController {
  ApiClient get api => Get.find<ApiClient>();
  LocalCache get cache => Get.find<LocalCache>();
  SessionStore get session => Get.find<SessionStore>();

  final ids = <String>{}.obs;
  final products = <Product>[].obs;
  final status = ViewStatus.loading.obs;
  final failure = Rxn<ApiFailure>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  bool contains(String id) => ids.contains(id);

  Future<void> load() async {
    final saved = await cache.favoriteIds();
    ids
      ..clear()
      ..addAll(saved);
    final catalog = await cache.products();
    products.assignAll(catalog.where((product) => ids.contains(product.id)));
    if (!session.signedIn) {
      status.value = ids.isEmpty ? ViewStatus.empty : ViewStatus.data;
      return;
    }
    if (products.isEmpty) status.value = ViewStatus.loading;
    try {
      final remote = await api.favorites();
      products.assignAll(remote);
      ids
        ..clear()
        ..addAll(remote.map((product) => product.id));
      await cache.saveFavoriteIds(ids.toList());
      failure.value = null;
      status.value = resolveStatus(loading: false, count: products.length);
    } on ApiFailure catch (error) {
      failure.value = error;
      status.value = resolveStatus(loading: false, count: ids.length, failure: ids.isEmpty ? error : null);
    }
  }

  Future<void> toggle(Product product) async {
    final saved = ids.contains(product.id);
    if (saved) {
      ids.remove(product.id);
      products.removeWhere((item) => item.id == product.id);
    } else {
      ids.add(product.id);
      if (!products.any((item) => item.id == product.id)) products.add(product);
    }
    ids.refresh();
    await cache.saveFavoriteIds(ids.toList());
    status.value = resolveStatus(loading: false, count: ids.length);
    if (!session.signedIn) return;
    try {
      if (saved) {
        await api.removeFavorite(product.id);
      } else {
        await api.addFavorite(product.id);
      }
    } on ApiFailure catch (error) {
      failure.value = error;
    }
  }
}

class OrdersController extends GetxController {
  ApiClient get api => Get.find<ApiClient>();
  LocalCache get cache => Get.find<LocalCache>();
  SessionStore get session => Get.find<SessionStore>();

  final orders = <ShopOrder>[].obs;
  final status = ViewStatus.empty.obs;
  final failure = Rxn<ApiFailure>();

  Future<void> load() async {
    if (!session.signedIn) {
      orders.clear();
      status.value = ViewStatus.empty;
      return;
    }
    if (orders.isEmpty) status.value = ViewStatus.loading;
    try {
      final remote = await api.orders();
      orders.assignAll(remote);
      await cache.saveOrders(remote);
      failure.value = null;
      status.value = resolveStatus(loading: false, count: orders.length);
    } on ApiFailure catch (error) {
      failure.value = error;
      if (orders.isEmpty && error.kind == ApiFailureKind.offline) {
        final cached = await cache.orders();
        if (cached.isNotEmpty) {
          orders.assignAll(cached);
          status.value = ViewStatus.data;
          return;
        }
      }
      status.value = resolveStatus(loading: false, count: orders.length, failure: orders.isEmpty ? error : null);
    }
  }

  Future<ShopOrder> checkout({
    required List<CartLine> lines,
    required Address address,
    required Map<String, dynamic> payment,
  }) async {
    await api.syncCart(lines);
    final saved = await api.addAddress(address);
    final paid = await api.pay(payment);
    final order = await api.placeOrder(
      addressId: saved.id,
      paymentReference: paid['reference'] as String,
    );
    orders.insert(0, order);
    await cache.saveOrders(orders);
    await cache.saveCart(const []);
    status.value = ViewStatus.data;
    await showOrderNotification(order.id);
    await FirebaseGate.pushOrder(order.toJson());
    return order;
  }
}
