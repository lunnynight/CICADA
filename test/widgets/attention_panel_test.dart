import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/widgets/attention_panel.dart';
import '../../lib/models/dashboard_stats.dart';

void main() {
  group('AttentionPanel', () {
    testWidgets('renders empty — returns SizedBox.shrink, no title shown',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AttentionPanel(items: []),
          ),
        ),
      );

      expect(find.text('需要注意'), findsNothing);
    });

    testWidgets('renders info item with correct icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AttentionPanel(
              items: [
                AttentionItem(
                  level: AttentionLevel.info,
                  message: 'All good',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('All good'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders warning item with correct icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AttentionPanel(
              items: [
                AttentionItem(
                  level: AttentionLevel.warning,
                  message: 'Watch out',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Watch out'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
    });

    testWidgets('renders error item with correct icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AttentionPanel(
              items: [
                AttentionItem(
                  level: AttentionLevel.error,
                  message: 'Something broke',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Something broke'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('action button appears and fires callback', (tester) async {
      var actionFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttentionPanel(
              items: [
                AttentionItem(
                  level: AttentionLevel.warning,
                  message: 'Fix needed',
                  actionLabel: '修复',
                  onAction: () => actionFired = true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('修复'), findsOneWidget);
      await tester.tap(find.text('修复'));
      expect(actionFired, isTrue);
    });

    testWidgets('multiple items all render', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AttentionPanel(
              items: [
                AttentionItem(
                  level: AttentionLevel.info,
                  message: 'Item one',
                ),
                AttentionItem(
                  level: AttentionLevel.warning,
                  message: 'Item two',
                ),
                AttentionItem(
                  level: AttentionLevel.error,
                  message: 'Item three',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item one'), findsOneWidget);
      expect(find.text('Item two'), findsOneWidget);
      expect(find.text('Item three'), findsOneWidget);
      expect(find.text('需要注意'), findsOneWidget);
    });
  });
}
