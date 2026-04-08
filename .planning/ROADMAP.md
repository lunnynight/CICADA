# Roadmap: Cicada 重构 Phase 3-5

**Created:** 2026-04-08
**Granularity:** Coarse
**Coverage:** 22/22 requirements mapped

## Phases

- [x] **Phase 1: 服务层单元测试** - 为所有服务层公开方法建立单元测试覆盖
- [ ] **Phase 2: Widget 与集成测试** - 完成组件测试和 Patrol 集成测试框架
- [ ] **Phase 3: 收尾与达标** - 修复导航 TODO、拆分大文件、达成 80% 覆盖率目标

## Phase Details

### Phase 1: 服务层单元测试
**Goal**: 所有服务层公开方法均有可运行的单元测试，mock 策略确立
**Depends on**: Nothing (first phase)
**Requirements**: TEST-01, TEST-02, TEST-03, TEST-04, TEST-05, TEST-06, TEST-07, TEST-08, TEST-09
**Success Criteria** (what must be TRUE):
  1. `flutter test test/services/` 全部通过，无跳过用例
  2. DiagnosticService、TokenService、IntegrationService、GatewayService、InstallerService、ConfigService、SkillDiscoveryService、SkillInstallerService、UpdateService、McpService、ProxyService 每个服务至少有一个测试文件
  3. static 方法的 mock 策略已确立并在测试中一致使用（包装类或依赖注入）
  4. 所有新增测试在 CI 中可重复运行（不依赖外部 CLI 工具的真实调用）
**Plans**: 3 plans

Plans:
- [x] 01-01-PLAN.md — Mock infrastructure + TokenService pure tests + ConfigService CRUD tests (Wave 1)
- [x] 01-02-PLAN.md — McpService, ProxyService, InstallerService, DiagnosticService tests (Wave 2)
- [x] 01-03-PLAN.md — SkillInstallerService, SkillDiscoveryService, UpdateService, GatewayService tests (Wave 2)

### Phase 2: Widget 与集成测试
**Goal**: 核心 UI 组件有 widget 测试，Patrol 集成测试框架可运行完整安装流程
**Depends on**: Phase 1
**Requirements**: WDGT-01, WDGT-02, WDGT-03, WDGT-04, WDGT-05, INTG-01, INTG-02
**Success Criteria** (what must be TRUE):
  1. `flutter test test/widgets/` 全部通过，覆盖 EnvironmentDetector、InstallationPanel、SetupPageNew、StatCard、AttentionPanel、QuickActionButton、HomePage
  2. `flutter test integration_test/` 可执行，Patrol 框架配置完成无报错
  3. 完整安装流程端到端测试可运行并通过（或在无环境时优雅跳过）
  4. HomePage 导航切换测试验证各 tab 正确渲染
**Plans**: 3 plans

Plans:
- [x] 02-01-PLAN.md — Dashboard widgets (StatCard, AttentionPanel, QuickActionButton) + Setup sub-widgets (EnvironmentDetector, InstallationPanel) tests (Wave 1)
- [x] 02-02-PLAN.md — SetupPage full page render + HomePage navigation switching tests (Wave 1)
- [x] 02-03-PLAN.md — Patrol integration test framework setup + smoke test (Wave 1)

### Phase 3: 收尾与达标
**Goal**: 导航 TODO 全部实现，大文件拆分完成，整体覆盖率达到 80%
**Depends on**: Phase 2
**Requirements**: NAV-01, NAV-02, NAV-03, SPLIT-01, SPLIT-02, COV-01
**Success Criteria** (what must be TRUE):
  1. diagnostic_page.dart 中 navigate_setup、navigate_models、navigate_dashboard 三处 TODO 全部替换为可用导航，手动点击可跳转
  2. settings_page.dart 拆分后所有子文件均 < 800 行，原有功能不变
  3. skills_page.dart 拆分后所有子文件均 < 800 行，原有功能不变
  4. `flutter test --coverage` 报告整体覆盖率 >= 80%
  5. 所有既有测试（含 Phase 1、2 新增）继续通过，无回归
**Plans**: TBD

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. 服务层单元测试 | 3/3 | Complete | 2026-04-08 |
| 2. Widget 与集成测试 | 3/3 | Complete | 2026-04-08 |
| 3. 收尾与达标 | 0/0 | Not started | - |

---
*Roadmap created: 2026-04-08*
