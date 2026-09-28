import 'package:dio/dio.dart';

import '../core/logic.dart';
import 'models.dart';
import 'session_store.dart';

class ApiClient {
  ApiClient({required this.session, Dio? dio, String? baseUrl})
      : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ??
                    const String.fromEnvironment(
                      'API_BASE',
                      defaultValue: 'http://127.0.0.1:8080',
                    ),
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 8),
                headers: {'content-type': 'application/json'},
              ),
            ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = session.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final SessionStore session;
  final Dio dio;

  String get baseUrl => dio.options.baseUrl;

  Future<Map<String, dynamic>> login(String email, String password) {
    return _data(() => dio.post('/v1/auth/login', data: {'email': email, 'password': password}));
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) {
    return _data(
      () => dio.post('/v1/auth/register', data: {'name': name, 'email': email, 'password': password}),
    );
  }

  Future<PageResult<Product>> products({
    String query = '',
    String? category,
    int page = 1,
  }) async {
    final data = await _data(
      () => dio.get(
        '/v1/products',
        queryParameters: {
          'q': query,
          'category': ?category,
          'page': page,
          'limit': 8,
        },
      ),
    );
    final items = (data['items'] as List)
        .whereType<Map>()
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return PageResult(items: items, hasMore: data['hasMore'] == true, page: page);
  }

  Future<List<CartLine>> syncCart(List<CartLine> lines) async {
    final data = await _data(
      () => dio.post('/v1/cart/sync', data: {
        'items': [
          for (final line in lines) {'productId': line.productId, 'quantity': line.quantity},
        ],
      }),
    );
    return _lines(data['items']);
  }

  Future<List<Product>> favorites() async {
    final data = await _data(() => dio.get('/v1/favorites'));
    return (data['items'] as List)
        .whereType<Map>()
        .map((item) => Product.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> addFavorite(String id) => _data(() => dio.post('/v1/favorites/$id'));

  Future<void> removeFavorite(String id) => _data(() => dio.delete('/v1/favorites/$id'));

  Future<List<Address>> addresses() async {
    final data = await _data(() => dio.get('/v1/addresses'));
    return (data['items'] as List)
        .whereType<Map>()
        .map((item) => Address.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Address> addAddress(Address draft) async {
    final data = await _data(() => dio.post('/v1/addresses', data: draft.toJson()));
    return Address.fromJson(data);
  }

  Future<void> deleteAddress(String id) => _data(() => dio.delete('/v1/addresses/$id'));

  Future<Map<String, dynamic>> pay(Map<String, dynamic> payload) {
    return _data(() => dio.post('/v1/payments/test', data: payload));
  }

  Future<ShopOrder> placeOrder({
    required String addressId,
    required String paymentReference,
  }) async {
    final data = await _data(
      () => dio.post('/v1/orders', data: {
        'addressId': addressId,
        'paymentReference': paymentReference,
      }),
    );
    return ShopOrder.fromJson(data);
  }

  Future<List<ShopOrder>> orders() async {
    final data = await _data(() => dio.get('/v1/orders'));
    return (data['items'] as List)
        .whereType<Map>()
        .map((item) => ShopOrder.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Map<String, dynamic>> updateProfile({required String name, required String phone}) {
    return _data(() => dio.patch('/v1/profile', data: {'name': name, 'phone': phone}));
  }

  Future<List<StorePin>> stores() async {
    final data = await _data(() => dio.get('/v1/stores'));
    return (data['items'] as List)
        .whereType<Map>()
        .map((item) => StorePin.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<CartLine> _lines(Object? raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((item) => CartLine.fromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<Map<String, dynamic>> _data(Future<Response<dynamic>> Function() send) async {
    try {
      final response = await send();
      final body = response.data;
      if (body is Map<String, dynamic>) return body;
      if (body is Map) return Map<String, dynamic>.from(body);
      return {'ok': true};
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}

ApiFailure mapDioError(DioException error) {
  final status = error.response?.statusCode;
  final data = error.response?.data;
  final message = data is Map && data['error'] != null ? '${data['error']}' : null;
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.unknown && status == null) {
    return ApiFailure(ApiFailureKind.offline, message ?? 'You appear to be offline.');
  }
  if (status == 401) {
    return ApiFailure(ApiFailureKind.unauthorized, message ?? 'Sign in again.');
  }
  if (status != null && status >= 500) {
    return ApiFailure(ApiFailureKind.server, message ?? 'The server hit an error.');
  }
  return ApiFailure(
    ApiFailureKind.validation,
    message ?? 'The request could not be completed.',
    status: status,
  );
}
