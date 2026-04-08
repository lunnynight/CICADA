import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/pages/setup/logic/setup_state.dart';
import '../../lib/pages/setup/widgets/environment_detector.dart';

/// Fake notifier that returns a fixed state without running detectEnvironment.
class FakeSetupState extends SetupState {
  final SetupStateData _initialState;
  FakeSetupState(this._initialState);

  @override
  SetupStateData build() => _initialState;
}

Widget buildSubject(SetupStateData stateData) {
  return ProviderScope(
    overrides: [
      setupStateProvider.overrideWith(() => FakeSetupState(stateData)),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EnvironmentDetector(),
        ),
      ),
    ),
  );
}

void main() {
  group('EnvironmentDetector', () {
    testWidgets('shows 环境检测 title text', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          SetupStateData.initial().copyWith(detecting: false),
        ),
      );
      await tester.pump();

      expect(find.text('环境检测'), findsOneWidget);
    });

    testWidgets('detecting state shows CircularProgressIndicator',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(SetupStateData.initial()), // detecting: true by default
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('node installed shows 已安装 and check_circle icon',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(
          SetupStateData.initial().copyWith(
            detecting: false,
            nodeInstalled: true,
            nodeVersion: 'v22.14.0',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('已安装'), findsWidgets);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('node not installed shows 未安装 and cancel icon',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(
          SetupStateData.initial().copyWith(
            detecting: false,
            nodeInstalled: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('未安装'), findsWidgets);
      expect(find.byIcon(Icons.cancel), findsWidgets);
    });

    testWidgets('bundled available shows 离线安装包可用 text', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          SetupStateData.initial().copyWith(
            detecting: false,
            bundledAvailable: true,
            bundledNodeVersion: 'v22.14.0',
            bundledOpenClawVersion: 'v0.1.8',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('离线安装包可用'), findsOneWidget);
    });

    testWidgets('重新检测 button visible when not detecting', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          SetupStateData.initial().copyWith(detecting: false),
        ),
      );
      await tester.pump();

      expect(find.text('重新检测'), findsOneWidget);
    });

    testWidgets(
        '继续安装 button visible when node or openclaw not installed and not detecting',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(
          SetupStateData.initial().copyWith(
            detecting: false,
            nodeInstalled: false,
            openclawInstalled: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('继续安装'), findsOneWidget);
    });
  });
}
