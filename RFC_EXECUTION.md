# RFC: Cicada MVP Enhancement — Execution Log

## Status: Phase 1-4 COMPLETE (24/25 units)

Build: `flutter analyze` — 0 errors, 0 warnings, 24 info hints only.

## Dependency Graph (DAG)

```
U01 ─────────────────┬──→ U05 ──→ U06 ──→ U07
(AppError)           │   (ConfigRepo) (ConfigSvc) (Riverpod)
                     │         │
U02 ────────────────┘         │
(Result)                      │
                              ├──→ U11 ──→ U12 ──→ U17
U03 ──→ U04                   │   (McpSvc) (McpPage) (NavUpdate)
(KeyMasker) (Tests)           │
                              │
U08 ──→ U09                   │
(McpModel) (Presets)──────────┘
       ──→ U10
         (Directory)

U13 ──→ U14 ──→ U15 ──→ U16
(SkillModel) (Installer) (Discovery) (PageRefactor)

U18 ──→ U19 ──→ U21
(ProxyModel) (ProxySvc) (InstallerInject)
              ──→ U22
              (ProxyUI)

U01+U02 ──→ U20
            (DiagEnhance)

U23 ──→ U24
(WebViewDeps) (WebUIPage)
```

## Work Units — Final Status

### Tier 1 — Isolated file edits

| ID | Scope | Status |
|----|-------|--------|
| U01 | `lib/core/app_error.dart` — sealed AppError (6 subtypes) | DONE |
| U02 | `lib/core/result.dart` — Result<T> sealed class | DONE |
| U03 | `lib/utils/key_masker.dart` — maskApiKey, maskUrl, maskAuthHeader | DONE |
| U04 | `test/utils/key_masker_test.dart` — 11 test cases | DONE |
| U08 | `lib/models/mcp_server.dart` — McpServer + McpPreset + McpTransport | DONE |
| U09 | `lib/data/mcp_presets.dart` — 10 built-in presets | DONE |
| U10 | `lib/data/mcp_directory.dart` — 17 curated MCP entries | DONE |
| U13 | `lib/models/skill.dart` — unified Skill model + SkillSource enum | DONE |
| U18 | `lib/models/proxy_config.dart` — ProxyConfig + ProxyType + toEnvVars | DONE |
| U23 | `pubspec.yaml` — webview_flutter + wkwebview deps | DONE |

### Tier 2 — Multi-file behavior changes

| ID | Scope | Status |
|----|-------|--------|
| U05 | `lib/data/config_repository.dart` — atomic write + chmod 600 | DONE |
| U06 | Refactor `config_service.dart` — delegates to ConfigRepository | DONE |
| U07 | `lib/providers/config_provider.dart` — Riverpod providers | DONE |
| U11 | `lib/services/mcp_service.dart` — full CRUD + test + toggle | DONE |
| U12 | `lib/pages/mcp_page.dart` — 3-tab UI (My/Presets/Discover) | DONE |
| U14 | `lib/services/skill_installer_service.dart` — ClawHub + GitHub install | DONE |
| U15 | `lib/services/skill_discovery_service.dart` — unified discovery | DONE |
| U17 | `lib/pages/home_page.dart` — nav updated (14 items, +MCP +WebUI) | DONE |
| U19 | `lib/services/proxy_service.dart` — config + test + env vars | DONE |
| U20 | `lib/services/diagnostic_service.dart` — API endpoint checks added | DONE |
| U21 | `lib/services/installer_service.dart` — proxy env injection | DONE |
| U22 | `lib/pages/settings_page.dart` — proxy settings UI section | DONE |
| U24 | `lib/pages/webui_page.dart` — WebView container + nav bar | DONE |

### Tier 3 — Deferred

| ID | Scope | Status |
|----|-------|--------|
| U16 | Refactor skills_page.dart to use unified Skill model | DEFERRED (non-breaking; old model still works) |
| U25 | `lib/services/android_installer_service.dart` | DEFERRED (Phase 5) |

## Files Created (17 new)

```
lib/core/app_error.dart
lib/core/result.dart
lib/utils/key_masker.dart
lib/data/config_repository.dart
lib/data/mcp_presets.dart
lib/data/mcp_directory.dart
lib/models/mcp_server.dart
lib/models/skill.dart
lib/models/proxy_config.dart
lib/providers/config_provider.dart
lib/services/mcp_service.dart
lib/services/proxy_service.dart
lib/services/skill_installer_service.dart
lib/services/skill_discovery_service.dart
lib/pages/mcp_page.dart
lib/pages/webui_page.dart
test/utils/key_masker_test.dart
```

## Files Modified (5)

```
lib/services/config_service.dart      — delegates to ConfigRepository
lib/services/installer_service.dart   — proxy env injection in startService()
lib/services/diagnostic_service.dart  — API endpoint connectivity checks
lib/pages/home_page.dart              — 2 new nav items (MCP, WebUI)
lib/pages/settings_page.dart          — proxy settings UI section
pubspec.yaml                          — webview_flutter deps
```

## Integration Risk Summary

- **LOW**: All new files are additive; no existing behavior changed
- **ConfigService**: backward-compatible static API preserved, delegates to repo internally
- **InstallerService.startService()**: signature changed to accept optional `extraEnv` — callers passing no args unaffected
- **home_page.dart**: nav indices shifted by +2 after index 8 — only affects direct index references (none found outside this file)
