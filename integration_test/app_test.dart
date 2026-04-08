import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cicada/main.dart';

// Patrol framework is configured (pubspec.yaml: patrol ^3.13.1).
// Native Patrol features ($.native, device interaction) require device/emulator execution
// via `patrol test`. These smoke tests verify app launches correctly using the
// flutter_test runner, which is CI-friendly per D-05.
//
// To run with full Patrol native features:
//   patrol test integration_test/app_test.dart
// To run in CI (flutter_test runner):
//   flutter test integration_test/app_test.dart

void main() {
  testWidgets(
    'app smoke test - launches and renders CICADA title',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: CicadaApp()),
      );
      // Pump a few frames to let initial build complete.
      // Using pump() instead of pumpAndSettle() to avoid Timer.periodic timeout
      // from HomePage's gateway status polling (same pattern as widget_test.dart).
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('CICADA'), findsOneWidget);
    },
  );

  testWidgets(
    'app smoke test - shows navigation structure',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: CicadaApp()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Verify at least one navigation element is visible.
      // On wide screens: sidebar with nav items (text labels).
      // On narrow screens: bottom NavigationBar.
      final hasSidebar = find.text('仪表盘').evaluate().isNotEmpty;
      final hasBottomNav = find.byType(NavigationBar).evaluate().isNotEmpty;
      expect(hasSidebar || hasBottomNav, isTrue);
    },
  );

  // INTG-02: Full install flow end-to-end test
  // This test documents the intended flow for future implementation:
  //   1. Launch app
  //   2. Navigate to setup wizard
  //   3. Environment detection runs (requires real Node.js/OpenClaw CLI)
  //   4. Install Node.js (requires network + write access)
  //   5. Install OpenClaw (requires network + npm)
  //   6. Verify installation completes and setup wizard advances
  //
  // Skipped per D-04: no real env dependency in Phase 2.
  // Will be unskipped when real test environment is available (future phase).
  // This satisfies INTG-02 via the "graceful skip" path allowed by ROADMAP success criteria.
  testWidgets(
    'install flow e2e - skipped without environment',
    (tester) async {
      // Intentionally empty — see skip reason above.
    },
    skip: true, // Requires real Node.js/OpenClaw environment (D-04: no real env dependency)
  );
}
