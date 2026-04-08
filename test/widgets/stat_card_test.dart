import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/widgets/stat_card.dart';

void main() {
  group('StatCard', () {
    testWidgets('renders icon, label, value, hint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              icon: Icons.analytics,
              label: 'Sessions',
              value: '42',
              hint: 'today',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.analytics), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('today'), findsOneWidget);
    });

    testWidgets('onTap callback fires when card is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              icon: Icons.analytics,
              label: 'Sessions',
              value: '42',
              hint: 'today',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StatCard));
      expect(tapped, isTrue);
    });

    testWidgets('custom iconColor is applied', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              icon: Icons.analytics,
              label: 'Sessions',
              value: '42',
              hint: 'today',
              iconColor: Colors.red,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.analytics));
      expect(icon.color, equals(Colors.red));
    });

    testWidgets('onTap null does not crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              icon: Icons.analytics,
              label: 'Sessions',
              value: '42',
              hint: 'today',
            ),
          ),
        ),
      );

      // Should not throw
      await tester.tap(find.byType(StatCard));
      await tester.pump();
    });

    testWidgets('renders with long text without overflow error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              icon: Icons.analytics,
              label: 'Sessions',
              value: 'A very long value string',
              hint: 'today',
            ),
          ),
        ),
      );

      expect(find.text('A very long value string'), findsOneWidget);
    });
  });
}
