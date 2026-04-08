# Phase 3: 收尾与达标 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-08
**Phase:** 03-wrap-up
**Areas discussed:** Navigation verification scope, settings_page split strategy, skills_page split strategy, Coverage gap priorities

---

## Navigation verification scope

| Option | Description | Selected |
|--------|-------------|----------|
| Verify + test only | Code is there (onNavigate wired, switch cases handle goto_setup/models/dashboard). Just add widget tests. | |
| Audit indices + test | Check if navigation indices (1, 7, 0) are correct and match actual HomePage page order, then add tests. | ✓ |
| More work needed | I know there's more work needed beyond what the code shows. | |

**User's choice:** Audit indices + test
**Notes:** Navigation appears already implemented. User wants to verify correctness of index mapping before adding tests.

---

## settings_page split strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Split by section | Extract proxy (~224 lines) and integration (~77+ lines) into separate files. | |
| Split dialogs out | Extract all dialogs (update risk, backup confirm) + update banner into separate file. | ✓ |
| Full decomposition | Extract proxy, integration, AND dialogs each into own files. | |

**User's choice:** Split dialogs out
**Notes:** Dialogs alone insufficient (~913 lines after). Follow-up: user chose to also extract proxy section, bringing main to ~689 lines.

### Follow-up: Additional extraction

| Option | Description | Selected |
|--------|-------------|----------|
| Also extract proxy section | Largest remaining chunk (~224 lines). Main drops to ~689 lines. | ✓ |
| Also extract integration section | Smaller (~77+ lines). Main drops to ~836 — borderline. | |
| You decide | Let Claude figure out minimum extraction. | |

---

## skills_page split strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Extract SkillCard + painters | _SkillCard (~260 lines) + _Badge + painters (~85 lines) into skill_card.dart. Main drops to ~558 lines. | ✓ |
| Extract SkillCard only | Only _SkillCard (~260 lines). Main drops to ~643 lines. | |
| You decide | Let Claude decide minimum extraction. | |

**User's choice:** Extract SkillCard + painters (Recommended)
**Notes:** All card-related widgets into one file.

---

## Coverage gap priorities

| Option | Description | Selected |
|--------|-------------|----------|
| Bottom-up: logic layers first | Models + core + data + remaining services + providers. High coverage per effort. | ✓ |
| Balanced across all layers | Proportional testing across all layers. Broader but shallower. | |
| Biggest files first | Focus on files with most lines regardless of layer. | |

**User's choice:** Bottom-up: logic layers first (Recommended)

### Follow-up: Measurement strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Measure after each plan | Run flutter test --coverage after each plan. Adjust if 80% hit early. | ✓ |
| Measure at the end only | Write all tests first, one measurement. | |
| You decide | Let Claude decide when to measure. | |

---

## Claude's Discretion

- Specific test case design and assertion strategies
- Priority ordering within models/core/data layers
- Exact file naming for extracted widgets (suggestions provided in CONTEXT.md)
- Supplemental test selection if coverage falls short

## Deferred Ideas

None — discussion stayed within phase scope
