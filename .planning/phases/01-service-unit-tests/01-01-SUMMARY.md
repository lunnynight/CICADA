---
phase: 01-service-unit-tests
plan: 01
subsystem: testing
tags: [flutter_test, mockito, unit-test, token-service, config-service]

requires: []
provides:
  - MockClient (mockito) for http.Client injection
  - ProcessRunner interface + FakeProcessRunner for CLI mocking
  - TokenService pure-logic test suite (14 tests)
  - ConfigService provider CRUD test suite (11 tests)
affects: [01-02, 01-03]

tech-stack:
  added: []
  patterns: [mockito-generated-mocks, process-runner-interface, temp-config-backup-restore]

key-files:
  created:
    - test/services/helpers/mock_http_client.dart
    - test/services/helpers/mock_http_client.mocks.dart
    - test/services/helpers/fake_process_runner.dart
    - test/services/token_service_test.dart
    - test/services/config_service_test.dart
  modified:
    - lib/services/config_service.dart

key-decisions:
  - "ProcessRunner abstract interface established for CLI mocking in Wave 2 tests"
  - "ConfigService tests use real ConfigRepository with backup/restore pattern instead of DI"
  - "Fixed ConfigService.readConfig() returning unmodifiable const map — mutable copy now returned"

patterns-established:
  - "Mock HTTP: @GenerateMocks([http.Client]) + stubGet helper for reusable HTTP mocking"
  - "Process mocking: ProcessRunner interface with FakeProcessRunner keyed by command string"
  - "Config test isolation: backup real config in setUp, restore in tearDown"

requirements-completed: [TEST-01, TEST-02, TEST-06, TEST-09]

duration: 6min
completed: 2026-04-08
---

# Phase 01 Plan 01: Mock Infrastructure + TokenService + ConfigService Tests Summary

**Mock helpers (MockClient, ProcessRunner) + 25 unit tests for TokenService pure logic and ConfigService provider CRUD, with unmodifiable-map bug fix**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-08T00:28:12Z
- **Completed:** 2026-04-08T00:34:36Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Created reusable mock infrastructure: MockClient via mockito and ProcessRunner interface for CLI process mocking
- 14 TokenService tests covering calculateStatistics, getRecentRecords, filterByDateRange, filterByModel — all pure functions, no mocks needed
- 11 ConfigService tests covering readConfig, setProvider, removeProvider, switchProvider, getConfiguredProviders with backup/restore isolation
- Fixed bug: ConfigService.readConfig() returned unmodifiable const map causing mutation errors in setProvider/removeProvider

## Task Commits

Each task was committed atomically:

1. **Task 1: Create mock infrastructure helpers** - `a35b2af` (chore)
2. **Task 2: TokenService pure-logic tests** - `7bece9e` (test)
3. **Task 3: ConfigService provider CRUD tests** - `19d98a9` (test)

## Files Created/Modified
- `test/services/helpers/mock_http_client.dart` - Reusable MockClient with stubGet convenience helper
- `test/services/helpers/mock_http_client.mocks.dart` - Generated mockito mocks for http.Client
- `test/services/helpers/fake_process_runner.dart` - ProcessRunner interface + FakeProcessRunner for CLI mocking
- `test/services/token_service_test.dart` - 14 tests for TokenService pure-logic methods
- `test/services/config_service_test.dart` - 11 tests for ConfigService provider CRUD operations
- `lib/services/config_service.dart` - Bug fix: readConfig() now returns mutable map copy

## Decisions Made
- ProcessRunner abstract interface chosen over direct Process.run mocking — establishes pattern for InstallerService/GatewayService tests in Wave 2
- ConfigService tests use real ConfigRepository with backup/restore rather than DI injection — avoids production code changes while maintaining test isolation
- Fixed unmodifiable map bug inline (Rule 1) rather than deferring

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ConfigService.readConfig() returned unmodifiable const map**
- **Found during:** Task 3 (ConfigService provider CRUD tests)
- **Issue:** `readConfig()` returned `result.dataOrNull ?? {}` where both the const Success map and the `?? {}` fallback are unmodifiable. Any caller mutating the returned map (setProvider, removeProvider) would crash with `Cannot modify unmodifiable map`.
- **Fix:** Changed to `Map<String, dynamic>.from(data)` to always return a mutable copy
- **Files modified:** lib/services/config_service.dart
- **Verification:** All 11 ConfigService tests pass after fix
- **Committed in:** 19d98a9 (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 bug fix)
**Impact on plan:** Essential for correctness — ConfigService was broken for any write operation when starting from empty config. No scope creep.

## Issues Encountered
None beyond the auto-fixed bug above.

## User Setup Required
None - no external service configuration required.

## Known Stubs
None - all tests use real assertions with concrete data.

## Next Phase Readiness
- Mock infrastructure ready for Wave 2 tests (DiagnosticService, IntegrationService, GatewayService, InstallerService)
- ProcessRunner interface ready for services that shell out to CLI tools
- MockClient ready for services making HTTP calls
- All 36 tests passing (14 new TokenService + 11 new ConfigService + 11 existing SetupState)

## Self-Check: PASSED

All 5 created files verified on disk. All 3 task commits (a35b2af, 7bece9e, 19d98a9) verified in git log.

---
*Phase: 01-service-unit-tests*
*Completed: 2026-04-08*
