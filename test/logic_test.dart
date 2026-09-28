import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercer_shop/core/logic.dart';
import 'package:mercer_shop/data/api_client.dart';

void main() {
  test('status covers loading, empty, offline, and server error', () {
    expect(resolveStatus(loading: true, count: 0), ViewStatus.loading);
    expect(resolveStatus(loading: false, count: 0), ViewStatus.empty);
    expect(resolveStatus(loading: false, count: 2), ViewStatus.data);
    expect(
      resolveStatus(
        loading: false,
        count: 0,
        failure: const ApiFailure(ApiFailureKind.offline, 'down'),
      ),
      ViewStatus.offline,
    );
    expect(
      resolveStatus(
        loading: false,
        count: 0,
        failure: const ApiFailure(ApiFailureKind.server, '500'),
      ),
      ViewStatus.serverError,
    );
    expect(
      resolveStatus(
        loading: false,
        count: 3,
        failure: const ApiFailure(ApiFailureKind.offline, 'down'),
      ),
      ViewStatus.data,
    );
  });

  test('cart totals match the API rounding', () {
    final totals = priceLines(const [
      (unitPrice: 48, quantity: 1),
      (unitPrice: 16, quantity: 2),
    ]);
    expect(totals.subtotal, 80);
    expect(totals.shipping, 0);
    expect(totals.tax, 6.6);
    expect(totals.total, 86.6);
    expect(money(86.6), '\$86.60');
  });

  test('haversine is zero at the same point', () {
    expect(haversineKm(30.27, -97.74, 30.27, -97.74), closeTo(0, 0.001));
    expect(haversineKm(30.2747, -97.7404, 30.2615, -97.7242), greaterThan(1));
  });

  test('dio errors map to offline and server failures', () {
    final offline = mapDioError(
      DioException(
        requestOptions: RequestOptions(path: '/v1/products'),
        type: DioExceptionType.connectionError,
      ),
    );
    expect(offline.kind, ApiFailureKind.offline);

    final server = mapDioError(
      DioException(
        requestOptions: RequestOptions(path: '/v1/products'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/v1/products'),
          statusCode: 500,
          data: {'error': 'boom'},
        ),
      ),
    );
    expect(server.kind, ApiFailureKind.server);
    expect(server.message, 'boom');
  });
}
