# Phase 2: Widget 与集成测试 - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning

<domain>
## Phase Boundary

为 7 个核心 UI 组件编写 widget 测试，配置 Patrol 集成测试框架并验证就绪状态。不涉及新功能开发、文件拆分或覆盖率达标（Phase 3 范围）。

</domain>

<decisions>
## Implementation Decisions

### Widget 测试深度
- **D-01:** 交互级别测试 — 验证渲染 + 核心交互（按钮点击触发回调、输入框接受文本、状态切换正确显示），每个组件 5-10 个测试
- **D-02:** 不测边界情况（空数据、极长文本、loading 状态），留给 Phase 3 覆盖率冲刺时补充

### Patrol 集成测试范围
- **D-03:** 框架就绪验证 — 只验证 Patrol 配置正确、能启动 test runner、一个最简 smoke test 通过
- **D-04:** 不依赖真实 Node.js/OpenClaw 环境，不做完整安装流程端到端测试
- **D-05:** CI 上能跑通即可，无环境时优雅跳过

### 服务依赖隔离
- **D-06:** 使用 Riverpod ProviderScope overrides 注入 fake service，与生产代码的依赖注入方式一致
- **D-07:** 不用 mockito mock static 方法（避免包装成本），通过 Riverpod provider 层隔离

### 测试目录结构
- **D-08:** Widget 测试放 `test/widgets/`，集成测试放 `integration_test/`
- **D-09:** 与 ROADMAP success criteria 一致（`flutter test test/widgets/` 和 `flutter test integration_test/`）

### Claude's Discretion
- 每个组件的具体测试用例设计
- Patrol 配置文件的具体内容
- fake service 的实现细节

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 测试基础设施（Phase 1 产出）
- `.planning/phases/01-service-unit-tests/01-01-SUMMARY.md` — Mock 基础设施和 mock 策略说明
- `test/services/helpers/fake_process_runner.dart` — ProcessRunner 接口模式
- `test/services/helpers/mock_http_client.dart` — MockClient 模式

### 待测组件
- `lib/pages/setup/widgets/environment_detector.dart` — EnvironmentDetector 组件
- `lib/pages/setup/widgets/installation_panel.dart` — InstallationPanel 组件
- `lib/pages/setup_page.dart` — SetupPageNew 页面
- `lib/widgets/stat_card.dart` — StatCard 组件
- `lib/widgets/attention_panel.dart` — AttentionPanel 组件（如存在）
- `lib/widgets/quick_action_button.dart` — QuickActionButton 组件（如存在）
- `lib/pages/home_page.dart` — HomePage 导航切换

### 状态管理
- `lib/providers/config_provider.dart` — Riverpod providers（override 目标）
- `lib/pages/setup/logic/setup_state.dart` — SetupState Riverpod 状态

### 项目配置
- `pubspec.yaml` — patrol ^3.13.1 已声明为 dev_dependency

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/services/helpers/` — Phase 1 建立的 mock 基础设施（FakeProcessRunner、MockClient）
- `test/widget_test.dart` — 现有 smoke test，可作为 widget 测试模板参考
- `test/setup_state_test.dart` — Riverpod 状态测试模式参考

### Established Patterns
- 服务层全部使用 static 方法，通过 Riverpod provider 暴露给 UI
- Widget 使用 `ref.watch()` 消费 provider 数据
- HomePage 使用 `Timer.periodic` 轮询 gateway 状态

### Integration Points
- Widget 测试需要 `ProviderScope` 包裹，override 相关 provider
- Patrol 需要 `integration_test/` 目录和 `patrol` 配置
- 现有 CI（GitHub Actions）需要能运行新增测试

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-widget*
*Context gathered: 2026-04-08*
