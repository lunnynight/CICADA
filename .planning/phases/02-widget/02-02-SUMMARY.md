---
phase: 02-widget
plan: 02
subsystem: widget-tests
tags: [flutter, widget-test, setup-page, home-page, navigation]
dependency_graph:
  requires: []
  provides: [WDGT-03, WDGT-05]
  affects: [test/widgets/]
tech_stack:
  added: []
  patterns: [tester.runAsync for real async I/O, FlutterError.onError overflow suppression, physicalSize viewport control]
key_files:
  created:
    - test/widgets/setup_page_test.dart
    - test/widgets/home_page_test.dart
  modified: []
decisions:
  - "Strategy A used for SetupPage: InstallerService static methods have internal try/catch returning safe defaults, so _detect() completes without throwing in test env"
  - "tester.runAsync with 3s delay required for SetupPage tests — fake async pump does not run real Process.run I/O"
  - "Pre-existing 3.8px RenderFlex overflow in sidebar nav item Row suppressed via FlutterError.onError — not caused by these tests"
  - "Test assertions are host-machine-agnostic: check installed OR not-installed state rather than assuming neither is present"
metrics:
  duration: ~35min
  completed: "2026-04-08"
  tasks: 2
  files: 2
---

# Phase 02 Plan 02: SetupPage and HomePage Widget Tests Summary

Widget tests for the two most complex page-level widgets: SetupPage (9 tests) and HomePage (8 tests), covering render, detection state, navigation switching, StatusBadge display, and responsive layout. All 175 tests pass with no regressions.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | SetupPage full page render and interaction tests | 182d0d9 | test/widgets/setup_page_test.dart |
| 2 | HomePage navigation switching tests | b484af5 | test/widgets/home_page_test.dart |

## Decisions Made

- Strategy A for SetupPage mocking: `isNodeVersionSufficient()` and `checkOpenClaw()` both have internal try/catch returning safe defaults (exitCode=1, empty strings). `isBundledAvailable()` has try/catch returning false. So `_detect()` completes safely in tests without needing @visibleForTesting overrides.
- `tester.runAsync()` with a real `Future.delayed(3s)` is required for SetupPage tests. `pump(Duration(seconds: 2))` advances the fake clock but does not execute real `Process.run` I/O.
- Test assertions are host-machine-agnostic: the test machine has Node.js v24.13.1 and OpenClaw installed, so assertions check for either "已安装" or "未安装" rather than assuming a clean environment.
- Pre-existing 3.8px RenderFlex overflow in `home_page.dart:291` (sidebar nav item Row with accent bar + icon + text exceeds 172px constraint on selected item) is suppressed via `FlutterError.onError` in wide-layout tests. This is a pre-existing production bug, not introduced by these tests.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed as written. Strategy A (graceful error handling) was selected after verifying `_detect()` source code, as specified in the plan's decision rule.

### Out-of-scope Discovery

**Pre-existing overflow bug in `home_page.dart:291`**: The selected sidebar nav item Row overflows by 3.8px due to the accent bar (2px + 10px margin) pushing the row beyond its 172px constraint. Logged to deferred-items — not fixed as it is outside the scope of this plan.

## Known Stubs

None — test files only, no production stubs introduced.

## Self-Check: PASSED

- test/widgets/setup_page_test.dart: FOUND
- test/widgets/home_page_test.dart: FOUND
- Commit 182d0d9: FOUND
- Commit b484af5: FOUND
- `flutter test test/widgets/setup_page_test.dart test/widgets/home_page_test.dart`: 17/17 passed
- `flutter test` (full suite): 175 passed, 1 skipped, 0 failed
