<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **cicada** (214 symbols, 224 relationships, 0 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## When Debugging

1. `gitnexus_query({query: "<error or symptom>"})` — find execution flows related to the issue
2. `gitnexus_context({name: "<suspect function>"})` — see all callers, callees, and process participation
3. `READ gitnexus://repo/cicada/process/{processName}` — trace the full execution flow step by step
4. For regressions: `gitnexus_detect_changes({scope: "compare", base_ref: "main"})` — see what your branch changed

## When Refactoring

- **Renaming**: MUST use `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` first. Review the preview — graph edits are safe, text_search edits need manual review. Then run with `dry_run: false`.
- **Extracting/Splitting**: MUST run `gitnexus_context({name: "target"})` to see all incoming/outgoing refs, then `gitnexus_impact({target: "target", direction: "upstream"})` to find all external callers before moving code.
- After any refactor: run `gitnexus_detect_changes({scope: "all"})` to verify only expected files changed.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Tools Quick Reference

| Tool | When to use | Command |
|------|-------------|---------|
| `query` | Find code by concept | `gitnexus_query({query: "auth validation"})` |
| `context` | 360-degree view of one symbol | `gitnexus_context({name: "validateUser"})` |
| `impact` | Blast radius before editing | `gitnexus_impact({target: "X", direction: "upstream"})` |
| `detect_changes` | Pre-commit scope check | `gitnexus_detect_changes({scope: "staged"})` |
| `rename` | Safe multi-file rename | `gitnexus_rename({symbol_name: "old", new_name: "new", dry_run: true})` |
| `cypher` | Custom graph queries | `gitnexus_cypher({query: "MATCH ..."})` |

## Impact Risk Levels

| Depth | Meaning | Action |
|-------|---------|--------|
| d=1 | WILL BREAK — direct callers/importers | MUST update these |
| d=2 | LIKELY AFFECTED — indirect deps | Should test |
| d=3 | MAY NEED TESTING — transitive | Test if critical path |

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/cicada/context` | Codebase overview, check index freshness |
| `gitnexus://repo/cicada/clusters` | All functional areas |
| `gitnexus://repo/cicada/processes` | All execution flows |
| `gitnexus://repo/cicada/process/{name}` | Step-by-step execution trace |

## Self-Check Before Finishing

Before completing any code modification task, verify:
1. `gitnexus_impact` was run for all modified symbols
2. No HIGH/CRITICAL risk warnings were ignored
3. `gitnexus_detect_changes()` confirms changes match expected scope
4. All d=1 (WILL BREAK) dependents were updated

## Keeping the Index Fresh

After committing code changes, the GitNexus index becomes stale. Re-run analyze to update it:

```bash
npx gitnexus analyze
```

If the index previously included embeddings, preserve them by adding `--embeddings`:

```bash
npx gitnexus analyze --embeddings
```

To check whether embeddings exist, inspect `.gitnexus/meta.json` — the `stats.embeddings` field shows the count (0 means no embeddings). **Running analyze without `--embeddings` will delete any previously generated embeddings.**

> Claude Code users: A PostToolUse hook handles this automatically after `git commit` and `git merge`.

## CLI

- Re-index: `npx gitnexus analyze`
- Check freshness: `npx gitnexus status`
- Generate docs: `npx gitnexus wiki`

<!-- gitnexus:end -->

<!-- GSD:project-start source:PROJECT.md -->
## Project

**Cicada 重构 Phase 3-5**

Cicada（知了猴）是 OpenClaw 一键启动器社区版，基于 Flutter 3.29 + Dart 3.7 构建的跨平台桌面/移动应用。MVP 已于 2026-03-15 完成，包含 6 个内置 skills 和纯本地模式。当前目标是完成代码重构的剩余阶段，提升代码质量和可维护性。

**Core Value:** 测试覆盖率从 10.6% 提升到 80%，并将所有超过 800 行的大文件拆分为可维护的模块，确保重构不破坏现有功能。

### Constraints

- **Tech Stack**: Flutter 3.29 + Dart 3.7，不引入新框架
- **兼容性**: 重构不能破坏现有功能，所有现有测试必须继续通过
- **文件大小**: 所有文件 < 800 行
- **测试框架**: flutter_test + mockito + patrol，不引入其他测试框架
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- Dart ^3.7.0 - All application logic, services, UI (`lib/`)
- Kotlin - Android platform channel code (`android/app/`)
- C++ - Windows native runner (`windows/runner/`, `windows/CMakeLists.txt`)
- Swift/Objective-C - macOS native runner (`macos/Runner/`)
- Dart scripts - Build/packaging tooling (`scripts/*.dart`)
## Runtime
- Flutter SDK (latest stable, requires Dart SDK ^3.7.0)
- Node.js >= 22 (runtime dependency for OpenClaw CLI, not for the app itself)
- pub (Dart/Flutter package manager)
- Lockfile: `pubspec.lock` present
## Frameworks
- Flutter (Material Design) - Cross-platform UI framework
- flutter_riverpod ^2.6.1 - State management (`lib/providers/`, `lib/main.dart`)
- riverpod_annotation ^2.6.1 - Code generation for Riverpod providers
- flutter_test (SDK) - Widget and unit testing
- mockito ^5.4.4 - Mock generation for unit tests
- patrol ^3.13.1 - Multi-platform integration/E2E testing
- build_runner ^2.4.13 - Code generation runner (Riverpod generators)
- riverpod_generator ^2.6.2 - Generates `.g.dart` provider files
- custom_lint ^0.7.0 - Custom lint rules
- flutter_lints ^5.0.0 - Standard Flutter lint rules
## Key Dependencies
- http ^1.2.1 - HTTP client for all API calls (Anthropic, OpenAI, Google AI, Feishu, GitHub, ClawHub, Ollama)
- web_socket_channel ^3.0.2 - WebSocket connection to OpenClaw Gateway (`lib/services/gateway_service.dart`)
- shared_preferences ^2.3.3 - Persistent key-value storage for credentials (Feishu integration)
- path_provider ^2.1.5 - Platform-specific directory resolution (config, backups, bundled assets)
- fl_chart ^0.68.0 - Charts for token usage dashboard (`lib/pages/token_page.dart`)
- easy_stepper ^0.8.5 - Step indicator for setup wizard (`lib/pages/setup/`)
- flutter_settings_screens ^0.3.4 - Settings page components (`lib/pages/settings_page.dart`)
- window_manager ^0.4.3 - Desktop window management (size, title, centering) (`lib/main.dart`)
- webview_flutter ^4.10.0 - Embedded WebView for OpenClaw UI (`lib/pages/webui_page.dart`)
- url_launcher ^6.3.1 - Opening external URLs/links
- file_picker ^8.1.6 - File selection dialogs
- super_clipboard ^0.8.0 - Clipboard operations
- pub_semver ^2.1.4 - Semantic version comparison for updates (`lib/services/update_service.dart`, `lib/services/bundled_skill_service.dart`)
- async ^2.11.0 - Stream utilities (StreamGroup for merging install output streams)
- timeago ^3.7.0 - Human-readable relative timestamps
## Configuration
- Config file: `~/.openclaw/openclaw.json` - Provider credentials, proxy settings, default model
- Claude Code config: `~/.claude/settings.json` - Environment variables, MCP servers, hooks
- Claude Code API configs: `~/.claude/api-configs.json` - API provider management
- MCP config: `~/.openclaw/mcp.json` - MCP server configurations
- `.env` files: existence noted only (not read by the app directly)
- `pubspec.yaml` - Package manifest and Flutter asset declarations
- `analysis_options.yaml` - Dart analyzer config (uses `package:flutter_lints/flutter.yaml`, excludes `scripts/**`, `build/**`, `**/*.g.dart`)
- `windows/CMakeLists.txt` - Windows native build
- `android/build.gradle.kts` - Android build config
- `assets/presets/models-cn.json` - Chinese region model presets
- `assets/presets/models-intl.json` - International model presets
- `assets/presets/mirrors.json` - npm/Node.js/pip/GitHub mirror URLs for China deployment
- `assets/presets/skill-sources.json` - Skill source configuration
- `assets/bundled/manifest.json` - Bundled Node.js v22.14.0 + OpenClaw v0.1.8 offline installer manifest
- `assets/bundled_skills/index.json` - 6 bundled skills (code-review, doc-gen, test-helper, git-helper, refactor, i18n)
## Platform Requirements
- Flutter SDK (Dart ^3.7.0)
- For code generation: `dart run build_runner build`
- Platform-specific toolchains: Xcode (macOS), Visual Studio (Windows), Android SDK (Android)
- Windows: `.exe` or `.msix` installer (self-update via GitHub Releases)
- macOS: `.app` bundle (Homebrew Node.js, login shell PATH resolution via `ShellEnv`)
- Linux: Standard Flutter Linux build
- Android: APK with Termux dependency for Node.js runtime (communicates via MethodChannel Intent bridge)
- External runtime dependency: Node.js >= 22 (can be bundled offline or installed online)
- External CLI dependency: `openclaw` npm package (can be bundled offline or installed online)
- Optional: `claude` CLI (Claude Code), `ollama` CLI, VS Code with Claude Code extension
- Desktop: Windows, macOS, Linux (direct process execution)
- Mobile: Android (via Termux bridge), iOS (limited, no Termux)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Patterns
- Use `snake_case.dart` for all Dart files: `config_service.dart`, `mcp_server.dart`, `key_masker.dart`
- Page files: `{feature}_page.dart` in `lib/pages/` (e.g., `dashboard_page.dart`, `settings_page.dart`)
- Service files: `{domain}_service.dart` in `lib/services/` (e.g., `mcp_service.dart`, `proxy_service.dart`)
- Model files: `{entity}.dart` in `lib/models/` (e.g., `mcp_server.dart`, `provider.dart`, `diagnostic.dart`)
- Widget files: `{widget_name}.dart` in `lib/app/widgets/` or `lib/widgets/` (e.g., `hud_panel.dart`, `stat_card.dart`)
- Test files: `{source_name}_test.dart` mirroring source structure (e.g., `test/utils/key_masker_test.dart`)
- Use `PascalCase` for all classes: `McpService`, `ConfigRepository`, `HudPanel`, `SetupStateData`
- Widget classes match file name in PascalCase: `status_badge.dart` -> `StatusBadge`
- Private helper classes prefixed with underscore: `_HudBorderPainter`, `_HudTitle`, `_HomePageState`, `_NavItem`
- Enums use `PascalCase` names with `camelCase` values: `enum McpTransport { stdio, sse }`, `enum StatusType { online, offline, warning, loading }`
- Use `camelCase` for all functions and methods: `readConfig()`, `maskApiKey()`, `detectEnvironment()`
- Private methods prefixed with underscore: `_readRaw()`, `_writeRaw()`, `_setFilePermissions()`
- Boolean getters use `is` prefix: `isSuccess`, `isFailure`, `isDesktop`, `isMobile`
- Factory constructors use descriptive names: `McpServer.fromJson()`, `SetupStateData.initial()`
- Use `camelCase` for all variables and parameters: `configDir`, `selectedMirror`, `nodeInstalled`
- Private static fields prefixed with underscore: `_cachedConfigDir`, `_openclawPath`
- Constants use `camelCase` (Dart convention): `const background = Color(0xFF0B0F14)`
- Sealed classes for algebraic types: `sealed class AppError`, `sealed class Result<T>`
- Named constructors for error variants: `ConfigError.readFailed()`, `NetworkError.timeout()`
- Record types for multi-value returns: `({bool installed, bool sufficient, int? major, String raw})`
## Code Style
- Dart standard formatting (dart format)
- 2-space indentation (Dart default)
- Trailing commas on multi-line parameter lists and collections
- Single quotes for strings (Dart convention)
- `package:flutter_lints` v5.0.0 via `analysis_options.yaml`
- Includes `package:flutter_lints/flutter.yaml` base ruleset
- Excludes from analysis: `scripts/**`, `build/**`, `**/*.g.dart`
- No custom lint rules enabled beyond the base set
## Import Organization
- Use relative imports within the project (not `package:cicada/...`)
- Example from `lib/services/mcp_service.dart`:
- None. Standard relative imports throughout.
- Used sparingly for grouping related exports:
## Error Handling
- `ConfigError` - file I/O and parse errors (named constructors: `.readFailed()`, `.writeFailed()`, `.parseFailed()`, `.notFound()`)
- `NetworkError` - connectivity issues (`.timeout()`, `.unreachable()`, `.proxyFailed()`)
- `AuthError` - API key issues (`.invalidKey()`, `.expired()`, `.rateLimited()`)
- `InstallError` - installation failures (`.nodeMissing()`, `.openclawFailed()`, `.extractFailed()`, `.permissionDenied()`)
- `ServiceError` - runtime service issues (`.notRunning()`, `.startFailed()`, `.connectionLost()`)
- `ValidationError` - input validation (`.emptyField()`, `.invalidFormat()`, `.invalidUrl()`)
## Logging
- Installation progress logged via state management: `state.logLines` list in `SetupStateData`
- Diagnostic output uses structured `DiagnosticFinding` objects with level/title/summary
- No centralized logger; services return structured results rather than logging
## Comments
- `///` doc comments on all public classes and their purpose
- `///` doc comments on public methods explaining behavior
- Inline `//` comments for section headers within long methods (e.g., `// Layer 1: Environment checks`)
- Chinese comments for user-facing context (e.g., `// 步骤指示器（替换自定义 StepCard）`)
## Function Design
- `Result<T>` for fallible operations
- `Future<T>` for async operations
- Dart 3 records for multi-value returns: `Future<(bool, String)> testConnection(...)`
- Named record fields for complex returns: `({bool installed, bool sufficient, int? major, String raw})`
## Module Design
- Barrel files for grouped exports in `lib/app/theme/theme.dart` and `lib/app/widgets/widgets.dart`
- No barrel file at `lib/` root; imports are explicit per-file
- Services use static methods exclusively (no instance state): `ConfigService`, `McpService`, `InstallerService`, `DiagnosticService`
- Private constructor pattern for utility classes: `CicadaColors._()`, `CicadaTheme._()`, `PlatformInfo._()`
- Repository pattern for data layer: `ConfigRepository` uses instance methods returning `Result<T>`
- Immutable data classes with `const` constructors
- `copyWith()` method for state updates (manually written, not code-generated)
- `fromJson()` factory constructor + `toJson()` method for serialization
- No code generation for models (except `setup_state.g.dart` for Riverpod)
- Riverpod for reactive state: `flutter_riverpod` + `riverpod_annotation`
- Providers defined in `lib/providers/config_provider.dart`
- `@riverpod` annotation with code generation for complex state (`lib/pages/setup/logic/setup_state.dart`)
- Simple `Provider`, `FutureProvider` for read-only data
- `Notifier` pattern (via `@riverpod`) for mutable state with methods
- `StatelessWidget` for pure display widgets (`HudPanel`, `CicadaApp`)
- `StatefulWidget` with `SingleTickerProviderStateMixin` for animated widgets (`StatusBadge`)
- `StatefulWidget` with `Timer` for polling state (`HomePage`)
- `const` constructors on all widgets where possible
- `super.key` parameter style (Dart 3)
## UI/Theme Conventions
- Centralized semantic colors in `lib/app/theme/cicada_colors.dart` (static const fields)
- Use semantic names: `CicadaColors.accent`, `CicadaColors.energy`, `CicadaColors.ok`, `CicadaColors.alert`
- Never use raw `Color()` values in widget code; always reference `CicadaColors.*`
- Single dark theme defined in `lib/app/theme/cicada_theme.dart`
- Material 3 enabled (`useMaterial3: true`)
- Custom `CardTheme`, `InputDecorationTheme`, `FilledButtonTheme`, `OutlinedButtonTheme`, `ChipTheme`
- UI strings are hardcoded in Chinese (Simplified)
- Error messages in `AppError` subclasses are Chinese
- No i18n framework in use
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern Overview
- Flutter desktop+mobile app acting as a GUI launcher/manager for the external `openclaw` CLI tool
- Layered separation: core → data → models → services → providers → pages/widgets
- Services are stateless static classes that shell out to CLI tools (`openclaw`, `node`, `claude`) or make HTTP calls
- State management via Riverpod (flutter_riverpod + riverpod_annotation with code generation)
- Sealed class Result type for error handling in core/data layers
- Platform-adaptive: desktop runs processes directly, Android delegates to Termux via MethodChannel
## Layers
- Purpose: Foundation types and platform abstractions shared across all layers
- Location: `lib/core/`
- Contains: `Result<T>` sealed type (`lib/core/result.dart`), `AppError` sealed hierarchy (`lib/core/app_error.dart`), `JsonFile` atomic I/O (`lib/core/json_file.dart`), `PlatformInfo` (`lib/core/platform/platform_info.dart`), `ShellEnv` macOS PATH resolver (`lib/core/platform/shell_env.dart`)
- Depends on: dart:io only
- Used by: data, services
- Purpose: Data access and persistence — reads/writes JSON config files on disk
- Location: `lib/data/`
- Contains: `ConfigRepository` (`lib/data/config_repository.dart`) for `~/.openclaw/openclaw.json`, `McpDirectory` (`lib/data/mcp_directory.dart`) curated MCP catalog, `McpPresets` (`lib/data/mcp_presets.dart`) preset templates, `ClawHubCatalog` (`lib/data/clawhub_catalog.dart`) skill catalog
- Depends on: core (Result, AppError, PlatformInfo)
- Used by: services, providers
- Purpose: Plain data classes with JSON serialization
- Location: `lib/models/`
- Contains: `McpServer` + `McpPreset` (`lib/models/mcp_server.dart`), `ProviderConfig` + `ModelInfo` (`lib/models/provider.dart`), `ProxyConfig` (`lib/models/proxy_config.dart`), `Skill` (`lib/models/skill.dart`), `DashboardStats` + `RecentSession` + `AttentionItem` (`lib/models/dashboard_stats.dart`), `DiagnosticReport` + `TokenRecord` (`lib/models/diagnostic.dart`)
- Depends on: nothing (pure data)
- Used by: services, providers, pages
- Purpose: Business logic — CLI invocation, HTTP API calls, file management
- Location: `lib/services/`
- Contains: 15 service classes, all using static methods (no instances)
- Depends on: core, data, models
- Used by: providers, pages (directly in some cases)
- Purpose: Riverpod state management — bridges services to UI
- Location: `lib/providers/config_provider.dart`
- Contains: `configRepositoryProvider`, `configDataProvider`, `configuredProvidersProvider`, `mcpServersProvider`, `mcpEnabledCountProvider`, `proxyConfigProvider`
- Depends on: data (ConfigRepository), services (McpService, ProxyService), models
- Used by: pages (via `ref.watch`)
- Purpose: Full-screen UI views, one per navigation destination
- Location: `lib/pages/`
- Contains: 16 page widgets + setup sub-module (`lib/pages/setup/`)
- Depends on: services (direct calls), providers (Riverpod), models, app/widgets
- Used by: `HomePage` router (`lib/pages/home_page.dart`)
- Purpose: Shared theme definition and reusable HUD-style widgets
- Location: `lib/app/theme/` and `lib/app/widgets/`
- Contains: `CicadaColors` (`lib/app/theme/cicada_colors.dart`), `CicadaTheme` (`lib/app/theme/cicada_theme.dart`), `HudPanel`, `ScanLineOverlay`, `StatusBadge`, `TerminalDialog`
- Depends on: Flutter framework only
- Used by: pages
- Purpose: Reusable widgets specific to the dashboard page
- Location: `lib/widgets/`
- Contains: `AttentionPanel`, `QuickActionButton`, `RecentSessionsList`, `StatCard`, `TerminalOutput`
- Depends on: models, app/theme
- Used by: `DashboardPage`
## Data Flow
- Riverpod `FutureProvider` for async data (config, MCP servers, proxy)
- Riverpod `@riverpod` annotation with code generation for `SetupState` (`lib/pages/setup/logic/setup_state.dart`)
- Most pages use local `StatefulWidget` state for UI-only concerns
- `HomePage` manages navigation index and service status polling via `Timer.periodic`
## Key Abstractions
- Purpose: Type-safe error handling without exceptions
- Location: `lib/core/result.dart`
- Pattern: `Success<T>` | `Failure<T>` with `map`, `flatMap`, `onSuccess`, `onFailure`
- Used in: `ConfigRepository`, `McpService`, `SkillInstallerService`, `ProxyService`
- Purpose: Typed error categories with Chinese user-facing messages
- Location: `lib/core/app_error.dart`
- Subtypes: `ConfigError`, `NetworkError`, `AuthError`, `InstallError`, `ServiceError`, `ValidationError`
- Each has named constructors for common cases (e.g., `ConfigError.readFailed()`)
- Purpose: Platform detection for conditional behavior
- Location: `lib/core/platform/platform_info.dart`
- Key properties: `isDesktop`, `isMobile`, `canRunProcesses`, `needsTermux`
- Purpose: Android-only bridge to execute commands inside Termux via Intent
- Location: `lib/services/termux_bridge.dart`
- Pattern: `MethodChannel` → Kotlin → Android Intent → Termux RUN_COMMAND
## Entry Points
- Location: `lib/main.dart`
- Triggers: App launch
- Responsibilities: Initialize Flutter binding, configure window (desktop), wrap app in `ProviderScope`, launch `CicadaApp` → `HomePage`
- Location: `lib/pages/home_page.dart`
- Triggers: Navigation selection (sidebar on desktop, bottom nav + drawer on mobile)
- Responsibilities: Manages 16 page destinations via index-based switching, polls gateway status every 5 seconds, responsive layout (sidebar >800px, bottom nav otherwise)
- `android/app/src/main/kotlin/com/example/cicada/MainActivity.kt` — Flutter activity + MethodChannel handler for Termux bridge
- `android/app/src/main/kotlin/com/example/cicada/CicadaAccessibilityService.kt` — Accessibility service for auto-configuring Termux
## Error Handling
- Core/data layer returns `Result<T>` — never throws
- Services return `Result<T>` for operations that can fail, or catch exceptions and return defaults (e.g., empty lists)
- UI code uses `.dataOrNull ?? {}` for graceful degradation
- `try/catch` with empty catch blocks in many services for non-critical failures (silent fallback)
- `AppError` subtypes carry Chinese-language user messages and error codes
## Cross-Cutting Concerns
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
