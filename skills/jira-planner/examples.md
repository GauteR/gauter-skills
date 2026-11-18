# Examples

All values are synthetic.

## Command

User: `jira-planner PROJ-123`, followed by the pasted summary and description.

1. Hard gate: key, issue text, writable `reports/`, code readable.
2. Decision map (or a documented skip), then teach-back; the user confirms.
3. Draft → `reports/plans/PROJ-123.md` (+ `PROJ-123-draft.md`).
4. Stress-test the draft; update the plan.
5. Plan review → fix, repeated until nothing is blocking or "should fix before start".
6. Paste-ready plan → `reports/plans/PROJ-123-jira.md`.
7. Show the path and say that the user pastes it into the Plan field. Stop.

## Paste-ready plan (step 6)

```markdown
## Summary

Failed loan renewals are retried automatically, so patrons no longer have to renew again by hand. Notifying the patron after the last failure is not included.

## Goal

A renewal that fails with a temporary error is retried up to three times with increasing delay, and each attempt is recorded.

## Decisions

- Retry state is stored in a separate table, not on the loan.
- Backoff doubles from 30 seconds.
- The feature is behind a feature flag and off by default.

## Definition of Done

- [ ] Temporary errors are retried; permanent errors are not
- [ ] Every attempt is recorded
- [ ] The feature flag is documented and off by default
```

## Review verdict (step 5)

```markdown
## Short verdict

**Iteration 2.** **Ready with reservations.** Both blocking findings from iteration 1 are closed. One minor clarification remains about the flag's default in staging.
```

## Subtask description (step 8, on request only)

```markdown
## PR 2 – Retry job with backoff

**Parent:** PROJ-123
**App:** renewal-service

### Goal

Failed renewals are picked up by a job and retried up to three times, with the delay doubling from 30 seconds.

### Steps

1. Write a failing test for a temporary error on the first attempt.
2. Add the job and the backoff calculation until the test passes.
3. Add a test that a permanent error is not retried.

### Files

- `src/jobs/renewal-retry.ts`
- `src/jobs/renewal-retry.test.ts`

### Tests

- Temporary error → retried with 30 s, 60 s, 120 s
- Permanent error → not retried
- Flag off → job does nothing

### DoD

- [ ] Tests above pass
- [ ] Flag documented in the README
```
