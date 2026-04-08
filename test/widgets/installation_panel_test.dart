import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/setup/logic/setup_state.dart';
import '../../lib/pages/setup/widgets/installation_panel.dart';

/// Fake notifier that returns a fixed state without side effects.
class FakeSetupState extends SetupState {
  final SetupStateData _initialState;
  FakeSetupState(this._initialState);

  @override
  SetupStateData build() => _initialState;
}

Widget buildSubject({
  required SetupStateData stateData,
  String title = 'Node.js',
  String description = '安装运行时',
  InstallTarget target = InstallTarget.node,
  bool useBundled = false,
}) {
  return ProviderScope(
    overrides: [
      setupStateProvider.overrideWith(() => FakeSetupState(stateData)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: InstallationPanel(
            title: title,
            description: description,
            target: target,
            useBundled: useBundled,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('InstallationPanel', () {
    testWidgets('shows title and description text', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          stateData: SetupStateData.initial().copyWith(
            detecting: false,
            nodeInstalled: false,
            installing: false,
          ),
          title: 'Node.js',
          description: '安装运行时',
        ),
      );
      await tester.pump();

      expect(find.text('Node.js'), findsWidgets);
      expect(find.text('安装运行时'), findsOneWidget);
    });

    testWidgets('installed state shows 已安装 and version', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          stateData: SetupStateData.initial().copyWith(
            detecting: false,
            nodeInstalled: true,
            nodeVersion: 'v22.14.0',
          ),
          target: InstallTarget.node,
        ),
      );
      await tester.pump();

      expect(find.textContaining('已安装'), findsWidgets);
      expect(find.text('v22.14.0'), findsOneWidget);
    });

    testWidgets('installed state shows 下一步 button', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          stateData: SetupStateData.initial().copyWith(
            detecting: false,
            nodeInstalled: true,
            nodeVersion: 'v22.14.0',
          ),
          target: InstallTarget.node,
        ),
      );
      await tester.pump();

      expect(find.text('下一步'), findsOneWidget);
    });

    testWidgets('not installed state shows install button', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          stateData: SetupStateData.initial().copyWith(
            detecting: false,
            nodeInstalled: false,
            installing: false,
          ),
          target: InstallTarget.node,
        ),
      );
      await tester.pump();

      // online install button
      expect(find.text('在线安装'), findsOneWidget);
    });

    testWidgets('installing state shows CircularProgressIndicator',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(
          stateData: SetupStateData.initial().copyWith(
            detecting: false,
            nodeInstalled: false,
            installing: true,
          ),
          target: InstallTarget.node,
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('log lines visible when not empty', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          stateData: SetupStateData.initial().copyWith(
            detecting: false,
            nodeInstalled: false,
            installing: false,
            logLines: ['line1', 'line2'],
          ),
          target: InstallTarget.node,
        ),
      );
      await tester.pump();

      expect(find.text('line1'), findsOneWidget);
      expect(find.text('line2'), findsOneWidget);
    });

    testWidgets('claudeCode target shows 安装 button text', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          stateData: SetupStateData.initial().copyWith(
            detecting: false,
            claudeCodeInstalled: false,
            installing: false,
          ),
          target: InstallTarget.claudeCode,
          title: 'Claude Code',
          description: '安装 Claude Code CLI',
        ),
      );
      await tester.pump();

      expect(find.text('安装'), findsOneWidget);
      expect(find.text('在线安装'), findsNothing);
      expect(find.text('离线安装'), findsNothing);
    });
  });
}
