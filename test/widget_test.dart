import 'package:flutter_test/flutter_test.dart';
import 'package:cicada/main.dart';

void main() {
  testWidgets('CicadaApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(const CicadaApp());
    expect(find.text('\u{1F997} 知了猴'), findsOneWidget);
  });
}
