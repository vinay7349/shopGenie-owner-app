import 'package:flutter_test/flutter_test.dart';
import 'package:shopgenie_flutter/main.dart';

void main() {
  testWidgets('ShopGenie Owner App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ShopGenieApp());
    expect(find.byType(ShopGenieApp), findsOneWidget);
  });
}
