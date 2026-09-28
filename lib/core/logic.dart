import 'dart:math' as math;

enum ViewStatus { loading, data, empty, offline, serverError }

enum ApiFailureKind { offline, server, unauthorized, validation }

class ApiFailure implements Exception {
  const ApiFailure(this.kind, this.message, {this.status});

  final ApiFailureKind kind;
  final String message;
  final int? status;

  @override
  String toString() => message;
}

ViewStatus resolveStatus({
  required bool loading,
  required int count,
  ApiFailure? failure,
}) {
  if (loading && count == 0) return ViewStatus.loading;
  if (count == 0 && failure != null) {
    if (failure.kind == ApiFailureKind.offline) return ViewStatus.offline;
    if (failure.kind == ApiFailureKind.server) return ViewStatus.serverError;
    if (failure.kind == ApiFailureKind.unauthorized) return ViewStatus.empty;
  }
  if (count == 0) return ViewStatus.empty;
  return ViewStatus.data;
}

double roundMoney(double value) => (value * 100).roundToDouble() / 100;

class Totals {
  const Totals({required this.subtotal, required this.shipping, required this.tax});

  final double subtotal;
  final double shipping;
  final double tax;

  double get total => roundMoney(subtotal + shipping + tax);
}

Totals priceLines(Iterable<({double unitPrice, int quantity})> lines) {
  final subtotal = roundMoney(
    lines.fold<double>(0, (sum, line) => sum + roundMoney(line.unitPrice * line.quantity)),
  );
  final shipping = subtotal == 0 || subtotal >= 60 ? 0.0 : 5.0;
  final tax = roundMoney(subtotal * 0.0825);
  return Totals(subtotal: subtotal, shipping: shipping, tax: tax);
}

String money(double value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2).split('.');
  final whole = fixed[0];
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
    buffer.write(whole[i]);
  }
  return '${negative ? '-' : ''}\$${buffer.toString()}.${fixed[1]}';
}

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earth = 6371.0;
  double rad(double degrees) => degrees * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * earth * math.asin(math.sqrt(a));
}
