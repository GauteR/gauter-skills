# Plan review template

Use this structure for:

- Iteration 1: `reports/plan-review-<KEY>-<nr>-YYYY-MM-DD.md`
- Iteration n ≥ 2: `reports/plan-review-<KEY>-<nr>-YYYY-MM-DD-i<n>.md`

The primary plan in `jira-planner` is the detailed local `reports/plans/<KEY>-<nr>.md` (updated between iterations). Do **not** review the paste-ready `*-jira.md`.

Keep the report short and concrete (aim for about one page). Write in the language of the issue; code and paths in English.

Mark the **iteration number** under Short verdict. For `n ≥ 2`: check explicitly that the findings from the previous iteration (blocking / "should fix before start") are closed, or reclassified with a reason.

```markdown
# Plan review – <KEY>-<nr>

## Short verdict

**Iteration n.** **[Ready | Ready with reservations | Not ready for development].** [1–3 sentences: what is needed before start.]

## Sources

- Primary plan: [file]
- Other: issue summary/description; relevant fields; components
- Code verified: [paths]
- Rules: governance / app instructions where relevant
- Previous review (n ≥ 2): [path]

## Strengths

- …

## Errors and gaps

### Blocking

- **[Title].** Problem. Why. What the plan must say or change.

### Should fix before start

- …

### Minor / clarifications

- …

## Goal vs plan

- Does the plan cover the issue's goals?
- Scope creep / missing scope
- Discrepancies between issue description ↔ plan ↔ code

## Structure

- Step order, PR split, feature flag, rollback

## Technical risks

- Security/GDPR, backwards compatibility, correctness, performance, operations, testing, unknowns

## Recommended next steps

- [ ] Update the plan / close blocking and "should fix before start" findings → new plan-review iteration
- [ ] If needed, `grilling` (teach-back / stress-test; plus `domain-modeling` for docs) on open decisions
- [ ] On exit (nothing blocking / should fix): hand over the paste-ready plan
```

## Review principles

- Verify claims against the code; do not trust the plan alone.
- Separate "already implemented" from "to be introduced".
- Feature flag, deploy surface, PRs ≤ 500 lines, out of scope = explicit.
- Only findings with high confidence; actionable next steps.
- In `jira-planner`: exit when Blocking and "Should fix before start" are empty. Minor / clarifications alone do not stop the loop.
