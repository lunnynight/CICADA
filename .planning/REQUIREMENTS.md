# Requirements: Cicada 重构 Phase 3-5

**Defined:** 2026-04-08
**Core Value:** 测试覆盖率从 10.6% 提升到 80%，并将所有超过 800 行的大文件拆分为可维护的模块，确保重构不破坏现有功能。

## v1 Requirements

### 服务层单元测试

- [x] **TEST-01**: DiagnosticService 所有公开方法有单元测试覆盖
- [x] **TEST-02**: TokenService 所有公开方法有单元测试覆盖
- [ ] **TEST-03**: IntegrationService 所有公开方法有单元测试覆盖
- [ ] **TEST-04**: GatewayService 所有公开方法有单元测试覆盖
- [ ] **TEST-05**: InstallerService 所有公开方法有单元测试覆盖
- [x] **TEST-06**: ConfigService 所有公开方法有单元测试覆盖
- [ ] **TEST-07**: SkillDiscoveryService / SkillInstallerService 所有公开方法有单元测试覆盖
- [ ] **TEST-08**: UpdateService 所有公开方法有单元测试覆盖
- [x] **TEST-09**: McpService / ProxyService 所有公开方法有单元测试覆盖

### Widget 测试

- [ ] **WDGT-01**: EnvironmentDetector 组件渲染和交互测试
- [ ] **WDGT-02**: InstallationPanel 组件渲染和交互测试
- [ ] **WDGT-03**: SetupPageNew 页面完整渲染测试
- [ ] **WDGT-04**: DashboardPage 核心 widget（StatCard, AttentionPanel, QuickActionButton）测试
- [ ] **WDGT-05**: HomePage 导航切换测试

### 集成测试

- [ ] **INTG-01**: Patrol 集成测试框架配置完成并可运行
- [ ] **INTG-02**: 完整安装流程端到端测试

### 覆盖率

- [ ] **COV-01**: 整体测试覆盖率达到 80%

### 导航修复

- [ ] **NAV-01**: diagnostic_page.dart navigate_setup 导航实现
- [ ] **NAV-02**: diagnostic_page.dart navigate_models 导航实现
- [ ] **NAV-03**: diagnostic_page.dart navigate_dashboard 导航实现

### 文件拆分

- [ ] **SPLIT-01**: settings_page.dart 拆分为多个文件，每个 < 800 行
- [ ] **SPLIT-02**: skills_page.dart 拆分为多个文件，每个 < 800 行

## v2 Requirements

### 进阶测试

- **ADV-01**: 多端构建测试（Windows, macOS, Android）
- **ADV-02**: 性能回归测试
- **ADV-03**: Patrol 跨页面导航集成测试

### 进阶重构

- **REF-01**: 服务层 static 方法改为依赖注入模式
- **REF-02**: 删除旧的 setup_page.dart（确认 setup_page_new.dart 完全替代后）

## Out of Scope

| Feature | Reason |
|---------|--------|
| 新功能开发 | 本轮纯重构，不加功能 |
| Android 构建测试 | 延后处理，当前聚焦代码质量 |
| UI 重新设计 | 保持现有 UI 不变 |
| 性能优化 | 不在本轮范围内 |
| 依赖升级 | 避免引入不稳定因素 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TEST-01 | Phase 1 | Complete |
| TEST-02 | Phase 1 | Complete |
| TEST-03 | Phase 1 | Pending |
| TEST-04 | Phase 1 | Pending |
| TEST-05 | Phase 1 | Pending |
| TEST-06 | Phase 1 | Complete |
| TEST-07 | Phase 1 | Pending |
| TEST-08 | Phase 1 | Pending |
| TEST-09 | Phase 1 | Complete |
| WDGT-01 | Phase 2 | Pending |
| WDGT-02 | Phase 2 | Pending |
| WDGT-03 | Phase 2 | Pending |
| WDGT-04 | Phase 2 | Pending |
| WDGT-05 | Phase 2 | Pending |
| INTG-01 | Phase 2 | Pending |
| INTG-02 | Phase 2 | Pending |
| COV-01 | Phase 3 | Pending |
| NAV-01 | Phase 3 | Pending |
| NAV-02 | Phase 3 | Pending |
| NAV-03 | Phase 3 | Pending |
| SPLIT-01 | Phase 3 | Pending |
| SPLIT-02 | Phase 3 | Pending |

**Coverage:**
- v1 requirements: 22 total
- Mapped to phases: 22
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-08*
*Last updated: 2026-04-08 after roadmap creation*
