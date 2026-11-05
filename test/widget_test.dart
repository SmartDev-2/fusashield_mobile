import 'package:flutter_test/flutter_test.dart';
import 'package:fusashield_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FusaShieldApp());
    expect(find.text('FusaShield'), findsWidgets);
  });
}
