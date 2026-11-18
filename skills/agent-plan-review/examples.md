# Examples

All values are synthetic.

## Command

User: "review the plan for PROJ-123", with the plan pasted or the PR named.

1. Hard gate: plan text, writable `reports/`, code readable (and `gh` if the plan is in a PR).
2. Collect the plan and the goals; load the project's rules; map the affected code.
3. Go through every section of `reference.md`.
4. Write `reports/plan-review-PROJ-123-2026-11-18.md` and summarise in chat.

## Report excerpt

```markdown
# Plan review – PROJ-123

## Short verdict

**Ready with reservations.** The plan covers the goal, but the rollback after PR 2 is not described and the retry limit differs from the issue text.

## Strengths

- The retry state is kept apart from the loan record, which keeps PR 1 small.
- Each PR has its own tests and DoD.

## Errors and gaps

### Blocking

- None.

### Should fix before start

- **Rollback is missing.** PR 2 adds the retry job, but the plan does not say how to switch it off. State the feature flag and its default.

### Minor / clarifications

- The issue says three attempts; the plan says five. Confirm which is intended.
```

## Chat summary

```text
Verdict: ready with reservations. Top findings: (1) no rollback after PR 2, (2) attempts: 3 vs 5, (3) QA does not cover the flag-off case. Report: reports/plan-review-PROJ-123-2026-11-18.md
```
