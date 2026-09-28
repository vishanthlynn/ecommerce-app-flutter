class PaymentResult {
  const PaymentResult.ok(this.reference) : message = null;
  const PaymentResult.fail(this.message) : reference = null;

  final String? reference;
  final String? message;
  bool get ok => reference != null;
}

PaymentResult chargeTest({
  required String method,
  required double amount,
  String? cardNumber,
  String? expiry,
  String? cvc,
  String? paypalEmail,
  String? paypalPassword,
}) {
  if (amount <= 0) return const PaymentResult.fail('Amount must be greater than zero.');
  if (method == 'stripe_test') {
    final pan = (cardNumber ?? '').replaceAll(RegExp(r'\s+'), '');
    if (!_expiryOk(expiry ?? '')) {
      return const PaymentResult.fail('Enter a future expiry as MM/YY.');
    }
    if (!RegExp(r'^\d{3,4}$').hasMatch(cvc ?? '')) {
      return const PaymentResult.fail('Enter the test CVC.');
    }
    if (pan == '4000000000000002') {
      return const PaymentResult.fail('Card declined.');
    }
    if (pan != '4242424242424242') {
      return const PaymentResult.fail('Use Stripe test card 4242 4242 4242 4242.');
    }
    return PaymentResult.ok('pi_test_${pan.substring(pan.length - 4)}_${amount.toStringAsFixed(2)}');
  }
  if (method == 'paypal_test') {
    final email = (paypalEmail ?? '').trim().toLowerCase();
    if (email != 'buyer@mercer.test' || paypalPassword != 'sandbox') {
      return const PaymentResult.fail('PayPal sandbox is buyer@mercer.test / sandbox.');
    }
    return PaymentResult.ok('paypal_test_${amount.toStringAsFixed(2)}');
  }
  return const PaymentResult.fail('Unknown payment method.');
}

bool _expiryOk(String value) {
  final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(value.trim());
  if (match == null) return false;
  final month = int.parse(match.group(1)!);
  final year = 2000 + int.parse(match.group(2)!);
  if (month < 1 || month > 12) return false;
  return DateTime(year, month + 1, 0).isAfter(DateTime.now());
}
