import 'package:flutter_test/flutter_test.dart';
import 'package:eczane_bul/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Eczane Bul'), findsOneWidget);
  });
}
