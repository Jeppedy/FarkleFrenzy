import 'package:flutter_test/flutter_test.dart';
import 'package:farkle_frenzy/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FarkleFrenzyApp());
    expect(find.text('FARKLE FRENZY'), findsWidgets);
  });
}
