# Phase 3: 收尾与达标 - Context

**Gathered:** 2026-04-08
**Status:** Ready for planning

<domain>
## Phase Boundary

完成导航修复验证、大文件拆分、测试覆盖率提升到 80%。纯重构收尾阶段，不加新功能。

</domain>

<decisions>
## Implementation Decisions

### 导航修复 (NAV-01, NAV-02, NAV-03)
- **D-01:** 导航代码已实现（diagnostic_page.dart:377-391，onNavigate 回调已在 HomePage:236 接入）。本阶段任务是审计导航索引（1=setup, 7=models, 0=dashboard）是否与 HomePage 实际页面顺序匹配，然后补充 widget 测试验证导航行为。
- **D-02:** 如果索引不匹配，修正索引值。不需要重写导航机制。

### settings_page.dart 拆分 (SPLIT-01)
- **D-03:** 提取对话框（update risk dialog ~63行, backup confirm dialog ~221行, update banner ~95行）到独立文件 `settings_dialogs.dart`
- **D-04:** 提取代理设置区域（proxy section, 740-963, ~224行）到独立文件 `settings_proxy_section.dart`
- **D-05:** 提取后主文件预计 ~689 行，满足 <800 行要求。保留 OpenClaw 配置、镜像源、集成管理、关于、数据管理在主文件中。

### skills_page.dart 拆分 (SPLIT-02)
- **D-06:** 提取 _SkillCard（617-877, ~260行）+ _Badge（878-903, ~25行）+ _DiagonalStripesPainter + _CornerBracketsPainter（557-616, ~60行）到独立文件 `skill_card.dart`
- **D-07:** 提取后主文件预计 ~558 行，满足 <800 行要求。

### 覆盖率策略 (COV-01)
- **D-08:** 自底向上策略：优先测试 models → core → data → remaining services → providers。页面层不新增测试（Phase 2 已覆盖核心页面）。
- **D-09:** 每个 plan 执行后运行 `flutter test --coverage` 测量覆盖率，根据进度调整后续 plan。如果提前达到 80% 可以停止。
- **D-10:** 目标从 10.6% 提升到 >= 80%。

### Claude's Discretion
- 具体测试用例设计和断言策略
- models/core/data 层的测试优先级排序
- 拆分后文件的具体命名（上述为建议名）
- 覆盖率不足时的补充测试选择

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 待拆分文件
- `lib/pages/settings_page.dart` — 1292 行，拆分目标文件
- `lib/pages/skills_page.dart` — 903 行，拆分目标文件

### 导航相关
- `lib/pages/diagnostic_page.dart` — 导航实现在 377-391 行，onNavigate 回调
- `lib/pages/home_page.dart` — 页面路由映射（_navigateTo, 页面索引定义）

### 测试基础设施（Phase 1-2 产出）
- `test/services/` — Phase 1 服务层测试（101 tests）
- `test/widgets/` — Phase 2 widget 测试
- `test/services/helpers/` — mock_http_client.dart, fake_process_runner.dart

### 项目配置
- `pubspec.yaml` — 依赖和测试框架配置
- `analysis_options.yaml` — lint 规则

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/services/helpers/mock_http_client.dart` — MockClient via mockito，可复用于需要 HTTP mock 的测试
- `test/services/helpers/fake_process_runner.dart` — FakeProcessRunner，可复用于需要进程 mock 的测试
- Phase 2 的 ProviderScope + overrideWith 模式可复用于 provider 测试

### Established Patterns
- 服务层全部 static 方法，Phase 1 已建立 mock 策略（包装或依赖注入）
- Widget 测试使用 `testWidgets` + `pumpWidget` + ProviderScope
- 文件拆分先例：setup_page.dart 已在重构 Phase 2 从 1112→320 行拆分成功

### Integration Points
- settings_page 拆分后的子文件需要访问 `_SettingsPageState` 的状态变量
- skills_page 拆分后 _SkillCard 需要接收回调参数（原来通过闭包访问父 state）
- 导航索引与 HomePage 的 `_buildPage(int index)` switch 语句绑定

</code_context>

<specifics>
## Specific Ideas

- setup_page.dart 拆分是成功先例（1112→320 行），可参考其拆分模式
- 导航索引审计需要对照 HomePage 的完整 switch case 列表

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-wrap-up*
*Context gathered: 2026-04-08*
