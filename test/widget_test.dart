import 'package:ecommerce_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test initializes without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LuxeStoreApp(),
      ),
    );
    expect(find.byType(LuxeStoreApp), findsOneWidget);
  });
}
