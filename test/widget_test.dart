import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mercer_shop/core/logic.dart';
import 'package:mercer_shop/ui/widgets.dart';

void main() {
  testWidgets('offline and server states expose retry', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatusBody(
          status: ViewStatus.offline,
          onRetry: () => taps++,
          child: const Text('hidden'),
        ),
      ),
    );
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('hidden'), findsNothing);
    await tester.tap(find.text('Try again'));
    expect(taps, 1);

    await tester.pumpWidget(
      const MaterialApp(
        home: StatusBody(
          status: ViewStatus.serverError,
          message: 'Database down',
          child: SizedBox.shrink(),
        ),
      ),
    );
    expect(find.text('Server error'), findsOneWidget);
    expect(find.text('Database down'), findsOneWidget);
  });

  testWidgets('data state shows the child', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StatusBody(
          status: ViewStatus.data,
          child: Text('Cast Iron Skillet'),
        ),
      ),
    );
    expect(find.text('Cast Iron Skillet'), findsOneWidget);
  });
}
