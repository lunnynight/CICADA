---
phase: 01-service-unit-tests
plan: "02"
subsystem: services
tags: [testing, mcp, proxy, installer, diagnostic, integration]
dependency_graph:
  requires: [01-01]
  provides: [mcp-service-tests, proxy-service-tests, installer-service-tests, integration-service-tests, diagnostic-service-tests]
  affects: [test-coverage]
tech_stack:
  added: []
  patterns: [backup-restore-test-pattern, shared-preferences-mock, pure-function-testing]
key_files:
  created:
    - test/services/mcp_service_test.dart
    - test/services/proxy_service_test.dart
    - test/services/installer_service_test.dart
    - test/services/integration_service_test.dart
    - test/services/diagnostic_service_test.dart
  modified:
    - lib/services/config_service.dart
decisions:
  - ProxyConfig needs type=ProxyType.http for isConfigured to be true
  - FeishuService API adapted to actual signatures (saveCredentials takes object, not named params)
metrics:
  duration: 6min
  completed: "2026-04-08"
  tasks: 5
  tests_added: 40
  files_created: 5
  files_modified: 1
---

# Phase 01 Plan 02: Service Unit Tests Wave 2 Summary

McpService CRUD, ProxyService config, InstallerService version parsing, FeishuService credentials, and DiagnosticService report export — 40 tests across 5 files, all green.

## Test Results

| Test File | Tests | Status |
|-----------|-------|--------|
| mcp_service_test.dart | 8 | PASS |
| proxy_service_test.dart | 4 | PASS |
| installer_service_test.dart | 7 | PASS |
| integration_service_test.dart | 11 | PASS |
| diagnostic_service_test.dart | 10 | PASS |
| **Total** | **40** | **ALL PASS** |

Regression: setup_state_test.dart (11 tests) still passes.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | d5b3fb1 | McpService CRUD tests (8 tests) |
| 2 | c8437cb | ProxyService config tests (4 tests) + ConfigService mutable map fix |
| 3 | bb55710 | InstallerService parseNodeMajorVersion tests (7 tests) |
| 4 | 4b997ac | FeishuService integration tests (11 tests) |
| 5 | d989040 | DiagnosticService pure-logic tests (10 tests) |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] ConfigService.readConfig() returns const unmodifiable map**
- **Found during:** Task 2 (ProxyService tests)
- **Issue:** ConfigRepository.readConfig() returns `const Success(<String, dynamic>{})` when file missing. ConfigService.readConfig() passes this const map through, causing ProxyService.saveConfig() to fail when trying to mutate it.
- **Fix:** Changed ConfigService.readConfig() to return `Map<String, dynamic>.from(data)` — a mutable copy.
- **Files modified:** lib/services/config_service.dart
- **Commit:** c8437cb

**2. [Plan Adaptation] FeishuService API signatures differ from plan**
- **Found during:** Task 4
- **Issue:** Plan assumed `saveCredentials(appId:, appSecret:)` named params and `FeishuTokenResult.success(token)/failure(error)`. Actual API: `saveCredentials(FeishuCredentials)`, `FeishuTokenResult.success(token:, expire:)/.error()`, `FeishuTestResult.success(latency:)/.failure(error, latency)`.
- **Fix:** Adapted test code to match actual source signatures.
- **Files modified:** test/services/integration_service_test.dart

**3. [Plan Adaptation] ProxyConfig requires type field for isConfigured**
- **Found during:** Task 2
- **Issue:** Plan used `ProxyConfig(enabled: true, host: '127.0.0.1', port: 7890)` but `isConfigured` checks `type != ProxyType.none`. Default type is `none`, so proxy env vars would be empty.
- **Fix:** Added `type: ProxyType.http` to test ProxyConfig constructors.
- **Files modified:** test/services/proxy_service_test.dart

## Known Stubs

None — all tests exercise real service code with no stubs or placeholders.

## Self-Check: PASSED

- All 5 commits verified (d5b3fb1, c8437cb, bb55710, 4b997ac, d989040)
- All 5 test files exist
- Modified file (lib/services/config_service.dart) exists
