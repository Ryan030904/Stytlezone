import 'package:flutter_test/flutter_test.dart';

import 'package:webshop/main.dart';

void main() {
  testWidgets('StyleZone app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StyleZoneApp());
    expect(find.text('STYLEZONE'), findsWidgets);
  });
}
