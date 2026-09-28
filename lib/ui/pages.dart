import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../controllers/shop_controllers.dart';
import '../core/logic.dart';
import '../data/api_client.dart';
import '../data/models.dart';
import '../services/firebase_gate.dart';
import 'theme.dart';
import 'widgets.dart';

const _categories = ['Kitchen', 'Grocery', 'Wellness', 'Stationery'];

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [ShopPage(), SavedPage(), CartPage(), OrdersPage(), ProfilePage()];
    return Obx(() {
      final wide = MediaQuery.sizeOf(context).width >= 960;
      final cartCount = Get.find<CartController>().count;
      final destinations = [
        const NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Shop'),
        const NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Saved'),
        NavigationDestination(
          icon: Badge(isLabelVisible: cartCount > 0, label: Text('$cartCount'), child: const Icon(Icons.shopping_bag_outlined)),
          label: 'Cart',
        ),
        const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        const NavigationDestination(icon: Icon(Icons.person_outline), label: 'You'),
      ];
      if (wide) {
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: (value) => setState(() => index = value),
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final destination in destinations)
                    NavigationRailDestination(icon: destination.icon, label: Text(destination.label)),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: pages[index]),
            ],
          ),
        );
      }
      return Scaffold(
        body: pages[index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          destinations: destinations,
          onDestinationSelected: (value) {
            setState(() => index = value);
            if (value == 3) Get.find<OrdersController>().load();
            if (value == 1) Get.find<FavoritesController>().load();
          },
        ),
      );
    });
  }
}

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 280) {
        Get.find<CatalogController>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = Get.find<CatalogController>();
    final favorites = Get.find<FavoritesController>();
    final cart = Get.find<CartController>();
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1100 ? 4 : width >= 720 ? 3 : 2;
    return Scaffold(
      appBar: AppBar(title: const Text('Mercer')),
      body: Obx(() {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search the shop'),
                onChanged: (value) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () => catalog.search(value));
                },
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final category in _categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: catalog.category.value == category,
                        onSelected: (_) => catalog.setCategory(category),
                      ),
                    ),
                ],
              ),
            ),
            if (catalog.failure.value?.kind == ApiFailureKind.offline && catalog.products.isNotEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text('Offline. Showing products saved in SQLite or preferences.'),
              ),
            Expanded(
              child: StatusBody(
                status: catalog.status.value,
                message: catalog.failure.value?.message,
                onRetry: catalog.refreshCatalog,
                child: RefreshIndicator(
                  onRefresh: catalog.refreshCatalog,
                  child: GridView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: catalog.products.length + (catalog.loadingMore.value ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= catalog.products.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final product = catalog.products[index];
                      return ProductTile(
                        product: product,
                        saved: favorites.contains(product.id),
                        onOpen: () => Get.to(() => ProductPage(product: product)),
                        onSave: () => favorites.toggle(product),
                        onAdd: () => cart.add(product),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class ProductPage extends StatelessWidget {
  const ProductPage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final favorites = Get.find<FavoritesController>();
    final cart = Get.find<CartController>();
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AspectRatio(aspectRatio: 1.2, child: ProductArtwork(hue: product.hue, category: product.category, radius: 20)),
          const SizedBox(height: 16),
          Text(product.category.toUpperCase(), style: const TextStyle(letterSpacing: 1.1, color: Color(0xFF66707A))),
          Text(product.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(money(product.price), style: const TextStyle(fontSize: 22, color: amber, fontWeight: FontWeight.w800)),
          Text('${product.rating.toStringAsFixed(1)} · ${product.reviewCount} reviews'),
          const SizedBox(height: 12),
          Text(product.description, style: const TextStyle(fontSize: 16, height: 1.4)),
          const SizedBox(height: 20),
          Obx(
            () => FilledButton(
              onPressed: () => favorites.toggle(product),
              child: Text(favorites.contains(product.id) ? 'Saved' : 'Save'),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => cart.add(product), child: const Text('Add to cart')),
        ],
      ),
    );
  }
}

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = Get.find<FavoritesController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: Obx(() {
        return StatusBody(
          status: favorites.status.value,
          message: favorites.failure.value?.message ?? 'Save products from the shop. They stay on this device.',
          onRetry: favorites.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = favorites.products[index];
              return ListTile(
                tileColor: card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: SizedBox(width: 52, height: 52, child: ProductArtwork(hue: product.hue, category: product.category, radius: 8)),
                title: Text(product.name),
                subtitle: Text(money(product.price)),
                trailing: IconButton(onPressed: () => favorites.toggle(product), icon: const Icon(Icons.favorite, color: amber)),
                onTap: () => Get.to(() => ProductPage(product: product)),
              );
            },
          ),
        );
      }),
    );
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Obx(() {
        if (cart.lines.isEmpty) {
          return const StatusBody(status: ViewStatus.empty, message: 'Your cart is empty.', child: SizedBox.shrink());
        }
        final totals = cart.totals;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final line in cart.lines)
              Card(
                child: ListTile(
                  title: Text(line.name),
                  subtitle: Text(money(line.unitPrice)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(onPressed: () => cart.setQty(line.productId, line.quantity - 1), icon: const Icon(Icons.remove)),
                      Text('${line.quantity}'),
                      IconButton(onPressed: () => cart.setQty(line.productId, line.quantity + 1), icon: const Icon(Icons.add)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text('Subtotal ${money(totals.subtotal)}'),
            Text('Shipping ${totals.shipping == 0 ? 'Free' : money(totals.shipping)}'),
            Text('Tax ${money(totals.tax)}'),
            Text('Total ${money(totals.total)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final auth = Get.find<AuthController>();
                if (!auth.signedIn.value) {
                  Get.to(() => const LoginPage());
                  return;
                }
                Get.to(() => const CheckoutPage());
              },
              child: const Text('Checkout'),
            ),
          ],
        );
      }),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _name = TextEditingController(text: 'Ada Mercer');
  final _line1 = TextEditingController(text: '12 Sabine St');
  final _city = TextEditingController(text: 'Austin');
  final _region = TextEditingController(text: 'TX');
  final _postal = TextEditingController(text: '78701');
  final _card = TextEditingController(text: '4242424242424242');
  final _paypalEmail = TextEditingController(text: 'buyer@mercer.test');
  final _paypalPassword = TextEditingController(text: 'sandbox');
  String _method = 'stripe';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _line1.dispose();
    _city.dispose();
    _region.dispose();
    _postal.dispose();
    _card.dispose();
    _paypalEmail.dispose();
    _paypalPassword.dispose();
    super.dispose();
  }

  Future<void> _place() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final cart = Get.find<CartController>();
    final totals = cart.totals;
    try {
      final order = await Get.find<OrdersController>().checkout(
        lines: cart.lines.toList(),
        address: Address(
          id: '',
          fullName: _name.text.trim(),
          line1: _line1.text.trim(),
          city: _city.text.trim(),
          region: _region.text.trim(),
          postalCode: _postal.text.trim(),
        ),
        payment: {
          'method': _method,
          'amount': totals.total,
          if (_method == 'stripe') 'cardNumber': _card.text,
          if (_method == 'paypal') 'email': _paypalEmail.text,
          if (_method == 'paypal') 'password': _paypalPassword.text,
        },
      );
      await cart.replace(const []);
      if (!mounted) return;
      Get.off(() => OrderDonePage(order: order));
    } on ApiFailure catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 8),
          TextField(controller: _line1, decoration: const InputDecoration(labelText: 'Street')),
          const SizedBox(height: 8),
          TextField(controller: _city, decoration: const InputDecoration(labelText: 'City')),
          const SizedBox(height: 8),
          TextField(controller: _region, decoration: const InputDecoration(labelText: 'State')),
          const SizedBox(height: 8),
          TextField(controller: _postal, decoration: const InputDecoration(labelText: 'Postal code')),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'stripe', label: Text('Stripe test')),
              ButtonSegment(value: 'paypal', label: Text('PayPal sandbox')),
            ],
            selected: {_method},
            onSelectionChanged: (value) => setState(() => _method = value.first),
          ),
          const SizedBox(height: 12),
          if (_method == 'stripe')
            TextField(controller: _card, decoration: const InputDecoration(labelText: 'Test card 4242...'))
          else ...[
            TextField(controller: _paypalEmail, decoration: const InputDecoration(labelText: 'Sandbox email')),
            const SizedBox(height: 8),
            TextField(controller: _paypalPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Sandbox password')),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _place, child: Text(_busy ? 'Placing…' : 'Place order')),
        ],
      ),
    );
  }
}

class OrderDonePage extends StatelessWidget {
  const OrderDonePage({super.key, required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmed')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order placed', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(order.id),
            Text(money(order.total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text('${order.paymentMethod} · ${order.paymentReference}'),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Get.until((route) => route.isFirst), child: const Text('Back to shop')),
          ],
        ),
      ),
    );
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = Get.find<OrdersController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: Obx(() {
        if (!Get.find<AuthController>().signedIn.value) {
          return StatusBody(
            status: ViewStatus.empty,
            message: 'Sign in to see orders.',
            actionLabel: 'Sign in',
            onRetry: () => Get.to(() => const LoginPage()),
            child: const SizedBox.shrink(),
          );
        }
        return StatusBody(
          status: orders.status.value,
          message: orders.failure.value?.message,
          onRetry: orders.load,
          child: RefreshIndicator(
            onRefresh: orders.load,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.orders.length,
              itemBuilder: (context, index) {
                final order = orders.orders[index];
                return Card(
                  child: ListTile(
                    title: Text(order.id),
                    subtitle: Text('${order.addressSummary}\n${order.paymentReference}'),
                    isThreeLine: true,
                    trailing: Text(money(order.total)),
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final api = Get.find<ApiClient>();
    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: Obx(() {
        if (!auth.signedIn.value) {
          return Center(
            child: FilledButton(onPressed: () => Get.to(() => const LoginPage()), child: const Text('Sign in')),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(auth.displayName.value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            Text(Get.find<AuthController>().session.email ?? ''),
            const SizedBox(height: 8),
            Text('API ${api.baseUrl}'),
            Text(FirebaseGate.ready ? 'Firebase connected' : 'Firebase not configured. The REST API is the source of truth.'),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Get.to(() => const ProfileEditPage()), child: const Text('Edit profile')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => Get.to(() => const StoresPage()), child: const Text('Store map')),
            const SizedBox(height: 8),
            TextButton(onPressed: auth.logout, child: const Text('Sign out')),
          ],
        );
      }),
    );
  }
}

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final _name = TextEditingController(text: Get.find<AuthController>().displayName.value);
  late final _phone = TextEditingController(text: Get.find<AuthController>().phone.value);
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 8),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              try {
                await Get.find<AuthController>().updateProfile(_name.text, _phone.text);
                Get.back();
              } on ApiFailure catch (error) {
                setState(() => _error = error.message);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController(text: 'ada@mercer.shop');
  final _password = TextEditingController(text: 'mercer123');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Demo account is filled in.', style: TextStyle(color: Color(0xFF66707A))),
          const SizedBox(height: 12),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 8),
          TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          Obx(() => auth.error.value == null ? const SizedBox.shrink() : Text(auth.error.value!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 16),
          Obx(
            () => FilledButton(
              onPressed: auth.busy.value
                  ? null
                  : () async {
                      final ok = await auth.login(_email.text, _password.text);
                      if (ok) {
                        await Get.find<OrdersController>().load();
                        await Get.find<FavoritesController>().load();
                        Get.back();
                      }
                    },
              child: const Text('Sign in'),
            ),
          ),
          TextButton(onPressed: () => Get.to(() => const RegisterPage()), child: const Text('Create account')),
        ],
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 8),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 8),
          TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          Obx(() => Text(auth.error.value ?? '', style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final ok = await auth.register(_name.text, _email.text, _password.text);
              if (ok) Get.back();
            },
            child: const Text('Create account'),
          ),
        ],
      ),
    );
  }
}

class StoresPage extends StatefulWidget {
  const StoresPage({super.key});

  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  List<StorePin> _stores = const [];
  double? _lat;
  double? _lng;
  String? _error;
  bool _loading = true;

  static const _useGoogle = bool.fromEnvironment('USE_GOOGLE_MAPS');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stores = await Get.find<ApiClient>().stores();
      if (mounted) {
        setState(() {
          _stores = stores;
          _loading = false;
        });
      }
    } on ApiFailure catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    }
  }

  Future<void> _locate() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission was denied. Distances stay hidden.');
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'Location is unavailable on this device.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stores')),
      body: _loading
          ? const StatusBody(status: ViewStatus.loading, child: SizedBox.shrink())
          : _stores.isEmpty
              ? StatusBody(status: _error == null ? ViewStatus.empty : ViewStatus.offline, message: _error, onRetry: _load, child: const SizedBox.shrink())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SizedBox(
                      height: 240,
                      child: _useGoogle
                          ? GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(_stores.first.latitude, _stores.first.longitude),
                                zoom: 11,
                              ),
                              myLocationEnabled: _lat != null,
                              markers: {
                                for (final store in _stores)
                                  Marker(
                                    markerId: MarkerId(store.id),
                                    position: LatLng(store.latitude, store.longitude),
                                    infoWindow: InfoWindow(title: store.name),
                                  ),
                              },
                            )
                          : _Plot(stores: _stores, lat: _lat, lng: _lng),
                    ),
                    const SizedBox(height: 8),
                    const Text('Set USE_GOOGLE_MAPS to draw Google Maps tiles. This plot works without an API key.'),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: _locate, child: const Text('Use my location')),
                    if (_error != null) Text(_error!),
                    for (final store in _stores)
                      ListTile(
                        title: Text(store.name),
                        subtitle: Text(
                          _lat == null
                              ? store.address
                              : '${store.address}\n${haversineKm(_lat!, _lng!, store.latitude, store.longitude).toStringAsFixed(1)} km away',
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _Plot extends StatelessWidget {
  const _Plot({required this.stores, required this.lat, required this.lng});

  final List<StorePin> stores;
  final double? lat;
  final double? lng;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PlotPainter(stores: stores, lat: lat, lng: lng),
      child: const SizedBox.expand(),
    );
  }
}

class _PlotPainter extends CustomPainter {
  _PlotPainter({required this.stores, required this.lat, required this.lng});

  final List<StorePin> stores;
  final double? lat;
  final double? lng;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)),
      Paint()..color = const Color(0xFFE7EEF2),
    );
    final points = [
      for (final store in stores) (store.latitude, store.longitude),
      if (lat != null && lng != null) (lat!, lng!),
    ];
    final minLat = points.map((point) => point.$1).reduce((a, b) => a < b ? a : b);
    final maxLat = points.map((point) => point.$1).reduce((a, b) => a > b ? a : b);
    final minLng = points.map((point) => point.$2).reduce((a, b) => a < b ? a : b);
    final maxLng = points.map((point) => point.$2).reduce((a, b) => a > b ? a : b);
    Offset place(double latitude, double longitude) {
      final x = (longitude - minLng) / ((maxLng - minLng).abs() < 0.0001 ? 1 : (maxLng - minLng));
      final y = 1 - (latitude - minLat) / ((maxLat - minLat).abs() < 0.0001 ? 1 : (maxLat - minLat));
      return Offset(24 + x * (size.width - 48), 24 + y * (size.height - 48));
    }

    for (final store in stores) {
      canvas.drawCircle(place(store.latitude, store.longitude), 8, Paint()..color = ink);
    }
    if (lat != null && lng != null) {
      canvas.drawCircle(place(lat!, lng!), 7, Paint()..color = amber);
    }
  }

  @override
  bool shouldRepaint(covariant _PlotPainter oldDelegate) => true;
}
