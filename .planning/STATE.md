# State: Cicada 重构 Phase 3-5

**Last updated:** 2026-04-08
**Session:** Initial roadmap creation

## Project Reference

**Core Value:** 测试覆盖率从 10.6% 提升到 80%，并将所有超过 800 行的大文件拆分为可维护的模块，确保重构不破坏现有功能。

**Current Focus:** Phase 1 — 服务层单元测试

## Current Position

**Phase:** 1 — 服务层单元测试
**Plan:** None started
**Status:** Not started

```
Progress: [----------] 0%
Phase 1 [          ] → Phase 2 [          ] → Phase 3 [          ]
```

## Performance Metrics

| Metric | Baseline | Current | Target |
|--------|----------|---------|--------|
| Test coverage | 10.6% | 10.6% | 80% |
| Passing tests | 15 | 15 | TBD |
| Files > 800 lines | 2 | 2 | 0 |
| Nav TODOs | 3 | 3 | 0 |

## Accumulated Context

### Key Decisions

- 先补测试再拆文件 — 有测试保障后拆文件更安全，能及时发现回归
- static 方法 mock 策略待确立 — 服务层全部是 static 方法，需要包装类或依赖注入

### Known Constraints

- 不引入新框架，仅使用 flutter_test + mockito + patrol
- 重构不能破坏现有 15 个通过测试
- 所有文件目标 < 800 行

### Blockers

None

### Todos

- [ ] 确立 static 方法 mock 策略后记录到 PROJECT.md Key Decisions

## Session Continuity

**To resume:** Read ROADMAP.md Phase 1 requirements (TEST-01 through TEST-09), then run `/gsd:plan-phase 1`.

---
*State initialized: 2026-04-08*
