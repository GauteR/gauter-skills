# Plan template (local, detailed)

Use this structure for:

- The canonical local plan: `reports/plans/<KEY>-<nr>.md`
- The snapshot (first draft): `reports/plans/<KEY>-<nr>-draft.md`

The paste-ready Jira plan is a **separate** file (`<KEY>-<nr>-jira.md`) made from [jira-plan-template.md](jira-plan-template.md). It is not the same content.

Write in the language of the issue; code and paths in English. No nice-to-haves. No automatic implementation.

Rules:

- Start with a **short summary for non-technical readers** (the same message as the paste-ready plan, often with a little more context).
- Reflect the **settled decisions** from the decision map, grilling and teach-back.
- Link to the local decision tickets where it helps (relative paths).
- Small steps; TDD where it fits; PRs ≤ 500 lines (propose a split).
- A machine-readable **Steps / PR plan** (the table below) so that PRs can be turned into subtask descriptions later (step 8 reads **this** file, not `*-jira.md`).
- The stress-test and the plan review run **only** against this local plan.
- Feature flag: ask when the plan adds new functionality.
- Mermaid (dark theme) only when it clarifies flow or dependencies.

```markdown
# Plan – <KEY>-<nr>: <short title>

## Summary

[One short paragraph and/or a short bullet list for non-technical readers: what will be done, why, and what is not included.]

## Goal

[Concrete goal / desired outcome.]

## Decisions

[Settled decisions from the decision map / grilling / teach-back. Optionally: "Decision map skipped: the path was already clear".]

- …

Decision map (local): `reports/plans/<KEY>-<nr>-wayfinder/`

## Scope

**In scope**

- …

**Out of scope**

- …

## Definition of Done

- [ ] …
- [ ] …

## Steps / PR plan (≤ 500 lines)

| PR | Issue | Content |
| ---- | ---- | --------- |
| 1 |  | Short title / scope for PR 1 |
| 2 |  | Short title / scope for PR 2 |

### PR 1 – <title>

- **Steps:** …
- **Files:** …
- **Tests:** …
- **DoD:** …

### PR 2 – <title>

- **Steps:** …
- **Files:** …
- **Tests:** …
- **DoD:** …

## Files

[Main files / folders that are touched.]

## Tests

[The TDD approach; which tests are written or updated.]

## Feature flag

[Environment variable / flag, or "not relevant".]

## Deploy surface

[Apps, configuration, infrastructure: what has to be rolled out.]

## Risks

- …

## QA

[How to verify manually / in a test environment.]

## Dependencies

- …
```

**Alternative PR format** (if the table does not fit): a numbered list, `1. PR1 – title — content`. The table is canonical.
