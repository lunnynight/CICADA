# Cicada 重构 Phase 3-5

## What This Is

Cicada（知了猴）是 OpenClaw 一键启动器社区版，基于 Flutter 3.29 + Dart 3.7 构建的跨平台桌面/移动应用。MVP 已于 2026-03-15 完成，包含 6 个内置 skills 和纯本地模式。当前目标是完成代码重构的剩余阶段，提升代码质量和可维护性。

## Core Value

测试覆盖率从 10.6% 提升到 80%，并将所有超过 800 行的大文件拆分为可维护的模块，确保重构不破坏现有功能。

## Requirements

### Validated

- ✓ MVP 功能集完整（Dashboard、Setup Wizard、Model Config、Skills Store、OTA Update、Dark Theme） — MVP v0.1.0
- ✓ 6 个内置 skills（code-review, doc-gen, test-helper, git-helper, refactor, i18n） — MVP
- ✓ 纯本地模式（移除远程依赖） — MVP
- ✓ Windows 构建成功 — MVP
- ✓ macOS 构建成功 — MVP
- ✓ setup_page.dart 拆分完成（1112→320 行，减少 71%） — 重构 Phase 2
- ✓ Riverpod 状态管理引入 — 重构 Phase 1
- ✓ 成熟组件库引入（easy_stepper, flutter_settings_screens, patrol, mockito） — 重构 Phase 1
- ✓ 基础测试通过（15/15） — 重构 Phase 2
- ✓ 服务层单元测试（DiagnosticService, TokenService, IntegrationService, GatewayService, InstallerService） — Validated in Phase 1: 服务层单元测试
- ✓ Widget 测试（EnvironmentDetector, InstallationPanel, SetupPageNew） — Validated in Phase 2: Widget 与集成测试
- ✓ 集成测试（Patrol 框架） — Validated in Phase 2: Widget 与集成测试

### Active

- [ ] 测试覆盖率达到 80%
- [ ] diagnostic_page.dart 导航 TODO 完成（navigate_setup, navigate_models, navigate_dashboard）
- [ ] settings_page.dart 拆分（当前 1045 行，目标 <800 行）
- [ ] skills_page.dart 拆分（当前 930 行，目标 <800 行）

### Out of Scope

- 新功能开发 — 本轮纯重构，不加功能
- Android 构建测试 — 延后处理
- UI 重新设计 — 保持现有 UI 不变
- 性能优化 — 不在本轮范围内

## Context

- 测试覆盖率当前 10.6%（459/4329 行），目标 80%
- 已有 test/setup_state_test.dart 包含 11 个测试用例
- 使用 mockito 做 mock，patrol 做集成测试
- 服务层全部是 static 方法，依赖外部 CLI 工具（openclaw, node）
- 大文件：settings_page.dart (1045行), skills_page.dart (930行)
- diagnostic_page.dart 行 378-385 有未实现的导航 TODO
- 架构：feature-based layered（core → data → models → services → providers → pages）

## Constraints

- **Tech Stack**: Flutter 3.29 + Dart 3.7，不引入新框架
- **兼容性**: 重构不能破坏现有功能，所有现有测试必须继续通过
- **文件大小**: 所有文件 < 800 行
- **测试框架**: flutter_test + mockito + patrol，不引入其他测试框架

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| 先补测试再拆文件 | 有测试保障后拆文件更安全，能及时发现回归 | — Pending |
| 不加新功能 | 聚焦代码质量，避免范围蔓延 | — Pending |
| 服务层 static 方法需要 mock 策略 | static 方法不好直接 mock，需要包装或使用依赖注入 | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-08 after Phase 2 (Widget 与集成测试) completion*
