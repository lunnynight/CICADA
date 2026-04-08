import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/widgets/quick_action_button.dart';

void main() {
  group('QuickActionButton', () {
    // QuickActionButton uses Expanded internally, so it MUST be inside a Row.
    Widget buildSubject({
      IconData icon = Icons.play_arrow,
      String label = '启动',
      VoidCallback? onPressed,
      Color? backgroundColor,
      Color? foregroundColor,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              QuickActionButton(
                icon: icon,
                label: label,
                onPressed: onPressed ?? () {},
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('renders icon and label', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('启动'), findsOneWidget);
    });

    testWidgets('onPressed fires when button is tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(buildSubject(onPressed: () => pressed = true));

      await tester.tap(find.byType(ElevatedButton));
      expect(pressed, isTrue);
    });

    testWidgets('custom backgroundColor is applied', (tester) async {
      await tester.pumpWidget(
        buildSubject(backgroundColor: Colors.green),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final style = button.style;
      final bg = style?.backgroundColor?.resolve({});
      expect(bg, equals(Colors.green));
    });

    testWidgets('label text alignment is center', (tester) async {
      await tester.pumpWidget(buildSubject());

      final text = tester.widget<Text>(find.text('启动'));
      expect(text.textAlign, equals(TextAlign.center));
    });
  });
}
