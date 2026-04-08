# Phase 2: Widget 与集成测试 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-08
**Phase:** 02-widget
**Areas discussed:** Widget 测试深度, Patrol 集成测试范围, 服务依赖处理, 测试目录结构

---

## Widget 测试深度

| Option | Description | Selected |
|--------|-------------|----------|
| Smoke 级别 | 只验证组件能渲染不报错，找到关键 widget 存在即可 | |
| 交互级别 | 验证渲染 + 核心交互（按钮点击、输入框、状态切换），每个组件 5-10 个测试 | ✓ |
| 全面级别 | 渲染 + 交互 + 边界情况（空数据、错误状态、极长文本），每个组件 10-20 个测试 | |

**User's choice:** 交互级别
**Notes:** 平衡覆盖率和工作量

---

## Patrol 集成测试范围

| Option | Description | Selected |
|--------|-------------|----------|
| 框架就绪验证 | 只验证 Patrol 配置正确、能启动 test runner、一个最简 smoke test 通过 | ✓ |
| UI 流转测试 | Mock 掉 CLI 调用，验证安装向导 UI 流转 | |
| 真实端到端测试 | 需要真实 Node.js + OpenClaw 环境 | |

**User's choice:** 框架就绪验证
**Notes:** Windows CI 无 Node.js/OpenClaw 环境，先确保框架可用

---

## 服务依赖处理

| Option | Description | Selected |
|--------|-------------|----------|
| Riverpod overrides | 用 ProviderScope overrides 注入 fake service，与架构一致 | ✓ |
| Mockito mock | 用 mockito 生成 mock 类，需要先包装 static 方法 | |
| 混合方案 | Riverpod 管理的用 overrides，直接 static 调用的用 mockito | |

**User's choice:** Riverpod overrides
**Notes:** 与生产代码的依赖注入方式一致，避免包装 static 方法的额外成本

---

## 测试目录结构

| Option | Description | Selected |
|--------|-------------|----------|
| test/widgets/ + integration_test/ | 与 ROADMAP success criteria 一致 | ✓ |
| test/pages/ + integration_test/ | 按页面分目录，更细粒度 | |
| test/unit\|widget\|integration/ | 按类型分，需要移动现有文件 | |

**User's choice:** test/widgets/ + integration_test/
**Notes:** 与 ROADMAP 的 success criteria 路径一致

---

## Claude's Discretion

- 每个组件的具体测试用例设计
- Patrol 配置文件的具体内容
- fake service 的实现细节

## Deferred Ideas

None
